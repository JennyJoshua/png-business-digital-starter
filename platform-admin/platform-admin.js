import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.119.0/+esm";

const SUPABASE_URL = "https://rwcwvqlgyckfdrglsbfg.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_PYBO0dmreYrpVVRx3tUr4A_iv7Nq_yD";
const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: { autoRefreshToken: true, persistSession: true, detectSessionInUrl: true, flowType: "pkce" }
});
const db = supabase.schema("admin_api");
const $ = (selector) => document.querySelector(selector);
const authPanel = $("#auth-panel"), appPanel = $("#app-panel");
let currentUser = null, queueItems = [];

function showMessage(target, text, success = false) {
  target.textContent = text || "";
  target.classList.toggle("success", success);
}
function friendlyError(error) {
  const raw = error?.message || "Something went wrong. Please try again.";
  if (/Platform administrator access required|42501/i.test(raw)) {
    return "This account is not authorised as a platform administrator. No publication change was made.";
  }
  if (/Invalid login credentials/i.test(raw)) return "Email or password is incorrect.";
  if (/schema cache|PGRST106|admin_api/i.test(raw)) return "The platform-admin API migration is not available in the connected database yet. No data was changed.";
  if (/failed to fetch|network|load failed|timeout/i.test(raw)) return "Connection problem. Check your internet connection and try again.";
  return raw;
}
function escapeHtml(value = "") {
  return String(value ?? "").replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
}
function label(item) {
  if (item.entity_type === "business") return "Business";
  if (item.entity_type === "category") return "Category";
  return item.kind === "service" ? "Service" : "Product";
}
function availableAction(item) {
  if (item.status === "draft") return { next: "published", text: "Publish" };
  if (item.status === "published") return { next: "draft", text: "Unpublish" };
  return null;
}
function renderQueue() {
  $("#queue-count").textContent = `${queueItems.length} review records`;
  const target = $("#queue");
  if (!queueItems.length) {
    target.innerHTML = '<div class="empty"><strong>Nothing needs review right now.</strong><p class="small">New owner drafts will appear here after they are saved.</p></div>';
    return;
  }
  target.innerHTML = queueItems.map(item => {
    const action = availableAction(item);
    const subtitle = item.entity_type === "business"
      ? `Business ID: ${escapeHtml(item.business_id)} · Active owners: ${escapeHtml(item.owner_count)}`
      : `${escapeHtml(item.business_name)} · Business ID: ${escapeHtml(item.business_id)}`;
    return `<article class="item" data-entity-id="${escapeHtml(item.id)}" data-entity-type="${escapeHtml(item.entity_type)}">
      <div><div class="meta">${label(item)} · ${new Date(item.created_at).toLocaleDateString()}</div><h2>${escapeHtml(item.name)}</h2><p class="meta">${subtitle}</p><span class="status">${escapeHtml(item.status)}</span></div>
      <div class="actions">
        ${action ? `<textarea class="reason" maxlength="500" aria-label="Optional review note" placeholder="Optional review note (max 500 characters)"></textarea><div class="action-row"><button class="primary" type="button" data-next="${action.next}">${action.text}</button></div>` : '<p class="small muted">No direct action available for this status.</p>'}
      </div>
    </article>`;
  }).join("");
}
async function loadQueue() {
  $("#refresh").disabled = true;
  showMessage($("#app-message"), "Loading publication queue…");
  try {
    const { data, error } = await db.rpc("platform_admin_queue");
    if (error) throw error;
    queueItems = Array.isArray(data) ? data : [];
    renderQueue();
    showMessage($("#app-message"), "");
  } catch (error) {
    queueItems = [];
    renderQueue();
    showMessage($("#app-message"), friendlyError(error));
  } finally {
    $("#refresh").disabled = false;
  }
}
async function setStatus(card, nextStatus) {
  const type = card.dataset.entityType;
  const item = queueItems.find(row => row.id === card.dataset.entityId);
  if (!item) return;
  const action = nextStatus === "published" ? "publish" : "unpublish";
  const question = `${action === "publish" ? "Publish" : "Unpublish"} this ${type}?`;
  if (!window.confirm(question + " This changes what customers can see.")) return;
  const reason = card.querySelector(".reason")?.value.trim() || null;
  const button = card.querySelector("[data-next]");
  button.disabled = true;
  showMessage($("#app-message"), "Saving publication decision…");
  const { error } = await db.rpc("set_publication_status", {
    p_entity_type: type,
    p_entity_id: item.id,
    p_new_status: nextStatus,
    p_reason: reason
  });
  if (error) {
    button.disabled = false;
    showMessage($("#app-message"), friendlyError(error));
    return;
  }
  showMessage($("#app-message"), "Publication decision saved and recorded in the audit log.", true);
  await loadQueue();
}
$("#queue").addEventListener("click", event => {
  const button = event.target.closest("[data-next]");
  if (button) setStatus(button.closest(".item"), button.dataset.next);
});
$("#refresh").addEventListener("click", loadQueue);
$("#signout").addEventListener("click", async () => {
  await supabase.auth.signOut();
  currentUser = null;
  queueItems = [];
  authPanel.hidden = false;
  appPanel.hidden = true;
});
$("#signin-form").addEventListener("submit", async event => {
  event.preventDefault();
  showMessage($("#auth-message"), "Signing in…");
  const { data, error } = await supabase.auth.signInWithPassword({
    email: $("#email").value.trim(),
    password: $("#password").value
  });
  if (error) {
    showMessage($("#auth-message"), friendlyError(error));
    return;
  }
  currentUser = data.user;
  await enterAdmin();
});
async function enterAdmin() {
  const { data: { user } } = await supabase.auth.getUser();
  currentUser = user;
  $("#signed-in-email").textContent = user?.email || "";
  authPanel.hidden = true;
  appPanel.hidden = false;
  await loadQueue();
}
supabase.auth.onAuthStateChange((event) => {
  if (event === "SIGNED_OUT") {
    currentUser = null;
    authPanel.hidden = false;
    appPanel.hidden = true;
  }
});
const { data: { session } } = await supabase.auth.getSession();
if (session?.user) await enterAdmin();
