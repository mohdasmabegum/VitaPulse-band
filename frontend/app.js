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
  symptoms:  document.getElementById("tab-symptoms"),
  recommend: document.getElementById("tab-recommend"),
  history:   document.getElementById("tab-history"),
  account:   document.getElementById("tab-account"),
};

navBtns.forEach(btn => btn.addEventListener("click", () => {
  navBtns.forEach(b => b.classList.remove("active"));
  btn.classList.add("active");
  const target = btn.dataset.tab;
  Object.entries(tabPanels).forEach(([k, el]) => el.classList.toggle("hidden", k !== target));
  if (target === "history") loadHistory();
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
