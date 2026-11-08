"""Real-browser QA (headless Chromium via Playwright for Python). Optional: not part of `npm test`.
Setup:  pip install playwright && playwright install chromium ; (optional) npm i axe-core and set AXE_PATH=.../axe.min.js
Run:    python3 tests/browser/browser-qa.py          (from the project root)
Checks the 3 demo businesses plus a broken-image variant at 4 viewport sizes."""
import os, sys, json, shutil, subprocess, tempfile, threading, functools, http.server
from playwright.sync_api import sync_playwright

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
AXE = os.environ.get('AXE_PATH'); SHOTS = os.environ.get('SHOTS_DIR')
EX = ['hardware-supplier', 'general-retail', 'service-provider']
VIEWPORTS = [(320, 640), (375, 667), (768, 1024), (1280, 800)]
tmp = tempfile.mkdtemp(); site = os.path.join(tmp, 'site'); os.makedirs(site)
def build(src, name):
    subprocess.run(['node', 'scripts/build.mjs', src, os.path.join(site, name)], cwd=ROOT, check=True, capture_output=True)
for e in EX: build(f'examples/{e}', e)
v = os.path.join(tmp, 'broken'); shutil.copytree(os.path.join(ROOT, 'examples/general-retail'), v)
open(os.path.join(v, 'corrupt.png'), 'wb').write(b'not really a png')
b = json.load(open(os.path.join(v, 'business.json'))); b['logo'] = 'corrupt.png'; b['coverImage'] = 'corrupt.png'; b['name'] = 'Demo Extraordinarily-Long-Unbroken-Business-Name-Tester'
c = json.load(open(os.path.join(v, 'catalogue.json'))); c['listings'][0]['image'] = 'corrupt.png'; c['listings'][1]['image'] = 'missing.jpg'; c['listings'][2]['name'] = 'Demo ' + 'Supercalifragilisticexpialidocious' * 2
json.dump(b, open(os.path.join(v, 'business.json'), 'w')); json.dump(c, open(os.path.join(v, 'catalogue.json'), 'w')); build(v, 'broken-images')
SITES = EX + ['broken-images']

class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a, **k): pass
handler = functools.partial(Quiet, directory=site)
srv = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler); threading.Thread(target=srv.serve_forever, daemon=True).start()
BASE = f'http://127.0.0.1:{srv.server_address[1]}'
results = []; axe_rows = []
def rec(site_, vp, page_, check, ok, detail=''):
    results.append(dict(site=site_, viewport=f'{vp[0]}x{vp[1]}', page=page_, check=check, ok=bool(ok), detail=detail))

def common_checks(pg, s, vp, name):
    pg.evaluate("document.querySelectorAll('img').forEach(i=>i.loading='eager')"); pg.wait_for_load_state('networkidle'); pg.wait_for_timeout(300)
    rec(s, vp, name, 'no horizontal overflow', pg.evaluate("document.documentElement.scrollWidth<=window.innerWidth"), pg.evaluate("document.documentElement.scrollWidth+' vs '+window.innerWidth"))
    bad = pg.evaluate("[...document.images].filter(i=>!(i.complete&&i.naturalWidth>0)).map(i=>i.getAttribute('src'))")
    rec(s, vp, name, 'all images loaded (fallbacks applied)', not bad, str(bad))
    small = pg.evaluate("""[...document.querySelectorAll('.btn,.chip,nav a,input[type=search],.brand')].filter(e=>e.offsetParent!==null).map(e=>{const r=e.getBoundingClientRect();return[e.textContent.trim().slice(0,20)||e.className,Math.round(r.width),Math.round(r.height)]}).filter(x=>x[1]<44||x[2]<44)""")
    rec(s, vp, name, 'tap targets >= 44px', not small, str(small))
    fs = pg.evaluate("Math.min(...[...document.querySelectorAll('main p,main h1,main h2,main h3,main a,main button,footer,footer a,nav a')].filter(e=>e.offsetParent!==null&&e.textContent.trim()).map(e=>parseFloat(getComputedStyle(e).fontSize)))")
    rec(s, vp, name, 'text >= 13px (body 16px)', fs >= 13 and pg.evaluate("parseFloat(getComputedStyle(document.body).fontSize)") == 16, f'min {fs}px')
    rec(s, vp, name, 'nav links stay on one line (no word breaking)', pg.evaluate("[...document.querySelectorAll('nav a')].every(a=>a.getBoundingClientRect().height<=48)"))
    rec(s, vp, name, 'footer + contact links present', pg.evaluate("!!document.querySelector('footer a[href^=tel],footer a[href^=mailto],footer a[href*=\"wa.me\"]')"))
    if AXE:
        pg.add_script_tag(path=AXE); r = pg.evaluate("axe.run().then(r=>r.violations.map(v=>({id:v.id,impact:v.impact,n:v.nodes.length})))")
        rec(s, vp, name, 'axe-core: no violations', not r, str(r))
        for x in r: axe_rows.append((s, f'{vp[0]}', name, x['id'], x['impact'], x['n']))

with sync_playwright() as p:
    br = p.chromium.launch()
    for s in SITES:
        cat = json.load(open(os.path.join(site, s, 'export/business-export.json')))['catalogue']; first = cat['listings'][0]
        for vp in VIEWPORTS:
            ctx = br.new_context(viewport=dict(width=vp[0], height=vp[1]), device_scale_factor=1, has_touch=vp[0] < 700); pg = ctx.new_page(); errs = []
            pg.on('pageerror', lambda e: errs.append(str(e)))
            pg.goto(f'{BASE}/{s}/index.html'); common_checks(pg, s, vp, 'home')
            rec(s, vp, 'home', 'no JavaScript errors', not errs, str(errs))
            if SHOTS: os.makedirs(SHOTS, exist_ok=True); pg.screenshot(path=os.path.join(SHOTS, f'{s}-{vp[0]}.png'), full_page=True)
            ratios = pg.evaluate("[...document.querySelectorAll('.card img')].filter(i=>i.offsetParent!==null).map(i=>{const r=i.getBoundingClientRect();return r.width/r.height})")
            rec(s, vp, 'home', 'card images keep 4:3 proportion', ratios and all(abs(x - 4 / 3) < 0.03 for x in ratios), str([round(x, 2) for x in ratios[:3]]))
            cols = pg.evaluate("new Set([...document.querySelectorAll('.card')].map(c=>Math.round(c.getBoundingClientRect().left))).size")
            rec(s, vp, 'home', 'card grid columns (2 mobile, 3 desktop)', cols == (3 if vp[0] >= 700 else 2), f'{cols} columns')
            n_all = pg.locator('.card:visible').count()
            pg.fill('#q', 'zzzzqq'); rec(s, vp, 'home', 'search: no match shows message', pg.locator('.card:visible').count() == 0 and 'Nothing matches' in pg.inner_text('#status'))
            word = first['name'].split()[1] if len(first['name'].split()) > 1 else first['name']
            pg.fill('#q', word); n = pg.locator('.card:visible').count(); rec(s, vp, 'home', 'search: matching term filters list', 1 <= n <= n_all, f'{n}/{n_all} for "{word}"')
            pg.fill('#q', ''); chips = pg.locator('.chip'); chips.nth(1).click()
            cat_id = chips.nth(1).get_attribute('data-cat'); vis = pg.evaluate("[...document.querySelectorAll('.card')].filter(c=>c.offsetParent!==null).map(c=>c.dataset.cat)")
            rec(s, vp, 'home', 'category filter works + aria-pressed', vis and all(x == cat_id for x in vis) and chips.nth(1).get_attribute('aria-pressed') == 'true' and chips.nth(0).get_attribute('aria-pressed') == 'false', f'{len(vis)} shown')
            chips.nth(0).click(); rec(s, vp, 'home', 'category "All" restores list', pg.locator('.card:visible').count() == n_all)
            pg.reload(); pg.keyboard.press('Tab'); sk = pg.evaluate("(()=>{const e=document.activeElement;const r=e.getBoundingClientRect();return[e.className,r.top>=0&&r.height>0]})()")
            rec(s, vp, 'home', 'first Tab reaches visible skip link', sk[0] == 'skip' and sk[1], str(sk))
            seen = 0; noring = []
            for _ in range(40):
                pg.keyboard.press('Tab'); info = pg.evaluate("(()=>{const e=document.activeElement;if(!e||e===document.body)return null;const c=getComputedStyle(e);return[e.tagName+'.'+e.className,c.outlineStyle!=='none'&&parseFloat(c.outlineWidth)>=2]})()")
                if info: seen += 1; (not info[1]) and noring.append(info[0])
            rec(s, vp, 'home', 'keyboard: every focusable element shows a focus ring', seen > 5 and not noring, f'{seen} stops; missing: {noring[:3]}')
            pg.goto(f'{BASE}/{s}/index.html'); pg.locator('.chip').nth(1).focus(); pg.keyboard.press('Enter')
            rec(s, vp, 'home', 'keyboard: Enter activates category chip', pg.locator('.chip').nth(1).get_attribute('aria-pressed') == 'true')
            pg.goto(f'{BASE}/{s}/index.html'); pg.locator('nav a', has_text='Promotions').click(); pg.wait_for_load_state()
            rec(s, vp, 'home', 'nav: Promotions link works', pg.url.endswith('promo.html')); common_checks(pg, s, vp, 'promo')
            pg.goto(f'{BASE}/{s}/index.html'); pg.locator('nav a', has_text='Contact').click(); pg.wait_for_timeout(400)
            rec(s, vp, 'home', 'nav: Contact link scrolls to footer', pg.evaluate("document.querySelector('footer').getBoundingClientRect().top<window.innerHeight"))
            pg.goto(f'{BASE}/{s}/index.html'); pg.locator('.card').first.click(); pg.wait_for_load_state(); common_checks(pg, s, vp, 'listing')
            dr = pg.evaluate("(()=>{const r=document.querySelector('.detail img').getBoundingClientRect();return r.width/r.height})()")
            rec(s, vp, 'listing', 'detail image keeps 4:3 proportion', abs(dr - 4 / 3) < 0.03, f'{dr:.2f}')
            rec(s, vp, 'listing', 'listing page has share button + back link', pg.locator('#share').count() == 1 and pg.locator('text=Back to catalogue').count() == 1)
            if SHOTS and vp[0] in (375, 1280): pg.screenshot(path=os.path.join(SHOTS, f'{s}-{vp[0]}-listing.png'), full_page=True)
            ctx.close()
    br.close()
fails = [r for r in results if not r['ok']]
json.dump(dict(total=len(results), failed=len(fails), results=results), open(os.path.join(tmp, 'results.json'), 'w'), indent=1)
print(f'checks: {len(results)}  passed: {len(results)-len(fails)}  failed: {len(fails)}  axe: {"on" if AXE else "off"}')
for f in fails: print('FAIL', f['site'], f['viewport'], f['page'], f['check'], f['detail'])
print('axe rows:', sorted(set(axe_rows))[:20])
print('results file:', os.path.join(tmp, 'results.json'))
sys.exit(1 if fails else 0)
