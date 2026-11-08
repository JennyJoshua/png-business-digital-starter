// Shared validation + helpers. No business-specific content lives here.
export const SCHEMA_VERSION = '1.0';
export const SUPPORTED_TYPES = ['hardware-supplier', 'general-retail', 'service-provider', 'other'];
const ID_RE = /^[a-z0-9][a-z0-9-]{1,63}$/;
const HEX_RE = /^#[0-9a-fA-F]{6}$/;
const PHONE_RAW_RE = /^\+?[0-9 ]{6,24}$/;
const EMAIL_RE = /^[^\s@<>"']+@[^\s@<>"']+\.[^\s@<>"']+$/;
const IMG_EXT_RE = /\.(png|jpe?g|webp|svg)$/i;

export const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
export const safeUrl = (u) => { try { const x = new URL(u); return ['http:', 'https:'].includes(x.protocol) ? x.href : null; } catch { return null; } };
export const digits = (p) => String(p || '').replace(/[^0-9+]/g, '');

export const DEFAULTS = {
  brand: { primary: '#0b6e4f', accent: '#f2a900' },
  currency: { code: 'PGK', symbol: 'K', position: 'before', decimals: 2 },
  coverImage: null, logo: null, email: null, phone: null, whatsapp: null, demo: false,
  location: { address: '', town: '', province: '' }, social: {}, description: ''
};

// ---- colour contrast (WCAG 2.x) ----
const lum = (hex) => { const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255).map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4)); return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
export const contrastRatio = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
export const INK = '#1b1f23'; export const PAGE_BG = '#f7f7f5';

// Returns an error message if an image reference is unsafe, else null. Files must live inside the business folder.
export function imagePathProblem(p) {
  if (typeof p !== 'string' || !p.trim()) return 'must be a file path as text';
  if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(p) || p.startsWith('//')) return 'must be a local file inside the business folder, not a URL';
  if (p.startsWith('/') || p.includes('\\') || p.split('/').includes('..')) return 'must be a relative path inside the business folder (no "..", no leading "/")';
  if (!IMG_EXT_RE.test(p)) return 'must end in .png, .jpg, .jpeg, .webp or .svg';
  return null;
}

const PLACEHOLDER_NAME_RE = /your business|replace (this|me)|\(replace\)|lorem ipsum/i;
const PLACEHOLDER_PHONE_RE = /^\+?6750{5,}/;
const PLACEHOLDER_MAIL_RE = /@(example\.(com|org|net)|[^@]*\.(invalid|test|example))$/i;

export function validate(business, catalogue) {
  const E = [];
  const B = (f, m) => E.push(`business.json › ${f}: ${m}`);
  const C = (f, m) => E.push(`catalogue.json › ${f}: ${m}`);
  const text = (err, path, v, { req = false, max = 500 } = {}) => {
    if (v == null || v === '') { if (req) err(path, 'is required'); return false; }
    if (typeof v !== 'string') { err(path, 'must be text'); return false; }
    if (v.length > max) { err(path, `too long (${v.length} characters, maximum ${max})`); return false; }
    return true;
  };
  const isObj = (v) => v && typeof v === 'object' && !Array.isArray(v);
  if (!isObj(business)) { B('(file)', 'must be a JSON object'); return E; }

  if (text(B, 'businessId', business.businessId, { req: true, max: 64 }) && !ID_RE.test(business.businessId)) B('businessId', 'use 2-64 characters: lowercase letters, digits and hyphens, starting with a letter or digit');
  text(B, 'name', business.name, { req: true, max: 80 });
  text(B, 'tagline', business.tagline, { max: 160 });
  text(B, 'description', business.description, { max: 2000 });
  if (text(B, 'type', business.type, { req: true, max: 40 }) && !SUPPORTED_TYPES.includes(business.type)) B('type', `"${business.type}" is not supported. Use one of: ${SUPPORTED_TYPES.join(', ')}`);
  if (business.demo != null && typeof business.demo !== 'boolean') B('demo', 'must be true or false');
  if (business.schemaVersion != null && !/^1(\.\d+)?$/.test(String(business.schemaVersion))) B('schemaVersion', `"${business.schemaVersion}" is not supported (this template reads 1.x)`);

  if (business.brand != null && !isObj(business.brand)) B('brand', 'must be an object');
  else {
    for (const k of ['primary', 'accent']) { const v = business.brand?.[k]; if (v != null && !(typeof v === 'string' && HEX_RE.test(v))) B(`brand.${k}`, `"${v}" is not a valid colour; use #RRGGBB such as #0b6e4f`); }
    const p = business.brand?.primary;
    if (HEX_RE.test(p || '')) {
      const w = contrastRatio(p, '#ffffff'), g = contrastRatio(p, PAGE_BG);
      if (Math.min(w, g) < 4.5) B('brand.primary', `${p} is too light: text contrast is ${Math.min(w, g).toFixed(1)}:1, needs at least 4.5:1 against white and the page background. Choose a darker colour`);
    }
    const a = business.brand?.accent;
    if (HEX_RE.test(a || '') && contrastRatio(a, INK) < 4.5) B('brand.accent', `${a} is too dark: dark button text would have contrast ${contrastRatio(a, INK).toFixed(1)}:1, needs at least 4.5:1. Choose a lighter accent`);
  }

  for (const k of ['phone', 'whatsapp']) {
    const v = business[k]; if (!text(B, k, v, { max: 24 })) continue;
    const n = digits(v).replace('+', '');
    if (!PHONE_RAW_RE.test(v) || n.length < 6 || n.length > 15) B(k, `"${v}" is not a valid number; use digits with an optional leading + (e.g. +675XXXXXXXX)`);
  }
  if (text(B, 'email', business.email, { max: 120 }) && !EMAIL_RE.test(business.email)) B('email', `"${business.email}" is not a valid email address`);
  for (const k of ['logo', 'coverImage']) if (business[k] != null) { const m = imagePathProblem(business[k]); if (m) B(k, m); }

  if (business.location != null && !isObj(business.location)) B('location', 'must be an object');
  else for (const k of ['address', 'town', 'province']) text(B, `location.${k}`, business.location?.[k], { max: 120 });
  if (business.social != null && !isObj(business.social)) B('social', 'must be an object of name: URL pairs');
  else for (const [n, u] of Object.entries(business.social || {})) { if (n.length > 30) B(`social.${n.slice(0, 10)}…`, 'name too long (max 30)'); if (typeof u !== 'string' || u.length > 300 || !safeUrl(u)) B(`social.${n}`, 'must be a full http:// or https:// web address'); }
  if (business.currency != null && !isObj(business.currency)) B('currency', 'must be an object');
  else if (business.currency) {
    const c = business.currency; text(B, 'currency.code', c.code, { max: 5 }); text(B, 'currency.symbol', c.symbol, { max: 5 });
    if (c.position != null && !['before', 'after'].includes(c.position)) B('currency.position', 'must be "before" or "after"');
    if (c.decimals != null && !(Number.isInteger(c.decimals) && c.decimals >= 0 && c.decimals <= 4)) B('currency.decimals', 'must be a whole number from 0 to 4');
  }

  if (!isObj(catalogue)) { C('(file)', 'must be a JSON object'); return E; }
  const catIds = new Set();
  if (catalogue.categories != null && !Array.isArray(catalogue.categories)) C('categories', 'must be a list');
  else (catalogue.categories || []).forEach((c, i) => {
    const w = `categories[${i}]`;
    if (!isObj(c)) return C(w, 'must be an object with id and name');
    if (text(C, `${w}.id`, c.id, { req: true, max: 64 }) && !ID_RE.test(c.id)) C(`${w}.id`, `"${c.id}" must be lowercase letters, digits and hyphens`);
    text(C, `${w}.name`, c.name, { req: true, max: 60 });
    if (catIds.has(c.id)) C(`${w}.id`, `duplicate category id "${c.id}"`); catIds.add(c.id);
  });
  if (!Array.isArray(catalogue.listings)) { C('listings', 'must be a list (it may be empty)'); return E; }
  const seen = new Set();
  catalogue.listings.forEach((l, i) => {
    const w = `listings[${i}]`;
    if (!isObj(l)) return C(w, 'must be an object');
    const tag = l.listingId ? `${w} (${l.listingId})` : w;
    if (text(C, `${w}.listingId`, l.listingId, { req: true, max: 64 }) && !ID_RE.test(l.listingId)) C(`${w}.listingId`, `"${l.listingId}" must be 2-64 characters: lowercase letters, digits and hyphens`);
    if (seen.has(l.listingId)) C(`${w}.listingId`, `duplicate listingId "${l.listingId}"; every listing needs its own permanent ID`); seen.add(l.listingId);
    text(C, `${tag}.name`, l.name, { req: true, max: 100 });
    text(C, `${tag}.description`, l.description, { max: 1000 });
    text(C, `${tag}.priceNote`, l.priceNote, { max: 40 });
    if (!['product', 'service'].includes(l.kind)) C(`${tag}.kind`, 'must be "product" or "service"');
    if (l.categoryId != null && !catIds.has(l.categoryId)) C(`${tag}.categoryId`, `"${l.categoryId}" is not defined in categories`);
    if (l.price != null && !(typeof l.price === 'number' && Number.isFinite(l.price) && l.price >= 0 && l.price <= 1e9)) C(`${tag}.price`, `"${l.price}" must be a number from 0 up (leave it out for "Ask for price")`);
    if (l.image != null) { const m = imagePathProblem(l.image); if (m) C(`${tag}.image`, m); }
  });

  // Placeholder / sample data must never pass as a real customer.
  if (business.demo !== true) {
    const P = (f, m) => B(f, `${m}. Replace it with real information, or set "demo": true to mark this as a demonstration`);
    if (PLACEHOLDER_NAME_RE.test(`${business.name} ${business.description || ''} ${business.tagline || ''}`)) P('name/description', 'still contains placeholder wording');
    for (const k of ['phone', 'whatsapp']) if (business[k] && PLACEHOLDER_PHONE_RE.test(digits(business[k]))) P(k, `"${business[k]}" is a placeholder number`);
    if (business.email && PLACEHOLDER_MAIL_RE.test(business.email)) P('email', `"${business.email}" is a placeholder address`);
    catalogue.listings.forEach((l, i) => { if (isObj(l) && PLACEHOLDER_NAME_RE.test(`${l.name} ${l.description || ''}`)) C(`listings[${i}] (${l.listingId})`, 'still contains placeholder wording. Replace it, or set "demo": true in business.json'); });
  }
  return E;
}

export const withDefaults = (b) => ({ ...DEFAULTS, ...b, brand: { ...DEFAULTS.brand, ...b.brand }, currency: { ...DEFAULTS.currency, ...b.currency }, location: { ...DEFAULTS.location, ...b.location } });

export function formatPrice(l, cur) {
  if (l.price == null) return l.priceNote || 'Ask for price';
  const n = l.price.toFixed(cur.decimals);
  const s = cur.position === 'after' ? `${n} ${cur.symbol}` : `${cur.symbol}${n}`;
  return l.priceNote ? `${s} ${l.priceNote}` : s;
}

// ---- portable export: whitelist only, so private/extra fields never reach the public export ----
const pick = (o, keys) => Object.fromEntries(keys.filter((k) => o[k] !== undefined).map((k) => [k, o[k]]));
const B_KEYS = ['schemaVersion', 'businessId', 'name', 'type', 'demo', 'tagline', 'description', 'logo', 'coverImage', 'brand', 'phone', 'whatsapp', 'email', 'location', 'social', 'currency'];
const L_KEYS = ['listingId', 'name', 'kind', 'categoryId', 'description', 'image', 'price', 'priceNote'];
export const pickBusiness = (b) => pick(b, B_KEYS);
export const pickCatalogue = (c) => ({ ...pick(c, ['schemaVersion']), categories: (c.categories || []).map((x) => pick(x, ['id', 'name'])), listings: c.listings.map((l) => pick(l, L_KEYS)) });
export const toExport = (b, c) => ({ schemaVersion: SCHEMA_VERSION, exportedFrom: 'png-business-digital-starter', business: pickBusiness(b), catalogue: pickCatalogue(c) });
