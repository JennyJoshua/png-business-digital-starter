import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.119.0/+esm";

const SUPABASE_URL = "https://rwcwvqlgyckfdrglsbfg.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_PYBO0dmreYrpVVRx3tUr4A_iv7Nq_yD";
const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: { autoRefreshToken: true, persistSession: true, detectSessionInUrl: true, flowType: "pkce" }
});

const $ = (s) => document.querySelector(s);
const authPanel = $("#auth-panel"), appPanel = $("#app-panel"), authMessage = $("#auth-message"), appMessage = $("#app-message");
let currentUser = null, currentBusiness = null, currentBusinessId = null, categories = [], listings = [], promotions = [], recoveryFlow = false;
const esc = (v = "") => String(v ?? "").replace(/[&<>"']/g, c => ({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[c]));
const slug = (v) => String(v).normalize("NFKD").toLowerCase().replace(/[^a-z0-9]+/g,"-").replace(/^-|-$/g,"").slice(0,70);
const message = (el, value, ok = false) => { el.textContent = value || ""; el.classList.toggle("success", ok); };
const value = (form, name) => new FormData(form).get(name)?.toString().trim() ?? "";
const isoDate = (v) => v ? new Date(v).toISOString() : null;
function showAuth(which = "signin") {
  $("#signin-form").hidden = which !== "signin";
  $("#forgot-form").hidden = which !== "forgot";
  $("#password-form").hidden = which !== "password";
  $("#forgot-link").hidden = which !== "signin";
}
function showApp() { authPanel.hidden = true; appPanel.hidden = false; }
function showSignIn() { appPanel.hidden = true; authPanel.hidden = false; showAuth("signin"); }
function switchView(name) {
  document.querySelectorAll(".view").forEach(v => v.classList.toggle("active", v.id === "view-" + name));
  document.querySelectorAll(".nav-item").forEach(b => b.classList.toggle("active", b.dataset.view === name));
  if (name === "profile") fillProfile();
}
function fillProfile() {
  if (!currentBusiness) return;
  const f = $("#profile-form");
  for (const n of ["name","business_type","tagline","description","phone","whatsapp","email","website_url","address_line","town","province"]) {
    if (f.elements[n]) f.elements[n].value = currentBusiness[n] ?? "";
  }
}
function friendlyError(error) {
  const text = error?.message || "Something went wrong. Please try again.";
  if (/schema cache|schema.*not.*exposed|PGRST106|admin_api/i.test(text)) return "The secure admin API is not enabled in this Supabase project's Data API settings yet. The project owner must expose the admin_api schema and keep app_private unexposed. No data has been changed.";
  if (/Invalid login credentials/i.test(text)) return "Email or password is incorrect.";
  if (/Email not confirmed/i.test(text)) return "Please confirm your email using the invitation email before signing in.";
  return text;
}
async function loadBusiness() {
  message(appMessage, "Checking your business access…");
  const m = await supabase.from("business_memberships").select("business_id,role,status").eq("status","active");
  if (m.error) throw m.error;
  if (!m.data?.length) throw new Error("Your account is signed in, but it has no active business-owner access. Ask the administrator to complete your business invitation.");
  const memberships = m.data;
  const ids = memberships.map(x => x.business_id);
  const b = await supabase.from("businesses").select("*").in("id", ids).order("created_at");
  if (b.error) throw b.error;
  if (!b.data?.length) throw new Error("Your owner membership exists, but its business record could not be loaded. Contact the administrator.");
  currentBusiness = b.data[0];
  currentBusinessId = currentBusiness.id;
  $("#welcome-title").textContent = currentBusiness.name;
  $("#business-status").textContent = "Publication status: " + currentBusiness.publication_status + ". Changes made here are stored in your private business record.";
  await Promise.all([loadCategories(), loadListings(), loadPromotions()]);
  updateCounts();
  fillProfile();
  message(appMessage, "");
  if (recoveryFlow) { authPanel.hidden = false; appPanel.hidden = true; showAuth("password"); }
  else showApp();
}
async function loadCategories() {
  const r = await supabase.from("categories").select("id,category_id,name,slug,description,sort_order,publication_status").eq("business_id",currentBusinessId).order("sort_order").order("name");
  if (r.error) throw r.error;
  categories = r.data || [];
  $("#categories-list").innerHTML = categories.length ? categories.map(c => `<article class="record"><div><strong>${esc(c.name)}</strong><small>${esc(c.publication_status)} · ID ${esc(c.category_id)}</small></div><div class="record-actions">${c.publication_status !== "archived" ? `<button class="outline" data-archive-category="${esc(c.id)}" type="button">Archive</button>` : ""}</div></article>`).join("") : '<p class="empty-state">No categories yet. Add your first category above.</p>';
  $("#listing-form").elements.category_id.innerHTML = '<option value="">No category</option>' + categories.filter(c=>c.publication_status!=="archived").map(c=>`<option value="${esc(c.id)}">${esc(c.name)}</option>`).join("");
}
async function loadListings() {
  const r = await supabase.from("listings").select("id,listing_id,category_id,kind,name,description,price,currency,availability_status,publication_status").eq("business_id",currentBusinessId).order("sort_order").order("name");
  if (r.error) throw r.error;
  listings = r.data || [];
  const catName = id => categories.find(c=>c.id===id)?.name || "Uncategorised";
  $("#listings-list").innerHTML = listings.length ? listings.map(l => `<article class="record"><div><strong>${esc(l.name)}</strong><small>${esc(l.kind)} · ${esc(catName(l.category_id))} · ${l.price == null ? "Price on request" : "PGK " + Number(l.price).toFixed(2)} · ${esc(l.publication_status)}</small></div><div class="record-actions">${l.publication_status !== "archived" ? `<button class="outline" data-archive-listing="${esc(l.id)}" type="button">Archive</button>` : ""}</div></article>`).join("") : '<p class="empty-state">No products or services yet. Add your first listing above.</p>';
}
async function loadPromotions() {
  const r = await supabase.from("promotions").select("id,title,internal_copy,status,starts_at,ends_at").eq("business_id",currentBusinessId).order("created_at",{ascending:false});
  if (r.error) throw r.error;
  promotions = r.data || [];
  $("#promotions-list").innerHTML = promotions.length ? promotions.map(p => `<article class="record"><div><strong>${esc(p.title)}</strong><small>Private · ${esc(p.status)}${p.starts_at ? " · Starts " + esc(new Date(p.starts_at).toLocaleString()) : ""}</small></div><div class="record-actions"><button class="outline" data-delete-promotion="${esc(p.id)}" type="button">Delete</button></div></article>`).join("") : '<p class="empty-state">No private promotions saved.</p>';
}
function updateCounts() {
  $("#count-categories").textContent = categories.filter(c=>c.publication_status!=="archived").length;
  $("#count-listings").textContent = listings.filter(l=>l.publication_status!=="archived").length;
  $("#count-promotions").textContent = promotions.length;
}
async function refreshAll() { await loadCategories(); await loadListings(); await loadPromotions(); updateCounts(); }

$("#signin-form").addEventListener("submit", async e => {
  e.preventDefault(); message(authMessage,"Signing in…");
  const email=value(e.currentTarget,"email"), password=value(e.currentTarget,"password");
  const r=await supabase.auth.signInWithPassword({email,password});
  if(r.error){message(authMessage,friendlyError(r.error));return;}
  currentUser=r.data.user;
  try { await loadBusiness(); $("#signed-in-email").textContent=currentUser.email || ""; $("#account-email").textContent=currentUser.email || ""; }
  catch(err){await supabase.auth.signOut();currentUser=null;message(authMessage,friendlyError(err));}
});
$("#forgot-link").addEventListener("click",()=>{showAuth("forgot");message(authMessage,"");$("#recovery-email").value=$("#email").value;});
$(".cancel").addEventListener("click",()=>showAuth("signin"));
$("#forgot-form").addEventListener("submit",async e=>{
  e.preventDefault();message(authMessage,"Sending recovery email…");
  const r=await supabase.auth.resetPasswordForEmail(value(e.currentTarget,"email"),{redirectTo:window.location.href});
  message(authMessage,r.error?friendlyError(r.error):"If an account exists for that email, a recovery link has been sent. Check your inbox.",!r.error);
});
$("#password-form").addEventListener("submit",async e=>{
  e.preventDefault();const p=value(e.currentTarget,"password"),confirm=value(e.currentTarget,"confirmPassword");
  if(p.length<10){message(authMessage,"Use at least 10 characters.");return;}
  if(p!==confirm){message(authMessage,"The passwords do not match.");return;}
  const r=await supabase.auth.updateUser({password:p});
  if(r.error){message(authMessage,friendlyError(r.error));return;}
  recoveryFlow=false;
  message(authMessage,"Password updated. You can now continue to the admin.",true);
  if(currentUser){try{await loadBusiness();}catch(err){message(authMessage,friendlyError(err));}}
  else showAuth("signin");
});
$("#signout").addEventListener("click",async()=>{await supabase.auth.signOut();currentUser=null;currentBusiness=null;showSignIn();});
$("#account-signout").addEventListener("click",async()=>{await supabase.auth.signOut();currentUser=null;currentBusiness=null;showSignIn();});
document.querySelectorAll(".nav-item").forEach(b=>b.addEventListener("click",()=>switchView(b.dataset.view)));

$("#profile-form").addEventListener("submit",async e=>{
  e.preventDefault();const f=e.currentTarget;
  const payload={};
  for(const n of ["name","business_type","tagline","description","phone","whatsapp","email","website_url","address_line","town","province"]) payload[n]=value(f,n)||null;
  const r=await supabase.from("businesses").update(payload).eq("id",currentBusinessId).select().single();
  if(r.error){message(appMessage,friendlyError(r.error));return;}
  currentBusiness={...currentBusiness,...r.data};$("#welcome-title").textContent=currentBusiness.name;message(appMessage,"Business profile saved.",true);
});
$("#category-form").addEventListener("submit",async e=>{
  e.preventDefault();const f=e.currentTarget,name=value(f,"name"),description=value(f,"description");
  const categorySlug=slug(name); if(!categorySlug){message(appMessage,"Use letters or numbers in the category name.");return;}
  const payload={business_id:currentBusinessId,category_id:categorySlug,name,slug:categorySlug,description:description||null,sort_order:categories.length,publication_status:"draft"};
  const r=await supabase.from("categories").insert(payload);
  if(r.error){message(appMessage,friendlyError(r.error));return;}
  f.reset();await refreshAll();message(appMessage,"Category added as a draft. Publish it only after reviewing it.",true);
});
$("#listing-form").addEventListener("submit",async e=>{
  e.preventDefault();const f=e.currentTarget,name=value(f,"name"),price=value(f,"price");
  const listingSlug=slug(name); if(!listingSlug){message(appMessage,"Use letters or numbers in the listing name.");return;}
  const payload={business_id:currentBusinessId,listing_id:listingSlug,category_id:value(f,"category_id")||null,kind:value(f,"kind"),name,slug:listingSlug,description:value(f,"description")||null,price:price===""?null:Number(price),currency:"PGK",availability_status:value(f,"availability_status")||null,publication_status:"draft",sort_order:listings.length};
  if(price!==""&&(!Number.isFinite(payload.price)||payload.price<0)){message(appMessage,"Enter a valid non-negative price.");return;}
  const r=await supabase.from("listings").insert(payload);
  if(r.error){message(appMessage,friendlyError(r.error));return;}
  f.reset();await refreshAll();message(appMessage,"Listing added as a draft. Review it before publishing.",true);
});
$("#promotion-form").addEventListener("submit",async e=>{
  e.preventDefault();const f=e.currentTarget,starts=value(f,"starts_at"),ends=value(f,"ends_at");
  const payload={business_id:currentBusinessId,title:value(f,"title"),internal_copy:value(f,"internal_copy")||null,status:value(f,"status"),starts_at:isoDate(starts),ends_at:isoDate(ends)};
  if(starts&&ends&&new Date(ends)<=new Date(starts)){message(appMessage,"The end date must be after the start date.");return;}
  const r=await supabase.from("promotions").insert(payload);
  if(r.error){message(appMessage,friendlyError(r.error));return;}
  f.reset();await loadPromotions();updateCounts();message(appMessage,"Private promotion saved. It is not shown publicly.",true);
});
document.addEventListener("click",async e=>{
  const cat=e.target.closest("[data-archive-category]"),listing=e.target.closest("[data-archive-listing]"),promo=e.target.closest("[data-delete-promotion]");
  let r;
  if(cat){if(!confirm("Archive this category? Existing listings will remain, but the category will no longer be available for new listings."))return;r=await supabase.from("categories").update({publication_status:"archived"}).eq("id",cat.dataset.archiveCategory);}
  if(listing){if(!confirm("Archive this listing? It will no longer appear in the public catalogue."))return;r=await supabase.from("listings").update({publication_status:"archived"}).eq("id",listing.dataset.archiveListing);}
  if(promo){if(!confirm("Delete this private promotion? This cannot be undone."))return;r=await supabase.from("promotions").delete().eq("id",promo.dataset.deletePromotion);}
  if(r){if(r.error){message(appMessage,friendlyError(r.error));return;}await refreshAll();message(appMessage,"Changes saved.",true);}
});

const inviteFlow = new URLSearchParams(location.search).get("type")==="invite" || location.hash.includes("type=invite");
if(inviteFlow) recoveryFlow=true;
supabase.auth.onAuthStateChange((event,session)=>{
  if(event==="PASSWORD_RECOVERY"){
    recoveryFlow=true;
    currentUser=session?.user||null;
    authPanel.hidden=false;appPanel.hidden=true;
    showAuth("password");
    message(authMessage,"Choose a new password for your account.",true);
  }
  if(event==="SIGNED_OUT"){currentUser=null;currentBusiness=null;currentBusinessId=null;showSignIn();}
});
