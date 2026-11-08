import { esc, safeUrl, digits, formatPrice } from './lib.mjs';

const initials = (n) => n.split(/\s+/).filter(Boolean).slice(0, 2).map((w) => w[0].toUpperCase()).join('');
export const logoSvg = (b) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="18" fill="${b.brand.primary}"/><text x="50" y="62" font-size="42" font-family="Arial" font-weight="700" text-anchor="middle" fill="#fff">${esc(initials(b.name))}</text></svg>`;
export const placeholderSvg = (b, l) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300"><rect width="400" height="300" fill="${b.brand.primary}" opacity=".12"/><text x="200" y="160" font-size="26" font-family="Arial" text-anchor="middle" fill="${b.brand.primary}">${esc(l.name.slice(0, 26))}</text></svg>`;

const waLink = (b, text) => b.whatsapp ? `https://wa.me/${digits(b.whatsapp).replace('+', '')}?text=${encodeURIComponent(text)}` : null;
const price = (b, l) => (b.demo ? 'Sample: ' : '') + formatPrice(l, b.currency);
const kindLabel = (b, l) => (b.demo ? 'Sample ' : '') + (l.kind === 'service' ? 'service' : 'product');

const errScript = `<script>document.addEventListener('error',function(e){var t=e.target;if(t&&t.tagName==='IMG'&&t.dataset.fallback&&!t.dataset.done){t.dataset.done=1;t.src=t.dataset.fallback}},true)</script>`;

function shell(b, { title, body, depth = 0, script = '' }) {
  const r = '../'.repeat(depth);
  const full = b.demo ? `[DEMO] ${title}` : title;
  const social = Object.entries(b.social).map(([n, u]) => safeUrl(u) && `<a href="${esc(safeUrl(u))}" rel="noopener noreferrer" target="_blank">${esc(n)}<span class="sr"> (opens in a new tab)</span></a>`).filter(Boolean).join(' · ');
  const loc = [b.location.address, b.location.town, b.location.province].filter(Boolean).join(', ');
  const banner = b.demo ? `<aside class="demo-banner" aria-label="Demonstration notice"><strong>DEMONSTRATION DATA.</strong> This is a sample storefront. The business, products, prices and contact details are not real.</aside>` : '';
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(full)}</title><meta name="description" content="${esc((b.demo ? 'DEMO: ' : '') + b.description.slice(0, 150))}">${b.demo ? '<meta name="robots" content="noindex,nofollow">' : ''}
<meta property="og:title" content="${esc(full)}"><meta property="og:description" content="${esc(b.description.slice(0, 150))}">
<link rel="icon" href="${r}${b.logoFile}"><link rel="stylesheet" href="${r}assets/styles.css">
<style>:root{--primary:${b.brand.primary};--accent:${b.brand.accent}</style>${errScript}</head><body>
<a class="skip" href="#main">Skip to main content</a>${banner}
<header class="top"><div class="wrap"><a class="brand" href="${r}index.html"><img src="${r}${b.logoFile}" data-fallback="${r}assets/logo-fallback.svg" width="38" height="38" alt=""><span>${esc(b.name)}</span></a>
<nav aria-label="Main"><a href="${r}index.html#catalogue">Catalogue</a><a href="${r}index.html#contact">Contact</a></nav></div></header>
<main id="main" tabindex="-1">${body}</main>
<footer id="contact"><div class="wrap"><strong>${esc(b.name)}</strong><br>${esc(loc)}<br>
${b.phone ? `<a href="tel:${esc(digits(b.phone))}">${esc(b.phone)}</a> · ` : ''}${b.whatsapp ? `<a href="${esc(waLink(b, 'Hello ' + b.name))}">WhatsApp</a> · ` : ''}${b.email ? `<a href="mailto:${esc(b.email)}">${esc(b.email)}</a>` : ''}
${social ? `<br>${social}` : ''}<p class="notice">Standalone storefront. Not a registered or approved marketplace provider unless stated by the marketplace.</p></div></footer>${script}</body></html>`;
}

const cardHtml = (b, l, c) => {
  const category = (c.categories || []).find((x) => x.id === l.categoryId);
  return `<a class="card" data-cat="${esc(l.categoryId || '')}" data-q="${esc((l.name + ' ' + (l.description || '') + ' ' + (category?.name || '')).toLowerCase())}" data-name="${esc(l.name.toLowerCase())}" data-price="${Number.isFinite(l.price) ? l.price : -1}" href="p/${esc(l.listingId)}.html"><img loading="lazy" src="${esc(l.imageFile)}" data-fallback="assets/img/${esc(l.listingId)}-placeholder.svg" width="400" height="300" alt=""><div class="b"><h3>${esc(l.name)}</h3><div class="tag">${esc(kindLabel(b, l))}${category ? ' · ' + esc(category.name) : ''}</div><div class="notice">${esc(b.name)}</div><div class="price">${esc(price(b, l))}</div></div></a>`;
};

export function renderHome(b, c) {
  const cats = (c.categories || []).map((x) => `<button type="button" class="chip" aria-pressed="false" data-cat="${esc(x.id)}">${esc(x.name)}</button>`).join('');
  const cover = b.coverFile ? ` cover" style="background-image:linear-gradient(rgba(0,0,0,.55),rgba(0,0,0,.55)),url('${b.coverFile}')` : '';
  const has = c.listings.length > 0;
  const catalogue = has ? `<div class="tools search-tools"><label class="sr" for="q">Search products and services</label><input type="search" id="q" placeholder="Search products and services" autocomplete="off" aria-controls="suggestions"><a class="btn alt" id="view-all" href="search.html">View all results</a></div><div id="suggestions" class="suggestions" role="listbox" aria-label="Search suggestions" hidden></div>
<div class="chips" role="group" aria-label="Filter by category"><button type="button" class="chip on" aria-pressed="true" data-cat="">All</button>${cats}</div>
<p class="notice" id="status" role="status" aria-live="polite"></p><div class="grid" id="grid">${c.listings.map((l) => cardHtml(b, l, c)).join('')}</div>` : '<p class="empty">No products or services have been listed yet. Please check back soon or contact us.</p>';
  const body = `<div class="hero${cover}"><div class="wrap"><div class="home-brand"><img src="${esc(b.logoFile)}" data-fallback="assets/logo-fallback.svg" width="64" height="64" alt="${esc(b.name)} logo"><div><h1>${esc(b.name)}</h1><p>${esc(b.tagline || b.description)}</p></div></div>
<a class="btn" href="#catalogue">Browse catalogue</a>${b.whatsapp ? `<a class="btn alt" href="${esc(waLink(b, 'Hello ' + b.name))}">WhatsApp us</a>` : ''}</div></div>
${b.description ? `<section><div class="wrap"><div class="panel"><h2>About us</h2><p>${esc(b.description)}</p></div></div></section>` : ''}
<section id="catalogue"><div class="wrap"><h2>Catalogue</h2>${catalogue}</div></section>`;
  const script = has ? `<script>(function(){var q=document.getElementById('q'),st=document.getElementById('status'),cards=[].slice.call(document.querySelectorAll('#grid .card')),chips=[].slice.call(document.querySelectorAll('.chip')),box=document.getElementById('suggestions'),all=document.getElementById('view-all'),cat='';function filter(){var t=q.value.toLowerCase().trim(),n=0;cards.forEach(function(c){var ok=(!cat||c.dataset.cat===cat)&&(!t||c.dataset.q.indexOf(t)>-1);c.classList.toggle('hidden',!ok);if(ok)n++});st.textContent=(t||cat)?(n?n+' of '+cards.length+' shown':'Nothing matches your search.'):'';all.href='search.html?q='+encodeURIComponent(q.value);box.replaceChildren();if(!t){box.hidden=true;return}cards.filter(function(c){return c.dataset.q.indexOf(t)>-1}).slice(0,5).forEach(function(c){var a=document.createElement('a');a.className='suggestion';a.href=c.href;a.setAttribute('role','option');a.textContent=c.querySelector('h3').textContent+' — '+c.querySelector('.tag').textContent;box.appendChild(a)});chips.filter(function(ch){return ch.dataset.cat&&ch.textContent.toLowerCase().indexOf(t)>-1}).slice(0,3).forEach(function(ch){var a=document.createElement('a');a.className='suggestion';a.href='search.html?category='+encodeURIComponent(ch.dataset.cat);a.setAttribute('role','option');a.textContent='Category: '+ch.textContent;box.appendChild(a)});box.hidden=box.childElementCount===0}q.addEventListener('input',filter);q.addEventListener('keydown',function(e){if(e.key==='Escape'){q.value='';filter();box.hidden=true}});chips.forEach(function(ch){ch.addEventListener('click',function(){cat=ch.dataset.cat;chips.forEach(function(x){var on=x===ch;x.classList.toggle('on',on);x.setAttribute('aria-pressed',on)});filter()})})})()</script>` : '';
  return shell(b, { title: b.name, body, script });
}

export function renderSearchResults(b, c) {
  const cats = (c.categories || []).map((x) => `<option value="${esc(x.id)}">${esc(x.name)}</option>`).join('');
  const cards = c.listings.map((l) => cardHtml(b, l, c)).join('');
  const body = `<section><div class="wrap"><p><a href="index.html#catalogue">&larr; Back to storefront</a></p><h1>Search results</h1><div class="tools"><label class="sr" for="results-q">Search products and services</label><input id="results-q" type="search" placeholder="Search products and services"><label class="sr" for="results-cat">Filter by category</label><select id="results-cat"><option value="">All categories</option>${cats}</select><label class="sr" for="results-sort">Sort results</label><select id="results-sort"><option value="relevance">Most relevant</option><option value="name">Name: A to Z</option><option value="price-asc">Price: low to high</option><option value="price-desc">Price: high to low</option></select><button type="button" class="btn alt" id="clear-results">Clear search</button></div><p id="results-status" class="notice" role="status" aria-live="polite"></p><div class="grid" id="results-grid">${cards}</div><p id="results-empty" class="empty" hidden>No matching products or services. Try another search or clear your filters.</p></div></section>`;
  const script = `<script>(function(){var params=new URLSearchParams(location.search),q=document.getElementById('results-q'),cat=document.getElementById('results-cat'),sort=document.getElementById('results-sort'),clear=document.getElementById('clear-results'),grid=document.getElementById('results-grid'),status=document.getElementById('results-status'),empty=document.getElementById('results-empty'),cards=[].slice.call(grid.children);q.value=params.get('q')||'';cat.value=params.get('category')||'';function run(){var term=q.value.toLowerCase().trim(),selected=cat.value,list=cards.filter(function(c){return(!selected||c.dataset.cat===selected)&&(!term||c.dataset.q.indexOf(term)>-1)});if(sort.value==='name')list.sort(function(a,b){return a.dataset.name.localeCompare(b.dataset.name)});if(sort.value==='price-asc')list.sort(function(a,b){return Number(a.dataset.price)<0?1:Number(b.dataset.price)<0?-1:Number(a.dataset.price)-Number(b.dataset.price)});if(sort.value==='price-desc')list.sort(function(a,b){return Number(a.dataset.price)<0?1:Number(b.dataset.price)<0?-1:Number(b.dataset.price)-Number(a.dataset.price)});list.forEach(function(c){grid.appendChild(c)});cards.filter(function(c){return list.indexOf(c)<0}).forEach(function(c){grid.appendChild(c);c.classList.add('hidden')});list.forEach(function(c){c.classList.remove('hidden')});status.textContent=list.length+' result'+(list.length===1?'':'s');empty.hidden=list.length!==0}q.addEventListener('input',run);cat.addEventListener('change',run);sort.addEventListener('change',run);clear.addEventListener('click',function(){q.value='';cat.value='';sort.value='relevance';run();q.focus()});run()})()</script>`;
  return shell(b, { title: 'Search results - ' + b.name, body, script });
}

export function renderListing(b, c, l) {
  const cat = (c.categories || []).find((x) => x.id === l.categoryId);
  const wa = waLink(b, `Hello ${b.name}, I am interested in: ${l.name}`);
  const body = `<section><div class="wrap"><p><a href="../index.html#catalogue">&larr; Back to catalogue</a></p><div class="detail">
<img src="../${esc(l.imageFile)}" data-fallback="../assets/img/${esc(l.listingId)}-placeholder.svg" width="400" height="300" alt="${esc(l.name)}"><div><h1>${esc(l.name)}</h1>
<div class="tag">${esc(kindLabel(b, l))}${cat ? ' · ' + esc(cat.name) : ''}</div><p class="price big">${esc(price(b, l))}</p><p>${esc(l.description || '')}</p>
<div class="actions">${wa ? `<a class="btn" href="${esc(wa)}">Enquire on WhatsApp</a>` : ''}${b.phone ? `<a class="btn alt" href="tel:${esc(digits(b.phone))}">Call ${esc(b.phone)}</a>` : ''}
<button type="button" class="btn alt" id="share">Share this page</button></div><p class="notice">Listing ID: ${esc(l.listingId)}</p></div></div></div></section>`;
  const script = `<script>document.getElementById('share').addEventListener('click',function(){var d={title:document.title,url:location.href};if(navigator.share){navigator.share(d).catch(function(){})}else if(navigator.clipboard){navigator.clipboard.writeText(d.url);this.textContent='Link copied'}else{prompt('Copy this link',d.url)}})</script>`;
  return shell(b, { title: `${l.name} - ${b.name}`, body, depth: 1, script });
}
