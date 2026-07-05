"use strict";
const functions = require("firebase-functions");
const express   = require("express");
const crypto    = require("crypto");
const { createClient } = require("@libsql/client");

const TURSO_URL   = process.env.TURSO_URL;
const TURSO_TOKEN = process.env.TURSO_TOKEN;

let _db;
function getDb() {
  if (!_db) {
    _db = createClient({ url: TURSO_URL, authToken: TURSO_TOKEN });
  }
  return _db;
}

async function initDb() {
  const db = getDb();
  await db.executeMultiple(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      salt TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS sessions (
      token TEXT PRIMARY KEY,
      user_id INTEGER NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS recommendation_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      payload_json TEXT NOT NULL,
      response_json TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);
}

/* ── Auth helpers ── */
function hashPw(pw, salt) {
  return crypto.createHash("sha256").update(`${salt}:${pw}`).digest("hex");
}
function randToken(n = 32) { return crypto.randomBytes(n).toString("hex"); }

async function getUserId(req) {
  const auth = req.headers.authorization || "";
  if (!auth.startsWith("Bearer ")) return null;
  const token = auth.slice(7).trim();
  if (!token) return null;
  const db = getDb();
  const res = await db.execute({ sql: "SELECT user_id FROM sessions WHERE token = ?", args: [token] });
  return res.rows.length ? res.rows[0].user_id : null;
}

/* ── Food DB ── */
const VITAMIN_FOODS = {
  vitamin_d:   { omnivore: ["salmon","egg yolk","fortified milk","sardines"],         vegetarian: ["fortified milk","fortified yogurt","mushrooms","fortified cereal"] },
  vitamin_b12: { omnivore: ["eggs","milk","fish","chicken"],                           vegetarian: ["milk","yogurt","paneer","fortified nutritional yeast"] },
  iron:        { omnivore: ["lean red meat","lentils","spinach","beans"],              vegetarian: ["lentils","spinach","chickpeas","pumpkin seeds"] },
};
const CHOL_HELP  = ["oats","barley","almonds","walnuts","beans","apple","broccoli","olive oil"];
const CHOL_LIMIT = ["deep-fried food","processed meat","packaged bakery snacks","trans-fat rich fast food"];
const FAT_LOSS   = ["eggs or tofu","dal or grilled chicken","mixed vegetables","brown rice or millet","greek yogurt or curd","fruits"];

function filterAllergic(items, allergies) {
  if (!allergies || !allergies.length) return items;
  const terms = allergies.map(a => a.trim().toLowerCase()).filter(Boolean);
  return items.filter(i => !terms.some(t => i.toLowerCase().includes(t)));
}
function lvl(v, lo, hi) { return v < lo ? "low" : v < hi ? "borderline" : "normal"; }

/* ── Symptom Engine ── */
const SYMPTOM_MAP = {
  "fatigue":             [["Vitamin D",0.6],["Vitamin B12",0.7],["Iron",0.8]],
  "weakness":            [["Vitamin D",0.5],["Iron",0.7]],
  "pale skin":           [["Iron",0.9],["Vitamin B12",0.6]],
  "brain fog":           [["Vitamin B12",0.8],["Vitamin D",0.4]],
  "tingling":            [["Vitamin B12",0.9]],
  "numbness":            [["Vitamin B12",0.9]],
  "bone pain":           [["Vitamin D",0.9]],
  "muscle cramps":       [["Vitamin D",0.7]],
  "hair loss":           [["Iron",0.7],["Vitamin D",0.4]],
  "shortness of breath": [["Iron",0.8],["Vitamin B12",0.5]],
  "cold hands":          [["Iron",0.7]],
  "mood swings":         [["Vitamin D",0.6],["Vitamin B12",0.5]],
  "depression":          [["Vitamin D",0.7],["Vitamin B12",0.6]],
  "poor concentration":  [["Vitamin B12",0.7],["Iron",0.5]],
  "frequent illness":    [["Vitamin D",0.7]],
  "slow healing":        [["Vitamin D",0.5],["Iron",0.5]],
};
const FOLLOW_UPS = {
  "Vitamin D":   ["Do you get less than 30 minutes of sunlight daily?","Do you live in a region with limited sunlight?"],
  "Vitamin B12": ["Are you vegetarian or vegan?","Do you experience occasional memory lapses?"],
  "Iron":        ["Do you have heavy menstrual periods (if applicable)?","Do you follow a plant-based or low-meat diet?"],
};
const INSIGHTS = {
  "Vitamin D":   "Low Vitamin D is common with limited sun exposure. It can cause fatigue, bone pain, and mood issues. Consider fortified foods or a supplement after consulting your doctor.",
  "Vitamin B12": "Vitamin B12 deficiency is frequent in vegetarians/vegans. Symptoms include fatigue, tingling, and brain fog. Eggs, dairy, or B12 supplements can help.",
  "Iron":        "Iron deficiency is the most common nutritional deficiency worldwide. Symptoms include fatigue, pale skin, and shortness of breath. Increase lentils, spinach, and pair with Vitamin C.",
};

function assessSymptoms(symptoms) {
  const scores = {};
  for (const s of symptoms) {
    const n = s.trim().toLowerCase();
    for (const [key, maps] of Object.entries(SYMPTOM_MAP)) {
      if (key.includes(n) || n.includes(key))
        for (const [def, w] of maps)
          scores[def] = Math.min(1.0, (scores[def] || 0) + w);
    }
  }
  for (const k in scores) scores[k] = Math.round(scores[k] * 100) / 100;
  return scores;
}
function applyFollowUps(scores, answers) {
  const u = { ...scores };
  for (const [def, qs] of Object.entries(FOLLOW_UPS))
    for (const q of qs)
      if (answers[q] === true)
        u[def] = Math.round(Math.min(1.0, (u[def] || 0) + 0.15) * 100) / 100;
  return u;
}
function getFollowUpQs(scores, answered) {
  const qs = [];
  for (const def of Object.keys(scores).sort((a,b) => scores[b]-scores[a]))
    for (const q of (FOLLOW_UPS[def] || []))
      if (!(q in answered)) { qs.push(q); break; }
  return qs;
}
function buildInsights(scores) {
  return Object.entries(scores)
    .filter(([,s]) => s >= 0.3)
    .sort((a,b) => b[1]-a[1])
    .map(([def, confidence]) => ({ deficiency: def, confidence, insight: INSIGHTS[def] }));
}

/* ── Recommendation Engine ── */
function buildRec(u) {
  const dk  = u.diet_type === "vegetarian" ? "vegetarian" : "omnivore";
  const dL  = lvl(u.biomarkers.vitamin_d_ng_ml,    20, 30);
  const bL  = lvl(u.biomarkers.vitamin_b12_pg_ml, 200, 300);
  const iL  = lvl(u.biomarkers.iron_ferritin_ng_ml, 30, 60);
  const ldlH = u.biomarkers.ldl_mg_dl >= 130;
  const hdlL = u.biomarkers.hdl_mg_dl < 40;
  const tgH  = u.biomarkers.triglycerides_mg_dl >= 150;
  const fatH = u.body_metrics.body_fat_percent > 30;
  const al   = u.allergies || [];

  const risk = [];
  if (dL !== "normal") risk.push("Vitamin D is below desired range.");
  if (bL !== "normal") risk.push("Vitamin B12 is below desired range.");
  if (iL !== "normal") risk.push("Iron/ferritin is below desired range.");
  if (ldlH||hdlL||tgH) risk.push("Lipid profile indicates cardiovascular risk.");
  if (fatH) risk.push("Body fat is above recommended range.");

  const sugg = [];
  if (dL !== "normal") sugg.push({ purpose:"Improve Vitamin D",     foods:filterAllergic(VITAMIN_FOODS.vitamin_d[dk],   al), avoid_or_limit:[] });
  if (bL !== "normal") sugg.push({ purpose:"Improve Vitamin B12",   foods:filterAllergic(VITAMIN_FOODS.vitamin_b12[dk], al), avoid_or_limit:[] });
  if (iL !== "normal") sugg.push({ purpose:"Improve Iron/Ferritin", foods:filterAllergic(VITAMIN_FOODS.iron[dk],        al), avoid_or_limit:[] });
  if (ldlH||hdlL||tgH) sugg.push({ purpose:"Reduce LDL & triglycerides", foods:filterAllergic(CHOL_HELP, al), avoid_or_limit:filterAllergic(CHOL_LIMIT, al) });
  if (fatH) sugg.push({ purpose:"Reduce body fat", foods:filterAllergic(FAT_LOSS, al), avoid_or_limit:filterAllergic(["sugary drinks","late-night snacking","highly processed snacks"], al) });

  return {
    risk_summary: risk.length ? risk : ["No major nutrition risk flags from provided values."],
    nutrient_status: [
      { nutrient:"Vitamin D",    level:dL, current_value:u.biomarkers.vitamin_d_ng_ml,    min_target:30,  note:"Aim for safe sunlight and fortified foods." },
      { nutrient:"Vitamin B12",  level:bL, current_value:u.biomarkers.vitamin_b12_pg_ml,  min_target:300, note:"Prioritize B12-rich foods from your diet type." },
      { nutrient:"Iron/Ferritin",level:iL, current_value:u.biomarkers.iron_ferritin_ng_ml,min_target:60,  note:"Pair iron foods with vitamin C for absorption." },
    ],
    food_suggestions: sugg,
    daily_plan: {
      breakfast: filterAllergic(["oats with milk and nuts","1 fruit"], al),
      lunch:     filterAllergic([dk==="vegetarian"?"dal or rajma/chole":"dal or lean protein","2 cups mixed vegetables","small portion brown rice"], al),
      dinner:    filterAllergic([dk==="vegetarian"?"paneer or tofu":"grilled protein or paneer","salad","soup"], al),
      snacks:    filterAllergic(["curd/greek yogurt","roasted chickpeas"], al),
    },
    lifestyle_actions: [
      "Walk at least 8000 steps/day.",
      "Perform strength training 2-3 times/week.",
      "Sleep 7-8 hours daily to support fat loss and lipid balance.",
      "Retest vitamin and lipid biomarkers every 8-12 weeks.",
    ],
    disclaimer: "This tool provides wellness guidance and is not a medical diagnosis. Consult a doctor for treatment decisions.",
  };
}

/* ── Express App ── */
const app = express();
app.use(express.json());
app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  if (req.method === "OPTIONS") return res.sendStatus(204);
  next();
});

app.get("/", (req, res) => res.json({ message: "Diet API running." }));

app.post("/auth/register", async (req, res) => {
  const { username, password } = req.body || {};
  if (!username || !password) return res.status(400).json({ detail: "username and password required" });
  const uname = username.trim().toLowerCase();
  const db = getDb();
  try {
    const existing = await db.execute({ sql: "SELECT id FROM users WHERE username = ?", args: [uname] });
    if (existing.rows.length) return res.status(409).json({ detail: "Username already exists" });
    const salt = randToken(16), hash = hashPw(password, salt);
    await db.execute({ sql: "INSERT INTO users (username, password_hash, salt) VALUES (?, ?, ?)", args: [uname, hash, salt] });
    const user = await db.execute({ sql: "SELECT id FROM users WHERE username = ?", args: [uname] });
    const token = randToken();
    await db.execute({ sql: "INSERT INTO sessions (token, user_id) VALUES (?, ?)", args: [token, user.rows[0].id] });
    res.json({ token, username: uname });
  } catch (e) {
    res.status(500).json({ detail: e.message });
  }
});

app.post("/auth/login", async (req, res) => {
  const { username, password } = req.body || {};
  const uname = (username || "").trim().toLowerCase();
  const db = getDb();
  try {
    const result = await db.execute({ sql: "SELECT id, password_hash, salt FROM users WHERE username = ?", args: [uname] });
    if (!result.rows.length) return res.status(401).json({ detail: "Invalid username or password" });
    const user = result.rows[0];
    if (hashPw(password, user.salt) !== user.password_hash)
      return res.status(401).json({ detail: "Invalid username or password" });
    const token = randToken();
    await db.execute({ sql: "INSERT INTO sessions (token, user_id) VALUES (?, ?)", args: [token, user.id] });
    res.json({ token, username: uname });
  } catch (e) {
    res.status(500).json({ detail: e.message });
  }
});

app.post("/symptom-check", (req, res) => {
  const { symptoms = [], follow_up_answers = {} } = req.body || {};
  let scores = assessSymptoms(symptoms);
  scores = applyFollowUps(scores, follow_up_answers);
  res.json({
    insights: buildInsights(scores),
    follow_up_questions: getFollowUpQs(scores, follow_up_answers),
    disclaimer: "This is a preliminary symptom-based assessment, not a medical diagnosis. Please consult a healthcare professional.",
  });
});

app.post("/recommend", (req, res) => {
  try { res.json(buildRec(req.body)); }
  catch (e) { res.status(422).json({ detail: e.message }); }
});

app.post("/recommend/save", async (req, res) => {
  const userId = await getUserId(req);
  if (!userId) return res.status(401).json({ detail: "Authorization required" });
  try {
    const rec = buildRec(req.body);
    const db = getDb();
    await db.execute({
      sql: "INSERT INTO recommendation_history (user_id, payload_json, response_json) VALUES (?, ?, ?)",
      args: [userId, JSON.stringify(req.body), JSON.stringify(rec)],
    });
    res.json(rec);
  } catch (e) { res.status(422).json({ detail: e.message }); }
});

app.get("/history", async (req, res) => {
  const userId = await getUserId(req);
  if (!userId) return res.status(401).json({ detail: "Authorization required" });
  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 10));
  const db = getDb();
  const result = await db.execute({
    sql: "SELECT id, payload_json, response_json, created_at FROM recommendation_history WHERE user_id = ? ORDER BY id DESC LIMIT ?",
    args: [userId, limit],
  });
  res.json(result.rows.map(r => ({
    id: r.id, created_at: r.created_at,
    payload: JSON.parse(r.payload_json),
    recommendation: JSON.parse(r.response_json),
  })));
});

// Initialize DB tables then start
const _init = initDb().catch(console.error);
exports.api = functions.https.onRequest(async (req, res) => {
  await _init;
  app(req, res);
});
