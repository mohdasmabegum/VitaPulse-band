from __future__ import annotations

import io
import math
from pathlib import Path

from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles

from app.db import (
    create_forum_post, create_forum_reply, create_session,
    get_forum_posts, get_forum_replies, get_history,
    get_recommendation_count, get_streak_days, get_user_goals,
    get_user_id_by_token, get_username, init_db,
    register_user, save_recommendation, save_user_goals, verify_user,
)
from app.engine import build_recommendation
from app.ml_engine import generate_ml_insights
from app.alert_engine import generate_health_alerts
from app.content_db import get_article_by_id, get_articles, get_videos, search_content, CATEGORIES
from app.models import (
    ArticleDetail, ArticleSummary, AuthCredentials, AuthResponse,
    Badge, ContentSearchResponse, DeficiencyInsight, EdgeNotification,
    EdgeNotificationRequest, EdgeNotificationResponse, ForumPost, ForumPostCreate,
    ForumReply, ForumReplyCreate, GamificationStatus, HealthAlertRequest, HealthAlertResponse,
    HealthGoals, MLInsightRequest, MLInsightResponse, ProviderResult, ProviderSearchRequest,
    RecommendationResponse, SavedRecommendation, SymptomAssessmentResponse, SymptomInput,
    UserInput, UserProfile, VideoItem,
)
from app.symptom_engine import apply_follow_up_answers, assess_symptoms, build_insights, get_follow_up_questions

APP_KEY = "vp-a8f3c2e1d4b7"

app = FastAPI(
    title="Diet Recommendation System",
    version="0.1.0",
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://vitapulse-band.web.app", "http://localhost:3000", "http://127.0.0.1:8000"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def require_app_key(request: Request, call_next):
    public = (
        "/", "/dashboard", "/auth/register", "/auth/login",
        "/recommend", "/recommend/save", "/history",
        "/symptom-check", "/upload-report",
        "/ml-insights", "/health-alerts",
        "/content/articles", "/content/videos", "/content/search", "/content/categories",
        "/providers/search", "/edge/notify",
        "/forum/posts", "/gamification", "/profile", "/profile/goals", "/report/pdf",
    )
    if (request.url.path in public
            or request.url.path.startswith("/static")
            or request.url.path.startswith("/content/articles/")
            or request.url.path.startswith("/forum/posts/")):
        return await call_next(request)
    key = request.headers.get("X-App-Key")
    if key != APP_KEY:
        return JSONResponse(status_code=403, content={"detail": "Forbidden"})
    return await call_next(request)


BASE_DIR = Path(__file__).resolve().parent.parent
FRONTEND_DIR = BASE_DIR / "frontend"

if FRONTEND_DIR.exists():
    app.mount("/static", StaticFiles(directory=FRONTEND_DIR), name="static")

init_db()


def _extract_token(authorization: str | None) -> str:
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header is required")
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Use Bearer token authorization")
    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(status_code=401, detail="Empty token")
    return token


def get_current_user_id(authorization: str | None = Header(default=None)) -> int:
    token = _extract_token(authorization)
    user_id = get_user_id_by_token(token)
    if user_id is None:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user_id


# ── Core ──────────────────────────────────────────────────────────────────────

@app.get("/")
def root() -> dict[str, str]:
    return {"message": "Diet Recommendation System API is running."}


@app.get("/dashboard")
def dashboard() -> FileResponse:
    return FileResponse(FRONTEND_DIR / "index.html")


@app.post("/auth/register", response_model=AuthResponse)
def auth_register(payload: AuthCredentials) -> AuthResponse:
    created = register_user(payload.username, payload.password)
    if not created:
        raise HTTPException(status_code=409, detail="Username already exists")
    user_id = verify_user(payload.username, payload.password)
    if user_id is None:
        raise HTTPException(status_code=500, detail="Failed to initialize user session")
    token = create_session(user_id)
    return AuthResponse(token=token, username=payload.username.strip().lower())


@app.post("/auth/login", response_model=AuthResponse)
def auth_login(payload: AuthCredentials) -> AuthResponse:
    user_id = verify_user(payload.username, payload.password)
    if user_id is None:
        raise HTTPException(status_code=401, detail="Invalid username or password")
    token = create_session(user_id)
    return AuthResponse(token=token, username=payload.username.strip().lower())


@app.post("/symptom-check", response_model=SymptomAssessmentResponse)
def symptom_check(payload: SymptomInput) -> SymptomAssessmentResponse:
    scores = assess_symptoms(payload.symptoms)
    if payload.follow_up_answers:
        scores = apply_follow_up_answers(scores, payload.follow_up_answers)
    insights = [DeficiencyInsight(**i) for i in build_insights(scores)]
    follow_ups = get_follow_up_questions(scores, payload.follow_up_answers)
    return SymptomAssessmentResponse(
        insights=insights,
        follow_up_questions=follow_ups,
        disclaimer="This is a preliminary symptom-based assessment, not a medical diagnosis. Please consult a healthcare professional.",
    )


@app.post("/ml-insights", response_model=MLInsightResponse)
def ml_insights(payload: MLInsightRequest) -> MLInsightResponse:
    result = generate_ml_insights(payload.biomarkers.model_dump(), payload.lifestyle.model_dump(), payload.history or [])
    return MLInsightResponse(**result)


@app.post("/health-alerts", response_model=HealthAlertResponse)
def health_alerts(payload: HealthAlertRequest) -> HealthAlertResponse:
    result = generate_health_alerts(payload.biomarkers.model_dump(), payload.lifestyle.model_dump(), payload.user_goals or {}, payload.history or [])
    return HealthAlertResponse(**result)


@app.post("/recommend", response_model=RecommendationResponse)
def recommend(payload: UserInput) -> RecommendationResponse:
    return build_recommendation(payload)


@app.post("/recommend/save", response_model=RecommendationResponse)
def recommend_and_save(payload: UserInput, user_id: int = Depends(get_current_user_id)) -> RecommendationResponse:
    recommendation = build_recommendation(payload)
    save_recommendation(user_id=user_id, payload=payload, recommendation=recommendation)
    return recommendation


@app.get("/history", response_model=list[SavedRecommendation])
def history(limit: int = 20, user_id: int = Depends(get_current_user_id)) -> list[SavedRecommendation]:
    return get_history(user_id=user_id, limit=max(1, min(limit, 100)))


MAX_REPORT_BYTES = 5 * 1024 * 1024
ALLOWED_TYPES = {"application/pdf", "image/jpeg", "image/png"}


@app.post("/upload-report")
async def upload_report(file: UploadFile = File(...)) -> dict[str, str]:
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=415, detail="Only PDF, JPG, and PNG files are accepted.")
    data = await file.read(MAX_REPORT_BYTES + 1)
    if len(data) > MAX_REPORT_BYTES:
        raise HTTPException(status_code=413, detail="File exceeds the 5 MB limit.")
    return {"message": f"Report '{file.filename}' received ({len(data) // 1024} KB). Analysis coming soon."}


# ── Content Hub ───────────────────────────────────────────────────────────────

@app.get("/content/articles", response_model=list[ArticleSummary])
def content_articles(category: str | None = None, tag: str | None = None) -> list[ArticleSummary]:
    return [ArticleSummary(**{k: v for k, v in a.items() if k not in ("content", "references")})
            for a in get_articles(category, tag)]


@app.get("/content/articles/{article_id}", response_model=ArticleDetail)
def content_article_detail(article_id: str) -> ArticleDetail:
    article = get_article_by_id(article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    return ArticleDetail(**article)


@app.get("/content/videos", response_model=list[VideoItem])
def content_videos(category: str | None = None, tag: str | None = None) -> list[VideoItem]:
    return [VideoItem(**v) for v in get_videos(category, tag)]


@app.get("/content/search", response_model=ContentSearchResponse)
def content_search(q: str = Query(min_length=2)) -> ContentSearchResponse:
    result = search_content(q)
    return ContentSearchResponse(
        articles=[ArticleSummary(**{k: v for k, v in a.items() if k not in ("content", "references")})
                  for a in result["articles"]],
        videos=[VideoItem(**v) for v in result["videos"]],
        total=result["total"],
    )


@app.get("/content/categories")
def content_categories() -> list[str]:
    return CATEGORIES


# ── Community Forum ───────────────────────────────────────────────────────────

@app.get("/forum/posts", response_model=list[ForumPost])
def forum_list(category: str | None = None, limit: int = 50) -> list[ForumPost]:
    return [ForumPost(**p) for p in get_forum_posts(category, min(limit, 100))]


@app.post("/forum/posts", response_model=ForumPost)
def forum_create(payload: ForumPostCreate, user_id: int = Depends(get_current_user_id)) -> ForumPost:
    post_id = create_forum_post(user_id, payload.title, payload.body, payload.category)
    return ForumPost(id=post_id, user_id=user_id, username=get_username(user_id),
                     title=payload.title, body=payload.body,
                     category=payload.category, created_at="now", reply_count=0)


@app.get("/forum/posts/{post_id}/replies", response_model=list[ForumReply])
def forum_replies(post_id: int) -> list[ForumReply]:
    return [ForumReply(**r) for r in get_forum_replies(post_id)]


@app.post("/forum/posts/{post_id}/replies", response_model=ForumReply)
def forum_reply(post_id: int, payload: ForumReplyCreate,
                user_id: int = Depends(get_current_user_id)) -> ForumReply:
    reply_id = create_forum_reply(post_id, user_id, payload.body)
    return ForumReply(id=reply_id, post_id=post_id, user_id=user_id,
                      username=get_username(user_id), body=payload.body, created_at="now")


# ── Gamification ──────────────────────────────────────────────────────────────

_BADGE_TIERS = [
    Badge(id="first_step",   name="First Step",    description="Submit your first recommendation", icon="🌱"),
    Badge(id="week_streak",  name="7-Day Streak",  description="Log activity 7 days in a row",     icon="🔥"),
    Badge(id="month_streak", name="30-Day Streak", description="Log activity 30 days in a row",    icon="🏆"),
    Badge(id="ten_logs",     name="Consistent",    description="Submit 10 recommendations",         icon="⭐"),
    Badge(id="fifty_logs",   name="Dedicated",     description="Submit 50 recommendations",         icon="💡"),
]


@app.get("/gamification", response_model=GamificationStatus)
def gamification(user_id: int = Depends(get_current_user_id)) -> GamificationStatus:
    streak = get_streak_days(user_id)
    total  = get_recommendation_count(user_id)
    earned: list[Badge] = []
    if total >= 1:   earned.append(_BADGE_TIERS[0])
    if streak >= 7:  earned.append(_BADGE_TIERS[1])
    if streak >= 30: earned.append(_BADGE_TIERS[2])
    if total >= 10:  earned.append(_BADGE_TIERS[3])
    if total >= 50:  earned.append(_BADGE_TIERS[4])
    earned_ids = {b.id for b in earned}
    next_b = next((b for b in _BADGE_TIERS if b.id not in earned_ids), None)
    return GamificationStatus(streak_days=streak, total_recommendations=total,
                               badges=earned, next_badge=next_b)


# ── Profile / Health Goals ────────────────────────────────────────────────────

@app.get("/profile", response_model=UserProfile)
def get_profile(user_id: int = Depends(get_current_user_id)) -> UserProfile:
    goals_raw = get_user_goals(user_id)
    return UserProfile(
        username=get_username(user_id),
        health_goals=HealthGoals(**goals_raw) if goals_raw else HealthGoals(),
        streak_days=get_streak_days(user_id),
        total_recommendations=get_recommendation_count(user_id),
    )


@app.put("/profile/goals", response_model=HealthGoals)
def update_goals(payload: HealthGoals, user_id: int = Depends(get_current_user_id)) -> HealthGoals:
    save_user_goals(user_id, payload.model_dump(exclude_none=True))
    return payload


# ── Provider Locator ──────────────────────────────────────────────────────────

_PROVIDERS = [
    {"name": "Jan Aushadhi Kendra",        "type": "pharmacy", "lat": 28.6139, "lon": 77.2090,
     "address": "Connaught Place, New Delhi",  "phone": None,              "low_cost": True},
    {"name": "ESI Hospital",               "type": "hospital", "lat": 28.6271, "lon": 77.2182,
     "address": "Patel Nagar, New Delhi",       "phone": "+91-11-25787",    "low_cost": True},
    {"name": "SRL Diagnostics",            "type": "lab",      "lat": 28.5355, "lon": 77.3910,
     "address": "Noida Sector 18",              "phone": "+91-120-4343434", "low_cost": False},
    {"name": "Thyrocare Collection Centre","type": "lab",      "lat": 19.0760, "lon": 72.8777,
     "address": "Andheri, Mumbai",              "phone": "+91-22-30006666", "low_cost": True},
    {"name": "PHC Urban Health Centre",    "type": "clinic",   "lat": 12.9716, "lon": 77.5946,
     "address": "Jayanagar, Bengaluru",         "phone": None,              "low_cost": True},
    {"name": "Lal PathLabs",               "type": "lab",      "lat": 22.5726, "lon": 88.3639,
     "address": "Park Street, Kolkata",         "phone": "+91-33-40444444", "low_cost": False},
]


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    dlat, dlon = math.radians(lat2 - lat1), math.radians(lon2 - lon1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


@app.post("/providers/search", response_model=list[ProviderResult])
def providers_search(payload: ProviderSearchRequest) -> list[ProviderResult]:
    results = []
    for p in _PROVIDERS:
        if p["type"] != payload.type:
            continue
        dist = _haversine(payload.latitude, payload.longitude, p["lat"], p["lon"])
        if dist <= payload.radius_km:
            results.append(ProviderResult(
                name=p["name"], type=p["type"], address=p["address"],
                distance_km=round(dist, 2), phone=p["phone"], low_cost=p["low_cost"],
                maps_url=f"https://www.google.com/maps/search/?api=1&query={p['lat']},{p['lon']}",
            ))
    results.sort(key=lambda r: r.distance_km)
    return results


# ── Edge Computing Notifications ──────────────────────────────────────────────

@app.post("/edge/notify", response_model=EdgeNotificationResponse)
def edge_notify(payload: EdgeNotificationRequest) -> EdgeNotificationResponse:
    b, ls = payload.biomarkers, payload.lifestyle
    notifications: list[EdgeNotification] = []

    if b.vitamin_d_ng_ml < 12:
        notifications.append(EdgeNotification(severity="critical", title="Critically Low Vitamin D",
            message=f"Vitamin D is {b.vitamin_d_ng_ml} ng/mL — severe deficiency.",
            action="Seek medical attention and start supplementation immediately."))
    elif b.vitamin_d_ng_ml < 20:
        notifications.append(EdgeNotification(severity="warning", title="Low Vitamin D",
            message=f"Vitamin D is {b.vitamin_d_ng_ml} ng/mL.",
            action="Increase sun exposure and consider D3 supplement."))

    if b.vitamin_b12_pg_ml < 150:
        notifications.append(EdgeNotification(severity="critical", title="Critically Low B12",
            message=f"B12 is {b.vitamin_b12_pg_ml} pg/mL — nerve damage risk.",
            action="Consult a doctor for B12 injection or high-dose supplement."))
    elif b.vitamin_b12_pg_ml < 300:
        notifications.append(EdgeNotification(severity="warning", title="Low Vitamin B12",
            message=f"B12 is {b.vitamin_b12_pg_ml} pg/mL.",
            action="Add B12-rich foods or supplement (methylcobalamin)."))

    if b.iron_ferritin_ng_ml < 12:
        notifications.append(EdgeNotification(severity="critical", title="Critically Low Iron",
            message=f"Ferritin is {b.iron_ferritin_ng_ml} ng/mL.",
            action="See a doctor — IV iron or prescription supplements may be needed."))

    if b.ldl_mg_dl > 190:
        notifications.append(EdgeNotification(severity="critical", title="Very High LDL",
            message=f"LDL is {b.ldl_mg_dl} mg/dL — high cardiovascular risk.",
            action="Consult a cardiologist. Medication may be required."))

    if ls.avg_sleep_hours < 5:
        notifications.append(EdgeNotification(severity="warning", title="Severe Sleep Deprivation",
            message=f"Averaging {ls.avg_sleep_hours}h sleep — metabolic risk elevated.",
            action="Prioritize 7–9 hours of sleep. Avoid screens before bed."))

    if ls.avg_daily_steps < 2000:
        notifications.append(EdgeNotification(severity="info", title="Very Low Activity",
            message=f"Only {ls.avg_daily_steps} steps/day detected.",
            action="Aim for at least 7,000 steps daily for cardiovascular health."))

    return EdgeNotificationResponse(device_id=payload.device_id,
                                     notifications=notifications, processed_locally=True)


# ── PDF Report Export ─────────────────────────────────────────────────────────

@app.get("/report/pdf")
def export_pdf(limit: int = 5, user_id: int = Depends(get_current_user_id)) -> StreamingResponse:
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import cm
    from reportlab.lib import colors
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable

    recs = get_history(user_id, min(limit, 20))
    username = get_username(user_id)
    buf = io.BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4, leftMargin=2*cm, rightMargin=2*cm,
                            topMargin=2*cm, bottomMargin=2*cm)
    styles = getSampleStyleSheet()
    h1 = ParagraphStyle("h1", parent=styles["Heading1"], textColor=colors.HexColor("#1B5E20"), fontSize=18)
    h2 = ParagraphStyle("h2", parent=styles["Heading2"], textColor=colors.HexColor("#2E7D32"), fontSize=13)
    body = styles["BodyText"]
    story = [
        Paragraph("VitaPulse Health Report", h1),
        Paragraph(f"User: {username}", body),
        Spacer(1, 0.4*cm),
        HRFlowable(width="100%", color=colors.HexColor("#A5D6A7")),
        Spacer(1, 0.4*cm),
    ]
    if not recs:
        story.append(Paragraph("No recommendation history found.", body))
    for rec in recs:
        story.append(Paragraph(f"Recommendation #{rec.id} — {rec.created_at[:16]}", h2))
        r = rec.recommendation
        if r.risk_summary:
            story.append(Paragraph("Risk Summary:", styles["Heading3"]))
            for risk in r.risk_summary:
                story.append(Paragraph(f"• {risk}", body))
        if r.nutrient_status:
            story.append(Paragraph("Nutrient Status:", styles["Heading3"]))
            tdata = [["Nutrient", "Level", "Value", "Target"]]
            for ns in r.nutrient_status:
                tdata.append([ns.nutrient, ns.level, str(ns.current_value), str(ns.min_target)])
            t = Table(tdata, colWidths=[5*cm, 3*cm, 3*cm, 3*cm])
            t.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#C8E6C9")),
                ("FONTNAME",   (0, 0), (-1, 0), "Helvetica-Bold"),
                ("GRID",       (0, 0), (-1, -1), 0.5, colors.HexColor("#E0E0E0")),
                ("FONTSIZE",   (0, 0), (-1, -1), 9),
            ]))
            story.append(t)
        if r.lifestyle_actions:
            story.append(Paragraph("Lifestyle Actions:", styles["Heading3"]))
            for action in r.lifestyle_actions:
                story.append(Paragraph(f"• {action}", body))
        story.append(Spacer(1, 0.5*cm))
        story.append(HRFlowable(width="100%", color=colors.HexColor("#E0E0E0")))
        story.append(Spacer(1, 0.3*cm))

    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph(
        "Disclaimer: This report is generated by a rule-based prototype. "
        "It is not a medical diagnosis. Please consult a qualified healthcare professional.",
        ParagraphStyle("disc", parent=body, textColor=colors.grey, fontSize=8),
    ))
    doc.build(story)
    buf.seek(0)
    return StreamingResponse(buf, media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="vitapulse_report_{username}.pdf"'})
