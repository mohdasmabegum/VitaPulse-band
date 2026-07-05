/* ══════════════════════════════════════
   CONFIG
══════════════════════════════════════ */
const API = "";

/* ══════════════════════════════════════
   STATE
══════════════════════════════════════ */
let authToken       = localStorage.getItem("nutri_token") || "";
let currentUsername = localStorage.getItem("nutri_user")  || "";

/* ══════════════════════════════════════
   LANDING ↔ APP VISIBILITY
══════════════════════════════════════ */
const landing   = document.getElementById("landing");
const app       = document.getElementById("app");
const authModal = document.getElementById("auth-modal");

function showApp() {
  landing.classList.add("hidden");
  authModal.classList.add("hidden");
  app.classList.remove("hidden");
  document.getElementById("account-name").textContent = currentUsername;
  document.getElementById("account-avatar").textContent =
    currentUsername.slice(0,2).toUpperCase() || "VP";
  loadHistory();
}

function showLanding() {
  app.classList.add("hidden");
  authModal.classList.add("hidden");
  landing.classList.remove("hidden");
}

// On load: if token exists go straight to app
if (authToken) showApp();

/* ══════════════════════════════════════
   LANDING BUTTONS
══════════════════════════════════════ */
document.getElementById("go-login").addEventListener("click", () => openModal("login"));
document.getElementById("go-register").addEventListener("click", () => openModal("register"));

/* ══════════════════════════════════════
   AUTH MODAL
══════════════════════════════════════ */
const authTabs      = document.querySelectorAll(".auth-tab");
const authForm      = document.getElementById("auth-form");
const authMsg       = document.getElementById("auth-msg");
const authSubmitBtn = document.getElementById("auth-submit-btn");
let authMode = "login";

function openModal(mode) {
  authMode = mode;
  authMsg.textContent = "";
  authMsg.className = "auth-msg";
  authForm.reset();
  authTabs.forEach(t => t.classList.toggle("active", t.dataset.mode === mode));
  authSubmitBtn.textContent = mode === "login" ? "Login" : "Create Account";
  authModal.classList.remove("hidden");
}

document.getElementById("modal-close").addEventListener("click", () => authModal.classList.add("hidden"));
authModal.addEventListener("click", e => { if (e.target === authModal) authModal.classList.add("hidden"); });

authTabs.forEach(tab => tab.addEventListener("click", () => openModal(tab.dataset.mode)));

authForm.addEventListener("submit", async e => {
  e.preventDefault();
  const fd = new FormData(authForm);
  const body = { username: fd.get("username").trim(), password: fd.get("password") };
  const endpoint = authMode === "login" ? "/auth/login" : "/auth/register";
  authSubmitBtn.disabled = true;
  authSubmitBtn.textContent = "Please wait…";
  authMsg.textContent = "";
  try {
    const res = await fetch(API + endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data?.detail ? JSON.stringify(data.detail) : "Failed");
    authToken = data.token;
    currentUsername = data.username;
    localStorage.setItem("nutri_token", authToken);
    localStorage.setItem("nutri_user", currentUsername);
    authMsg.textContent = "✓ Success!";
    authMsg.className = "auth-msg success";
    setTimeout(showApp, 500);
  } catch (err) {
    authMsg.textContent = err.message;
    authMsg.className = "auth-msg";
  } finally {
    authSubmitBtn.disabled = false;
    authSubmitBtn.textContent = authMode === "login" ? "Login" : "Create Account";
  }
});

/* ══════════════════════════════════════
   LOGOUT
══════════════════════════════════════ */
function doLogout() {
  authToken = ""; currentUsername = "";
  localStorage.removeItem("nutri_token");
  localStorage.removeItem("nutri_user");
  showLanding();
}
document.getElementById("sidebar-logout").addEventListener("click", doLogout);
document.getElementById("topbar-logout").addEventListener("click", doLogout);
document.getElementById("account-logout").addEventListener("click", doLogout);

/* ══════════════════════════════════════
   SIDEBAR / MOBILE HAMBURGER
══════════════════════════════════════ */
const sidebar   = document.querySelector(".sidebar");
const hamburger = document.getElementById("hamburger");
hamburger.addEventListener("click", () => sidebar.classList.toggle("open"));

// Close sidebar on outside click (mobile)
document.addEventListener("click", e => {
  if (window.innerWidth <= 768 && sidebar.classList.contains("open") &&
      !sidebar.contains(e.target) && e.target !== hamburger) {
    sidebar.classList.remove("open");
  }
});

/* ══════════════════════════════════════
   TAB NAVIGATION
══════════════════════════════════════ */
const navBtns   = document.querySelectorAll(".nav-btn");
const tabPanels = {
  symptoms:     document.getElementById("tab-symptoms"),
  recommend:    document.getElementById("tab-recommend"),
  history:      document.getElementById("tab-history"),
  content:      document.getElementById("tab-content"),
  forum:        document.getElementById("tab-forum"),
  gamification: document.getElementById("tab-gamification"),
  goals:        document.getElementById("tab-goals"),
  providers:    document.getElementById("tab-providers"),
  account:      document.getElementById("tab-account"),
};

navBtns.forEach(btn => btn.addEventListener("click", () => {
  navBtns.forEach(b => b.classList.remove("active"));
  btn.classList.add("active");
  const target = btn.dataset.tab;
  Object.entries(tabPanels).forEach(([k, el]) => el.classList.toggle("hidden", k !== target));
  if (target === "history") loadHistory();
  if (target === "content") loadContentCategories();
  if (target === "forum") loadForumPosts();
  if (target === "gamification") loadGamification();
  if (target === "goals") loadGoals();
  if (window.innerWidth <= 768) sidebar.classList.remove("open");
}));

/* ══════════════════════════════════════
   SYMPTOM CHECKER
══════════════════════════════════════ */
const symptomInput   = document.getElementById("symptom-input");
const symptomAddBtn  = document.getElementById("symptom-add-btn");
const chipRow        = document.getElementById("symptom-chips");
const followupList   = document.getElementById("symptom-followups");
const symptomResults = document.getElementById("symptom-results");
const symptomError   = document.getElementById("symptom-error");

let symptoms = [], followUpAnswers = {};

function renderChips() {
  chipRow.innerHTML = symptoms.map((s, i) =>
    `<span class="chip">${s}<button onclick="removeSymptom(${i})" title="Remove">×</button></span>`
  ).join("");
}

window.removeSymptom = i => { symptoms.splice(i, 1); renderChips(); runSymptomCheck(); };

function confClass(c) { return c >= 0.7 ? "conf-high" : c >= 0.4 ? "conf-medium" : "conf-low"; }

async function runSymptomCheck() {
  if (!symptoms.length) { symptomResults.innerHTML = ""; followupList.innerHTML = ""; return; }
  symptomError.classList.add("hidden");
  try {
    const res = await fetch(API + "/symptom-check", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ symptoms, follow_up_answers: followUpAnswers }),
    });
    if (!res.ok) throw new Error("Check failed");
    const data = await res.json();
    symptomResults.innerHTML = data.insights.length
      ? data.insights.map(i => `
          <div class="insight-card">
            <div class="confidence-badge ${confClass(i.confidence)}">${Math.round(i.confidence * 100)}%</div>
            <div><h4>${i.deficiency}</h4><p>${i.insight}</p></div>
          </div>`).join("") + `<p class="muted" style="margin-top:0.5rem">${data.disclaimer}</p>`
      : `<p class="muted">No strong deficiency signals detected yet. Add more symptoms.</p>`;
    const pending = data.follow_up_questions.filter(q => !(q in followUpAnswers));
    followupList.innerHTML = pending.map(q => `
      <div class="followup-card">
        <p>${q}</p>
        <div class="btn-row">
          <button class="btn-yes" onclick="answerFollowUp(${JSON.stringify(q)}, true)">Yes</button>
          <button class="btn-no"  onclick="answerFollowUp(${JSON.stringify(q)}, false)">No</button>
        </div>
      </div>`).join("");
  } catch (e) {
    symptomError.textContent = e.message;
    symptomError.classList.remove("hidden");
  }
}

window.answerFollowUp = (q, answer) => { followUpAnswers[q] = answer; runSymptomCheck(); };

symptomAddBtn.addEventListener("click", () => {
  const val = symptomInput.value.trim();
  if (val && !symptoms.includes(val)) { symptoms.push(val); renderChips(); }
  symptomInput.value = "";
  runSymptomCheck();
});
symptomInput.addEventListener("keydown", e => { if (e.key === "Enter") { e.preventDefault(); symptomAddBtn.click(); } });

/* ══════════════════════════════════════
   RECOMMEND
══════════════════════════════════════ */
const form    = document.getElementById("health-form");
const results = document.getElementById("results");

function num(v) { return Number(v); }
function toList(items) { return `<ul>${items.map(i => `<li>${i}</li>`).join("")}</ul>`; }
function renderCard(title, content) { return `<article class="result-card"><h3>${title}</h3>${content}</article>`; }

function renderResponse(r) {
  results.innerHTML = [
    renderCard("Risk Summary", toList(r.risk_summary)),
    renderCard("Nutrient Status", r.nutrient_status.map(n =>
      `<p><strong>${n.nutrient}</strong> <span class="badge ${n.level}">${n.level}</span><br/>Current: ${n.current_value} | Target: ${n.min_target}<br/>${n.note}</p>`
    ).join("")),
    renderCard("Food Suggestions", r.food_suggestions.map(s =>
      `<p><strong>${s.purpose}</strong></p>${toList(s.foods)}${s.avoid_or_limit.length ? `<p><strong>Limit:</strong></p>${toList(s.avoid_or_limit)}` : ""}`
    ).join("")),
    renderCard("Daily Plan", `
      <p><strong>Breakfast</strong></p>${toList(r.daily_plan.breakfast)}
      <p><strong>Lunch</strong></p>${toList(r.daily_plan.lunch)}
      <p><strong>Dinner</strong></p>${toList(r.daily_plan.dinner)}
      <p><strong>Snacks</strong></p>${toList(r.daily_plan.snacks)}`),
    renderCard("Lifestyle Actions", toList(r.lifestyle_actions)),
    renderCard("Disclaimer", `<p>${r.disclaimer}</p>`),
  ].join("");
  results.scrollIntoView({ behavior: "smooth", block: "start" });
}

form.addEventListener("submit", async e => {
  e.preventDefault();
  const btn = form.querySelector("button[type=submit]");
  const orig = btn.textContent;
  btn.textContent = "⏳ Analyzing…"; btn.disabled = true;
  try {
    const d = new FormData(form);
    const allergies = (d.get("allergies") || "").split(",").map(s => s.trim()).filter(Boolean);
    const payload = {
      age: num(d.get("age")), sex: d.get("sex"), diet_type: d.get("diet_type"), allergies,
      biomarkers: { vitamin_d_ng_ml: num(d.get("vitamin_d_ng_ml")), vitamin_b12_pg_ml: num(d.get("vitamin_b12_pg_ml")), iron_ferritin_ng_ml: num(d.get("iron_ferritin_ng_ml")), ldl_mg_dl: num(d.get("ldl_mg_dl")), hdl_mg_dl: num(d.get("hdl_mg_dl")), triglycerides_mg_dl: num(d.get("triglycerides_mg_dl")) },
      body_metrics: { height_cm: num(d.get("height_cm")), weight_kg: num(d.get("weight_kg")), body_fat_percent: num(d.get("body_fat_percent")) },
      lifestyle: { avg_daily_steps: num(d.get("avg_daily_steps")), avg_sleep_hours: num(d.get("avg_sleep_hours")), weekly_workouts: num(d.get("weekly_workouts")) },
    };
    const endpoint = authToken ? "/recommend/save" : "/recommend";
    const headers = { "Content-Type": "application/json" };
    if (authToken) headers.Authorization = `Bearer ${authToken}`;
    const res = await fetch(API + endpoint, { method: "POST", headers, body: JSON.stringify(payload) });
    if (!res.ok) { const err = await res.json(); throw new Error(err?.detail ? JSON.stringify(err.detail) : "Unknown error"); }
    renderResponse(await res.json());
    loadHistory();
  } catch (err) {
    results.innerHTML = renderCard("Request Error", `<p>${err.message}</p>`);
  } finally {
    btn.textContent = orig; btn.disabled = false;
  }
});

/* ══════════════════════════════════════
   HISTORY
══════════════════════════════════════ */
async function loadHistory() {
  const container = document.getElementById("history");
  if (!authToken) { container.innerHTML = '<p class="muted">Login to view saved recommendations.</p>'; return; }
  try {
    const res = await fetch(API + "/history?limit=10", { headers: { Authorization: `Bearer ${authToken}` } });
    if (!res.ok) { doLogout(); return; }
    const items = await res.json();
    container.innerHTML = items.length
      ? items.map(item => `<article class="history-item"><strong>${item.created_at}</strong><br/>Top risk: ${item.recommendation.risk_summary[0] || "No major risk."}</article>`).join("")
      : '<p class="muted">No saved recommendations yet.</p>';
  } catch { container.innerHTML = '<p class="muted">Could not load history.</p>'; }
}

/* ══════════════════════════════════════
   CONTENT HUB
══════════════════════════════════════ */
async function loadContentCategories() {
  const res = await fetch(API + "/content/categories");
  const cats = await res.json();
  const row = document.getElementById("content-categories");
  row.innerHTML = cats.map(c =>
    `<span class="chip" style="cursor:pointer" onclick="loadArticles('${c}')">${c.replace(/_/g," ")}</span>`
  ).join("") + `<span class="chip" style="cursor:pointer" onclick="loadArticles()">All</span>`;
  loadArticles();
}

async function loadArticles(category) {
  const url = category ? `${API}/content/articles?category=${category}` : `${API}/content/articles`;
  const res = await fetch(url);
  const articles = await res.json();
  const vRes = await fetch(category ? `${API}/content/videos?category=${category}` : `${API}/content/videos`);
  const videos = await vRes.json();
  const container = document.getElementById("content-results");
  container.innerHTML = [
    ...articles.map(a => `<article class="result-card">
      <h3>📄 ${a.title}</h3>
      <p class="muted">${a.category.replace(/_/g," ")} · ${a.read_time_min} min read</p>
      <p>${a.summary}</p>
      ${a.video_url ? `<a href="${a.video_url}" target="_blank" class="btn-primary" style="display:inline-block;margin-top:0.5rem;font-size:0.85rem">▶ Watch Video</a>` : ""}
      <button class="btn-primary" style="margin-top:0.5rem;font-size:0.85rem" onclick="loadArticleDetail('${a.id}')">Read More</button>
    </article>`),
    ...videos.map(v => `<article class="result-card">
      <h3>🎬 ${v.title}</h3>
      <p class="muted">${v.category.replace(/_/g," ")} · ${v.duration_min} min</p>
      <p>${v.description}</p>
      <a href="${v.url}" target="_blank" class="btn-primary" style="display:inline-block;margin-top:0.5rem;font-size:0.85rem">▶ Watch</a>
    </article>`),
  ].join("") || `<p class="muted">No content found.</p>`;
}

async function loadArticleDetail(id) {
  const res = await fetch(`${API}/content/articles/${id}`);
  const a = await res.json();
  document.getElementById("content-results").innerHTML = `<article class="result-card" style="grid-column:1/-1">
    <button onclick="loadArticles()" style="margin-bottom:0.75rem" class="btn-primary">← Back</button>
    <h3>${a.title}</h3>
    <p class="muted">${a.category} · ${a.read_time_min} min read</p>
    <pre style="white-space:pre-wrap;font-family:inherit;line-height:1.7">${a.content}</pre>
    ${a.references.length ? `<p class="muted" style="margin-top:0.75rem"><strong>References:</strong> ${a.references.join(", ")}</p>` : ""}
    ${a.video_url ? `<a href="${a.video_url}" target="_blank" class="btn-primary" style="display:inline-block;margin-top:0.75rem">▶ Watch Video</a>` : ""}
  </article>`;
}

document.getElementById("content-search-btn").addEventListener("click", async () => {
  const q = document.getElementById("content-search").value.trim();
  if (q.length < 2) return;
  const res = await fetch(`${API}/content/search?q=${encodeURIComponent(q)}`);
  const data = await res.json();
  const container = document.getElementById("content-results");
  container.innerHTML = [
    ...data.articles.map(a => `<article class="result-card"><h3>📄 ${a.title}</h3><p>${a.summary}</p>
      <button class="btn-primary" style="font-size:0.85rem" onclick="loadArticleDetail('${a.id}')">Read More</button></article>`),
    ...data.videos.map(v => `<article class="result-card"><h3>🎬 ${v.title}</h3><p>${v.description}</p>
      <a href="${v.url}" target="_blank" class="btn-primary" style="display:inline-block;font-size:0.85rem">▶ Watch</a></article>`),
  ].join("") || `<p class="muted">No results for "${q}".</p>`;
});

/* ══════════════════════════════════════
   FORUM
══════════════════════════════════════ */
async function loadForumPosts(category) {
  const url = category ? `${API}/forum/posts?category=${category}` : `${API}/forum/posts`;
  const res = await fetch(url, { headers: authToken ? { Authorization: `Bearer ${authToken}` } : {} });
  const posts = await res.json();
  document.getElementById("forum-posts").innerHTML = posts.length
    ? posts.map(p => `<article class="result-card">
        <strong>${p.title}</strong> <span class="badge normal">${p.category}</span>
        <p class="muted" style="margin:0.25rem 0">by ${p.username} · ${p.created_at?.slice(0,16)} · ${p.reply_count} replies</p>
        <p>${p.body}</p>
        <button class="btn-primary" style="font-size:0.85rem;margin-top:0.5rem" onclick="loadReplies(${p.id}, this)">💬 View Replies</button>
        <div id="replies-${p.id}" style="margin-top:0.5rem"></div>
      </article>`).join("")
    : `<p class="muted">No posts yet. Be the first!</p>`;
}

window.loadReplies = async (postId, btn) => {
  const container = document.getElementById(`replies-${postId}`);
  if (container.innerHTML) { container.innerHTML = ""; return; }
  const res = await fetch(`${API}/forum/posts/${postId}/replies`);
  const replies = await res.json();
  container.innerHTML = (replies.length
    ? replies.map(r => `<div style="padding:0.4rem 0;border-top:1px solid #eee"><strong>${r.username}</strong>: ${r.body}</div>`).join("")
    : `<p class="muted">No replies yet.</p>`)
    + (authToken ? `<div style="margin-top:0.5rem;display:flex;gap:0.5rem">
        <input id="reply-input-${postId}" type="text" placeholder="Write a reply…" style="flex:1" />
        <button class="btn-primary" onclick="submitReply(${postId})">Reply</button>
      </div>` : "");
};

window.submitReply = async (postId) => {
  const input = document.getElementById(`reply-input-${postId}`);
  const body = input.value.trim();
  if (body.length < 2) return;
  await fetch(`${API}/forum/posts/${postId}/replies`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${authToken}` },
    body: JSON.stringify({ body }),
  });
  input.value = "";
  loadReplies(postId, null);
};

document.getElementById("forum-post-btn").addEventListener("click", async () => {
  if (!authToken) { document.getElementById("forum-msg").textContent = "Login to post."; return; }
  const title = document.getElementById("forum-title").value.trim();
  const body = document.getElementById("forum-body").value.trim();
  const category = document.getElementById("forum-category").value;
  if (title.length < 5 || body.length < 10) {
    document.getElementById("forum-msg").textContent = "Title ≥5 chars, body ≥10 chars."; return;
  }
  await fetch(`${API}/forum/posts`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${authToken}` },
    body: JSON.stringify({ title, body, category }),
  });
  document.getElementById("forum-title").value = "";
  document.getElementById("forum-body").value = "";
  document.getElementById("forum-msg").textContent = "✓ Posted!";
  loadForumPosts();
});

/* ══════════════════════════════════════
   GAMIFICATION
══════════════════════════════════════ */
async function loadGamification() {
  const container = document.getElementById("gamification-content");
  if (!authToken) { container.innerHTML = `<p class="muted">Login to view your badges.</p>`; return; }
  const res = await fetch(API + "/gamification", { headers: { Authorization: `Bearer ${authToken}` } });
  const g = await res.json();
  container.innerHTML = `
    <div style="display:flex;gap:1.5rem;flex-wrap:wrap;align-items:center;margin-bottom:1rem">
      <div style="text-align:center"><div style="font-size:2rem">🔥</div><strong>${g.streak_days}</strong><br/><span class="muted">Day Streak</span></div>
      <div style="text-align:center"><div style="font-size:2rem">📋</div><strong>${g.total_recommendations}</strong><br/><span class="muted">Total Logs</span></div>
    </div>
    <h4>Earned Badges</h4>
    <div class="chip-row" style="margin:0.5rem 0">
      ${g.badges.length ? g.badges.map(b => `<span class="chip" title="${b.description}">${b.icon} ${b.name}</span>`).join("") : `<span class="muted">No badges yet — start logging!</span>`}
    </div>
    ${g.next_badge ? `<p class="muted" style="margin-top:0.5rem">Next: ${g.next_badge.icon} <strong>${g.next_badge.name}</strong> — ${g.next_badge.description}</p>` : ""}
  `;
}

/* ══════════════════════════════════════
   HEALTH GOALS & PDF EXPORT
══════════════════════════════════════ */
async function loadGoals() {
  if (!authToken) return;
  const res = await fetch(API + "/profile", { headers: { Authorization: `Bearer ${authToken}` } });
  const profile = await res.json();
  const g = profile.health_goals;
  const f = document.getElementById("goals-form");
  if (g.goal_weight_kg)        f.goal_weight_kg.value = g.goal_weight_kg;
  if (g.goal_steps_per_day)    f.goal_steps_per_day.value = g.goal_steps_per_day;
  if (g.goal_sleep_hours)      f.goal_sleep_hours.value = g.goal_sleep_hours;
  if (g.goal_body_fat_percent) f.goal_body_fat_percent.value = g.goal_body_fat_percent;
  if (g.focus_areas?.length)   f.focus_areas.value = g.focus_areas.join(", ");
}

document.getElementById("goals-form").addEventListener("submit", async e => {
  e.preventDefault();
  if (!authToken) { document.getElementById("goals-msg").textContent = "Login to save goals."; return; }
  const d = new FormData(e.target);
  const payload = {};
  if (d.get("goal_weight_kg"))        payload.goal_weight_kg = Number(d.get("goal_weight_kg"));
  if (d.get("goal_steps_per_day"))    payload.goal_steps_per_day = Number(d.get("goal_steps_per_day"));
  if (d.get("goal_sleep_hours"))      payload.goal_sleep_hours = Number(d.get("goal_sleep_hours"));
  if (d.get("goal_body_fat_percent")) payload.goal_body_fat_percent = Number(d.get("goal_body_fat_percent"));
  const fa = d.get("focus_areas") || "";
  payload.focus_areas = fa.split(",").map(s => s.trim()).filter(Boolean);
  await fetch(API + "/profile/goals", {
    method: "PUT",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${authToken}` },
    body: JSON.stringify(payload),
  });
  document.getElementById("goals-msg").textContent = "✓ Goals saved!";
});

document.getElementById("pdf-export-btn").addEventListener("click", async () => {
  if (!authToken) { alert("Login to export your PDF report."); return; }
  const res = await fetch(API + "/report/pdf?limit=10", { headers: { Authorization: `Bearer ${authToken}` } });
  if (!res.ok) { alert("Could not generate PDF."); return; }
  const blob = await res.blob();
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url; a.download = "vitapulse_report.pdf"; a.click();
  URL.revokeObjectURL(url);
});

/* ══════════════════════════════════════
   PROVIDER LOCATOR
══════════════════════════════════════ */
document.getElementById("prov-locate-btn").addEventListener("click", () => {
  if (!navigator.geolocation) { alert("Geolocation not supported."); return; }
  navigator.geolocation.getCurrentPosition(pos => {
    document.getElementById("prov-lat").value = pos.coords.latitude.toFixed(4);
    document.getElementById("prov-lon").value = pos.coords.longitude.toFixed(4);
  }, () => alert("Could not get location. Enter manually."));
});

document.getElementById("prov-search-btn").addEventListener("click", async () => {
  const lat = parseFloat(document.getElementById("prov-lat").value);
  const lon = parseFloat(document.getElementById("prov-lon").value);
  const radius = parseFloat(document.getElementById("prov-radius").value) || 50;
  const type = document.getElementById("prov-type").value;
  if (isNaN(lat) || isNaN(lon)) { alert("Enter valid coordinates or use 'Use My Location'."); return; }
  const res = await fetch(API + "/providers/search", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ latitude: lat, longitude: lon, radius_km: radius, type }),
  });
  const providers = await res.json();
  document.getElementById("providers-results").innerHTML = providers.length
    ? providers.map(p => `<article class="result-card">
        <strong>${p.name}</strong> ${p.low_cost ? `<span class="badge normal">Low Cost</span>` : ""}
        <p class="muted">${p.address} · ${p.distance_km} km away</p>
        ${p.phone ? `<p>📞 ${p.phone}</p>` : ""}
        <a href="${p.maps_url}" target="_blank" class="btn-primary" style="display:inline-block;margin-top:0.5rem;font-size:0.85rem">📍 Open in Maps</a>
      </article>`).join("")
    : `<p class="muted">No ${type}s found within ${radius} km. Try increasing the radius.</p>`;
});
