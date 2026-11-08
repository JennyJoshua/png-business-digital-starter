// Usage: node scripts/import.mjs <export.json> <target-folder> [--force]
// Splits a portable export into business.json + catalogue.json. IDs are never rewritten.
import fs from 'node:fs'; import path from 'node:path';
import { validate, SCHEMA_VERSION, pickBusiness, pickCatalogue } from '../src/lib.mjs';
const fail = (m) => { console.error(m); process.exit(1); };
const [file, target, flag] = process.argv.slice(2);
if (!file || !target) fail('Usage: node scripts/import.mjs <export.json> <target-folder> [--force]');
let data;
try { data = JSON.parse(fs.readFileSync(file, 'utf8')); } catch (e) { fail(`Cannot read ${file} as JSON: ${e.message}`); }
if (!data || typeof data !== 'object' || Array.isArray(data)) fail('Invalid export: top level must be an object');
if (String(data.schemaVersion).split('.')[0] !== SCHEMA_VERSION.split('.')[0]) fail(`Unsupported or missing schemaVersion "${data.schemaVersion}" (this template reads ${SCHEMA_VERSION.split('.')[0]}.x)`);
const errs = validate(data.business, data.catalogue);
if (errs.length) fail('Invalid export:\n - ' + errs.join('\n - '));
const bFile = path.join(target, 'business.json');
if (fs.existsSync(bFile) && flag !== '--force') {
  let cur = null; try { cur = JSON.parse(fs.readFileSync(bFile, 'utf8')).businessId; } catch { /* unreadable: treat as different */ }
  if (cur !== data.business.businessId) fail(`Refusing to overwrite: ${target} holds business "${cur}" but the export is "${data.business.businessId}". IDs must stay stable. Use --force only if you are sure.`);
}
fs.mkdirSync(target, { recursive: true });
fs.writeFileSync(bFile, JSON.stringify(pickBusiness(data.business), null, 2));
fs.writeFileSync(path.join(target, 'catalogue.json'), JSON.stringify(pickCatalogue(data.catalogue), null, 2));
console.log(`Imported ${data.business.businessId} (${data.catalogue.listings.length} listings) into ${target}. Copy any image files separately.`);
