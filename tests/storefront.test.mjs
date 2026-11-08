import { test } from 'node:test'; import assert from 'node:assert/strict';
import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path'; import { execFileSync } from 'node:child_process';
import { build } from '../scripts/build.mjs'; import { validate } from '../src/lib.mjs';

const EX = ['hardware-supplier', 'general-retail', 'service-provider'];
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'pbds-'));
const rd = (d, f) => fs.readFileSync(path.join(d, f), 'utf8');
const cfg = (e) => JSON.parse(rd(`examples/${e}`, 'business.json'));
const cat = (e) => JSON.parse(rd(`examples/${e}`, 'catalogue.json'));
const out = Object.fromEntries(EX.map((e) => [e, path.join(tmp, e)]));
for (const e of EX) build(`examples/${e}`, out[e]);

test('1. all three example businesses build', () => { for (const e of EX) { assert.ok(fs.existsSync(path.join(out[e], 'index.html'))); assert.ok(fs.existsSync(path.join(out[e], 'search.html'))); } });

test('4. each build shows its own name, colour, content, and none of the others', () => {
  for (const e of EX) {
    const html = rd(out[e], 'index.html'), b = cfg(e);
    assert.ok(html.includes(b.name.replace('&', '&amp;'))); assert.ok(html.includes(b.brand.primary));
    assert.ok(fs.existsSync(path.join(out[e], 'assets/logo-fallback.svg')));
    for (const o of EX.filter((x) => x !== e)) { assert.ok(!html.includes(cfg(o).name.replace('&', '&amp;'))); assert.ok(!html.includes(cfg(o).brand.primary)); }
  }
});

test('5. changing one configuration does not change another', () => {
  const src = path.join(tmp, 'mod'); fs.cpSync('examples/hardware-supplier', src, { recursive: true });
  const b = JSON.parse(rd(src, 'business.json')); b.name = 'Changed Name'; fs.writeFileSync(path.join(src, 'business.json'), JSON.stringify(b));
  build(src, path.join(tmp, 'mod-out'));
  assert.ok(rd(path.join(tmp, 'mod-out'), 'index.html').includes('Changed Name'));
  assert.equal(rd(out['general-retail'], 'index.html'), (build('examples/general-retail', path.join(tmp, 'g2')), rd(path.join(tmp, 'g2'), 'index.html')));
});

test('6/7. listing pages exist with contact + share + enquiry links', () => {
  for (const e of EX) for (const l of cat(e).listings) {
    const html = rd(out[e], `p/${l.listingId}.html`); assert.ok(html.includes(l.name.replace('&', '&amp;'))); assert.ok(html.includes('id="share"'));
    const b = cfg(e); if (b.phone) assert.ok(html.includes(`href="tel:${b.phone}"`));
    if (b.whatsapp) assert.ok(html.includes(`https://wa.me/${b.whatsapp.replace('+', '')}?text=`));
  }
  assert.ok(!rd(out['service-provider'], 'p/sv-solar.html').includes('wa.me/')); // no whatsapp configured => no link
  for (const e of EX) { assert.ok(!fs.existsSync(path.join(out[e], 'promo.html'))); assert.ok(!rd(out[e], 'index.html').includes('Promotions')); }
});

test('8. no example business content hardcoded in shared source', () => {
  const shared = ['src/lib.mjs', 'src/render.mjs', 'src/styles.css', 'scripts/build.mjs'].map((f) => rd('.', f)).join('\n');
  for (const e of EX) { const b = cfg(e); for (const s of [b.name, b.businessId, b.phone, b.email].filter(Boolean)) assert.ok(!shared.includes(s), `found ${s}`); for (const l of cat(e).listings) assert.ok(!shared.includes(l.listingId)); }
});

test('9. IDs are stable across rebuilds and export', () => {
  for (const e of EX) {
    build(`examples/${e}`, path.join(tmp, e + '-2'));
    const a = JSON.parse(rd(out[e], 'export/business-export.json')), b = JSON.parse(rd(path.join(tmp, e + '-2'), 'export/business-export.json'));
    assert.equal(a.business.businessId, cfg(e).businessId); assert.deepEqual(a.catalogue.listings.map((l) => l.listingId), cat(e).listings.map((l) => l.listingId)); assert.deepEqual(a, b);
  }
});

test('10. export -> import round trip preserves data and IDs', () => {
  const t = path.join(tmp, 'imp');
  execFileSync('node', ['scripts/import.mjs', path.join(out['general-retail'], 'export/business-export.json'), t]);
  assert.deepEqual(JSON.parse(rd(t, 'business.json')), cfg('general-retail')); assert.deepEqual(JSON.parse(rd(t, 'catalogue.json')), cat('general-retail'));
});

test('security: HTML is escaped, bad URLs/colours/IDs rejected, path traversal ignored', () => {
  const src = path.join(tmp, 'evil'); fs.cpSync('examples/general-retail', src, { recursive: true });
  const b = cfg('general-retail'); b.name = '<script>alert(1)</script>'; b.logo = '../../../etc/passwd';
  const c = cat('general-retail'); c.listings[0].description = '"><img src=x onerror=alert(1)>';
  fs.writeFileSync(path.join(src, 'business.json'), JSON.stringify(b)); fs.writeFileSync(path.join(src, 'catalogue.json'), JSON.stringify(c));
  assert.throws(() => build(src, path.join(tmp, 'evil-out')), /business\.json › logo/);
  b.logo = 'logo.png'; fs.writeFileSync(path.join(src, 'business.json'), JSON.stringify(b));
  const r = build(src, path.join(tmp, 'evil-out')); assert.ok(r.warnings.some((w) => w.includes('logo.png')));
  const html = rd(path.join(tmp, 'evil-out'), 'index.html') + rd(path.join(tmp, 'evil-out'), `p/${c.listings[0].listingId}.html`);
  assert.ok(!html.includes('<script>alert(1)')); assert.ok(!html.includes('<img src=x')); assert.ok(!fs.existsSync(path.join(tmp, 'evil-out/assets/logo.png'))); assert.ok(html.includes('assets/logo-fallback.svg'));
  const bad = { ...cfg('general-retail'), brand: { primary: 'red' }, social: { x: 'javascript:alert(1)' }, businessId: 'Bad ID' };
  const errs = validate(bad, cat('general-retail')); assert.ok(errs.length >= 3);
});

test('defaults: minimal config (no optional fields) builds', () => {
  const src = path.join(tmp, 'min'); fs.mkdirSync(src);
  fs.writeFileSync(path.join(src, 'business.json'), JSON.stringify({ businessId: 'min-biz', name: 'Min', type: 'other' }));
  fs.writeFileSync(path.join(src, 'catalogue.json'), JSON.stringify({ listings: [{ listingId: 'min-1', name: 'Thing', kind: 'product' }] }));
  build(src, path.join(tmp, 'min-out')); assert.ok(rd(path.join(tmp, 'min-out'), 'index.html').includes('Min'));
  assert.ok(rd(path.join(tmp, 'min-out'), 'p/min-1.html').includes('Ask for price'));
});

test('no secrets/env files or forbidden folders in project', () => {
  for (const f of fs.readdirSync('.')) assert.ok(!/^\.env(\..*)?$/.test(f) || f === '.env.example');
  assert.ok(!fs.existsSync('node_modules'));
});

const ok = () => [cfg('general-retail'), cat('general-retail')];
const errsFor = (mutB = () => {}, mutC = () => {}) => { const [b, c] = ok(); mutB(b); mutC(c); return validate(b, c); };

test('validation: messages name the file and field', () => {
  const has = (errs, s) => assert.ok(errs.some((e) => e.includes(s)), `${s} not in ${JSON.stringify(errs)}`);
  has(errsFor((b) => delete b.businessId), 'business.json › businessId: is required');
  has(errsFor((b) => { b.businessId = 'Bad ID!'; }), 'business.json › businessId');
  has(errsFor((b) => delete b.name), 'business.json › name: is required');
  has(errsFor((b) => { b.type = 'bakery'; }), 'business.json › type: "bakery" is not supported');
  has(errsFor((b) => { b.brand = { primary: 'red' }; }), 'business.json › brand.primary');
  has(errsFor((b) => { b.brand = { primary: '#ffff00' }; }), 'too light');
  has(errsFor((b) => { b.brand = { accent: '#000000' }; }), 'too dark');
  has(errsFor((b) => { b.phone = 'call me'; }), 'business.json › phone');
  has(errsFor((b) => { b.whatsapp = '+675abc12345'; }), 'business.json › whatsapp');
  has(errsFor((b) => { b.email = 'not-an-email'; }), 'business.json › email');
  has(errsFor((b) => { b.name = 'x'.repeat(81); }), 'name: too long');
  has(errsFor((b) => { b.demo = 'yes'; }), 'business.json › demo');
  has(errsFor((b) => { b.currency = { decimals: 9 }; }), 'currency.decimals');
  has(errsFor((b) => { b.social = { Facebook: 'ftp://x' }; }), 'social.Facebook');
  for (const bad of ['../x.png', '/etc/x.png', 'http://x/y.png', 'C:\\x.png', 'a\\b.png', 'file.exe', 'data:image/png;base64,xx']) has(errsFor((b) => { b.logo = bad; }), 'business.json › logo');
  has(errsFor((b) => { b.coverImage = '../c.jpg'; }), 'coverImage');
  has(errsFor(() => {}, (c) => { c.listings[1].listingId = c.listings[0].listingId; }), 'duplicate listingId');
  has(errsFor(() => {}, (c) => delete c.listings[0].listingId), 'listings[0].listingId: is required');
  has(errsFor(() => {}, (c) => delete c.listings[0].name), 'name: is required');
  has(errsFor(() => {}, (c) => { c.listings[0].price = -5; }), 'price');
  has(errsFor(() => {}, (c) => { c.listings[0].price = '12'; }), 'price');
  has(errsFor(() => {}, (c) => { c.listings[0].price = NaN; }), 'price');
  has(errsFor(() => {}, (c) => { c.listings[0].kind = 'thing'; }), 'kind');
  has(errsFor(() => {}, (c) => { c.listings[0].categoryId = 'nope'; }), 'categoryId');
  has(errsFor(() => {}, (c) => { c.listings[0].description = 5; }), 'description: must be text');
  has(errsFor(() => {}, (c) => { c.listings[0].image = '../../x.png'; }), '.image');
  has(errsFor(() => {}, (c) => { c.categories.push(c.categories[0]); }), 'duplicate category');
  assert.deepEqual(errsFor(), []);
  assert.throws(() => build(path.join(tmp, 'doesnotexist'), path.join(tmp, 'x')));
});

test('demo data: examples and starter are marked, banner + noindex + sample labels; placeholders rejected for real businesses', () => {
  for (const e of EX) {
    const html = rd(out[e], 'index.html'), search = rd(out[e], 'search.html'), lp = rd(out[e], `p/${cat(e).listings[0].listingId}.html`);
    assert.equal(cfg(e).demo, true);
    for (const h of [html, search, lp]) { assert.ok(h.includes('DEMONSTRATION DATA')); assert.ok(h.includes('noindex')); assert.ok(h.includes('<title>[DEMO]')); }
    assert.ok(html.includes('Sample: '));
    assert.match(cfg(e).phone || '+67500000000', /^\+6750{5}/);
  }
  const starter = path.join(tmp, 'starter-out'); const r = build('business', starter);
  assert.ok(r.warnings.some((w) => w.includes('DEMONSTRATION DATA'))); assert.ok(rd(starter, 'index.html').includes('DEMONSTRATION DATA'));
  const errs = errsFor((b) => { b.demo = false; b.name = 'Your Business Name (replace)'; b.phone = '+67500000001'; b.email = 'a@example.com'; });
  assert.ok(errs.filter((e) => e.includes('placeholder')).length >= 3, JSON.stringify(errs));
  const [b, c] = ok(); b.demo = false; b.phone = '+67571234567'; b.whatsapp = b.phone; b.email = 'owner@realshop.pg';
  b.name = 'Real Shop'; b.description = 'We sell goods.'; b.social = {}; c.listings.forEach((l) => { l.name = 'Item ' + l.listingId; l.description = 'Fine.'; });
  const rs = path.join(tmp, 'real'); fs.mkdirSync(rs); fs.writeFileSync(path.join(rs, 'business.json'), JSON.stringify(b)); fs.writeFileSync(path.join(rs, 'catalogue.json'), JSON.stringify(c));
  build(rs, path.join(tmp, 'real-out')); const h = rd(path.join(tmp, 'real-out'), 'index.html');
  assert.ok(!h.includes('DEMONSTRATION') && !h.includes('noindex') && !h.includes('Sample:'));
});

test('export: whitelist only (no private/extra fields), has schemaVersion; import rejects malformed or incompatible data', () => {
  const src = path.join(tmp, 'priv'); fs.cpSync('examples/general-retail', src, { recursive: true });
  const b = cfg('general-retail'); b.ownerHomeAddress = 'SECRET'; b.apiKey = 'sk-123'; const c = cat('general-retail'); c.listings[0].costPrice = 3; c.listings[0].supplierNote = 'SECRET';
  fs.writeFileSync(path.join(src, 'business.json'), JSON.stringify(b)); fs.writeFileSync(path.join(src, 'catalogue.json'), JSON.stringify(c));
  build(src, path.join(tmp, 'priv-out')); const raw = rd(path.join(tmp, 'priv-out'), 'export/business-export.json');
  assert.ok(!raw.includes('SECRET') && !raw.includes('sk-123') && !raw.includes('costPrice')); assert.equal(JSON.parse(raw).schemaVersion, '1.0');
  const imp = (obj, target = path.join(tmp, 'imp-' + Math.random()), ...extra) => { const f = path.join(tmp, 'in-' + Math.random() + '.json'); fs.writeFileSync(f, typeof obj === 'string' ? obj : JSON.stringify(obj)); try { execFileSync('node', ['scripts/import.mjs', f, target, ...extra], { stdio: 'pipe' }); return { ok: true, target }; } catch (e) { return { ok: false, msg: String(e.stderr) }; } };
  const good = JSON.parse(rd(out['general-retail'], 'export/business-export.json'));
  assert.ok(imp(good).ok);
  assert.ok(/schemaVersion/.test(imp({ ...good, schemaVersion: '2.0' }).msg)); assert.ok(/schemaVersion/.test(imp({ business: good.business, catalogue: good.catalogue }).msg));
  assert.ok(/Cannot read|JSON/.test(imp('{not json').msg)); assert.ok(/top level/.test(imp('[1,2]').msg));
  assert.ok(/Invalid export/.test(imp({ ...good, business: { ...good.business, businessId: 'BAD ID' } }).msg));
  assert.ok(/Invalid export/.test(imp({ ...good, catalogue: { listings: 'x' } }).msg));
  const t = path.join(tmp, 'imp-guard'); assert.ok(imp(good, t).ok);
  const other = JSON.parse(JSON.stringify(good)); other.business.businessId = 'someone-else';
  assert.ok(/Refusing to overwrite/.test(imp(other, t).msg)); assert.ok(imp(other, t, '--force').ok);
});

test('image handling: real images are used, missing files fall back with a warning, listing pages keep working', () => {
  const src = path.join(tmp, 'imgs'); fs.cpSync('examples/general-retail', src, { recursive: true });
  const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==', 'base64');
  fs.writeFileSync(path.join(src, 'logo.png'), png); fs.writeFileSync(path.join(src, 'cover.png'), png); fs.writeFileSync(path.join(src, 'rice.png'), png);
  const b = cfg('general-retail'); b.logo = 'logo.png'; b.coverImage = 'cover.png'; const c = cat('general-retail'); c.listings[0].image = 'rice.png'; c.listings[1].image = 'missing.jpg';
  fs.writeFileSync(path.join(src, 'business.json'), JSON.stringify(b)); fs.writeFileSync(path.join(src, 'catalogue.json'), JSON.stringify(c));
  const o = path.join(tmp, 'imgs-out'); const r = build(src, o);
  assert.ok(fs.existsSync(path.join(o, 'assets/logo.png')) && fs.existsSync(path.join(o, 'assets/cover.png')) && fs.existsSync(path.join(o, `assets/img/${c.listings[0].listingId}.png`)));
  assert.ok(r.warnings.some((w) => w.includes('missing.jpg')));
  const home = rd(o, 'index.html'); assert.ok(home.includes('assets/cover.png')); assert.ok(home.includes(`assets/img/${c.listings[1].listingId}-placeholder.svg`));
  assert.ok(home.includes('data-fallback='));
});

test('empty catalogue and minimal config do not break the storefront', () => {
  const src = path.join(tmp, 'empty'); fs.mkdirSync(src);
  fs.writeFileSync(path.join(src, 'business.json'), JSON.stringify({ businessId: 'empty-shop', name: 'Empty Shop', type: 'other' })); fs.writeFileSync(path.join(src, 'catalogue.json'), JSON.stringify({ listings: [] }));
  const o = path.join(tmp, 'empty-out'); build(src, o); assert.ok(rd(o, 'index.html').includes('No products or services')); assert.ok(!fs.existsSync(path.join(o, 'promo.html')));
});

test('accessibility (static): landmarks, headings, labels, alt text, link names on every generated page', () => {
  for (const e of EX) {
    const files = ['index.html', 'search.html', ...cat(e).listings.map((l) => `p/${l.listingId}.html`)];
    for (const f of files) {
      const h = rd(out[e], f);
      assert.ok(h.includes('<html lang="en">') && h.includes('<main id="main"') && h.includes('class="skip"') && h.includes('<nav aria-label="Main">'), f);
      assert.equal((h.match(/<h1[ >]/g) || []).length, 1, `${f} h1 count`);
      assert.ok(!/<h3/.test(h) || /<h2/.test(h), `${f} heading levels`);
      for (const img of h.match(/<img [^>]*>/g) || []) assert.ok(/ alt="/.test(img), `${f} img without alt`);
      assert.ok(!/<a [^>]*>\s*<\/a>/.test(h), `${f} empty link`);
      if (f === 'index.html') { assert.ok(h.includes('<label class="sr" for="q">')); assert.ok(h.includes('aria-pressed')); }
    }
  }
  const css = rd('src', 'styles.css'); assert.ok(css.includes(':focus-visible')); assert.ok(css.includes('min-height:44px'));
});

test('public storefront: no Promotions page; search suggestions and full results are generated', () => {
  for (const e of EX) {
    const home = rd(out[e], 'index.html');
    const results = rd(out[e], 'search.html');
    assert.ok(!fs.existsSync(path.join(out[e], 'promo.html')));
    assert.ok(!home.includes('>Promotions<'));
    assert.ok(home.includes('id="suggestions"'));
    assert.ok(home.includes('View all results'));
    assert.ok(home.includes('assets/logo-fallback.svg'));
    assert.ok(results.includes('id="results-q"'));
    assert.ok(results.includes('id="results-cat"'));
    assert.ok(results.includes('id="results-sort"'));
    assert.ok(results.includes('id="clear-results"'));
    assert.ok(home.includes('Category: '));
    assert.ok(results.includes('Most relevant'));
    assert.ok(results.includes('Price: low to high'));
    assert.ok(results.includes('No matching products or services'));
    assert.ok(results.includes(cfg(e).name));
  }
});
