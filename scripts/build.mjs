import fs from 'node:fs'; import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { validate, withDefaults, toExport } from '../src/lib.mjs';
import { renderHome, renderSearchResults, renderListing, logoSvg, placeholderSvg } from '../src/render.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const readJson = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const IMG = { '.png': 1, '.jpg': 1, '.jpeg': 1, '.webp': 1, '.svg': 1 };

export function build(srcDir, outDir, { validateOnly = false } = {}) {
  srcDir = path.resolve(srcDir);
  const business = readJson(path.join(srcDir, 'business.json'));
  const catalogue = readJson(path.join(srcDir, 'catalogue.json'));
  const errors = validate(business, catalogue);
  if (errors.length) throw new Error('Invalid configuration:\n - ' + errors.join('\n - '));
  if (validateOnly) return { business, catalogue, warnings: [] };
  const warnings = [];
  if (business.demo === true) warnings.push('business.json › demo: this build contains DEMONSTRATION DATA (banner, noindex and "Sample" labels are added). Replace it before onboarding a real business.');
  const b = withDefaults(business);
  const out = path.resolve(outDir);
  fs.rmSync(out, { recursive: true, force: true });
  for (const d of ['assets/img', 'p', 'export', 'admin', 'platform-admin']) fs.mkdirSync(path.join(out, d), { recursive: true });
  fs.copyFileSync(path.join(root, 'src/styles.css'), path.join(out, 'assets/styles.css'));
  // Separate private routes; authorization is enforced by Supabase Auth and database RPCs.
  fs.cpSync(path.join(root, 'admin'), path.join(out, 'admin'), { recursive: true });
  fs.cpSync(path.join(root, 'platform-admin'), path.join(out, 'platform-admin'), { recursive: true });
  // Only files inside the business folder can be referenced (paths are also validated in src/lib.mjs).
  // Returns the output file name (relative to the site root) or null; a missing file produces a warning and a generated fallback.
  const copyAsset = (rel, destBase, label) => {
    if (!rel) return null;
    const abs = path.resolve(srcDir, rel);
    if (!abs.startsWith(srcDir + path.sep) || !IMG[path.extname(abs).toLowerCase()]) throw new Error(`Invalid configuration:\n - ${label}: "${rel}" is outside the business folder or not an image`);
    if (!fs.existsSync(abs) || !fs.statSync(abs).isFile()) { warnings.push(`${label}: file "${rel}" was not found; a generated placeholder is used instead`); return null; }
    const ext = path.extname(abs).slice(1).toLowerCase(); fs.copyFileSync(abs, `${destBase}.${ext}`); return `${destBase.slice(out.length + 1)}.${ext}`;
  };
  fs.writeFileSync(path.join(out, 'assets/logo-fallback.svg'), logoSvg(b));
  b.logoFile = copyAsset(b.logo, path.join(out, 'assets/logo'), 'business.json › logo') || 'assets/logo-fallback.svg';
  b.coverFile = copyAsset(b.coverImage, path.join(out, 'assets/cover'), 'business.json › coverImage');
  const c = { ...catalogue, listings: catalogue.listings.map((l) => ({ ...l })) };
  c.listings.forEach((l, i) => {
    fs.writeFileSync(path.join(out, 'assets/img', `${l.listingId}-placeholder.svg`), placeholderSvg(b, l));
    l.imageFile = copyAsset(l.image, path.join(out, 'assets/img', l.listingId), `catalogue.json › listings[${i}] (${l.listingId}).image`) || `assets/img/${l.listingId}-placeholder.svg`;
  });
  fs.writeFileSync(path.join(out, 'index.html'), renderHome(b, c));
  fs.writeFileSync(path.join(out, 'search.html'), renderSearchResults(b, c));
  for (const l of c.listings) fs.writeFileSync(path.join(out, 'p', `${l.listingId}.html`), renderListing(b, c, l));
  fs.writeFileSync(path.join(out, 'export/business-export.json'), JSON.stringify(toExport(business, catalogue), null, 2));
  return { out, listings: c.listings.length, warnings };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [src = 'business', dest = 'dist', flag] = process.argv.slice(2);
  try {
    const r = build(src, dest, { validateOnly: flag === '--validate-only' });
    console.log(flag === '--validate-only' ? `OK: ${src} is valid` : `Built ${r.listings} listings from ${src} -> ${dest}`);
    for (const w of r.warnings) console.warn(`WARNING ${w}`);
  } catch (e) { console.error(e.message); process.exit(1); }
}
