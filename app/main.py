from __future__ import annotations

from pathlib import Path

from fastapi import Depends, FastAPI, Header, HTTPException, Request, UploadFile, File
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from app.db import create_session, get_history, get_user_id_by_token, init_db, register_user, save_recommendation, verify_user
from app.engine import build_recommendation
from app.models import AuthCredentials, AuthResponse, DeficiencyInsight, RecommendationResponse, SavedRecommendation, SymptomAssessmentResponse, SymptomInput, UserInput
from app.symptom_engine import apply_follow_up_answers, assess_symptoms, build_insights, get_follow_up_questions

APP_KEY = "vp-a8f3c2e1d4b7"

app = FastAPI(
    title="Diet Recommendation System",
    version="0.1.0",
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
)


@app.middleware("http")
async def require_app_key(request: Request, call_next):
    public = ("/", "/dashboard", "/auth/register", "/auth/login",
              "/recommend", "/recommend/save", "/history",
              "/symptom-check", "/upload-report")
    if request.url.path in public or request.url.path.startswith("/static"):
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
    safe_limit = max(1, min(limit, 100))
    return get_history(user_id=user_id, limit=safe_limit)


MAX_REPORT_BYTES = 5 * 1024 * 1024  # 5 MB
ALLOWED_TYPES = {"application/pdf", "image/jpeg", "image/png"}


@app.post("/upload-report")
async def upload_report(file: UploadFile = File(...)) -> dict[str, str]:
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=415, detail="Only PDF, JPG, and PNG files are accepted.")
    data = await file.read(MAX_REPORT_BYTES + 1)
    if len(data) > MAX_REPORT_BYTES:
        raise HTTPException(status_code=413, detail="File exceeds the 5 MB limit.")
    # Future: parse report and extract biomarkers
    return {"message": f"Report '{file.filename}' received ({len(data) // 1024} KB). Analysis coming soon."}
