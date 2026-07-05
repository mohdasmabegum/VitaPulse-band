from __future__ import annotations

from typing import List, Literal

from pydantic import BaseModel, Field, confloat


DeficiencyLevel = Literal["normal", "borderline", "low"]


class Biomarkers(BaseModel):
    vitamin_d_ng_ml: confloat(ge=0) = Field(..., description="25(OH)D level")
    vitamin_b12_pg_ml: confloat(ge=0)
    iron_ferritin_ng_ml: confloat(ge=0)
    ldl_mg_dl: confloat(ge=0)
    hdl_mg_dl: confloat(ge=0)
    triglycerides_mg_dl: confloat(ge=0)


class BodyMetrics(BaseModel):
    height_cm: confloat(gt=0)
    weight_kg: confloat(gt=0)
    body_fat_percent: confloat(ge=0, le=70)


class LifestyleSignals(BaseModel):
    avg_daily_steps: int = Field(ge=0)
    avg_sleep_hours: confloat(ge=0, le=24)
    weekly_workouts: int = Field(ge=0)


class UserInput(BaseModel):
    age: int = Field(ge=1, le=120)
    sex: Literal["male", "female", "other"]
    diet_type: Literal["omnivore", "vegetarian"] = "omnivore"
    allergies: List[str] = Field(default_factory=list)
    biomarkers: Biomarkers
    body_metrics: BodyMetrics
    lifestyle: LifestyleSignals


class NutrientStatus(BaseModel):
    nutrient: str
    level: DeficiencyLevel
    current_value: float
    min_target: float
    note: str


class FoodSuggestion(BaseModel):
    purpose: str
    foods: List[str]
    avoid_or_limit: List[str] = Field(default_factory=list)


class DailyPlan(BaseModel):
    breakfast: List[str]
    lunch: List[str]
    dinner: List[str]
    snacks: List[str]


class RecommendationResponse(BaseModel):
    risk_summary: List[str]
    nutrient_status: List[NutrientStatus]
    food_suggestions: List[FoodSuggestion]
    daily_plan: DailyPlan
    lifestyle_actions: List[str]
    disclaimer: str


class SymptomInput(BaseModel):
    symptoms: List[str] = Field(min_length=1, description="List of reported symptoms")
    follow_up_answers: dict[str, bool] = Field(
        default_factory=dict,
        description="Map of follow-up question text → True/False answer",
    )


class DeficiencyInsight(BaseModel):
    deficiency: str
    confidence: float = Field(ge=0, le=1)
    insight: str


class SymptomAssessmentResponse(BaseModel):
    insights: List[DeficiencyInsight]
    follow_up_questions: List[str]
    disclaimer: str


class AuthCredentials(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=6, max_length=128)


class AuthResponse(BaseModel):
    token: str
    username: str


class SavedRecommendation(BaseModel):
    id: int
    created_at: str
    payload: UserInput
    recommendation: RecommendationResponse


# ── ML Insight models ────────────────────────────────────────────────────────

class MLInsightRequest(BaseModel):
    biomarkers: Biomarkers
    lifestyle: LifestyleSignals
    history: List[dict] = Field(default_factory=list, description="List of past biomarker+lifestyle snapshots")


class RiskBreakdownItem(BaseModel):
    marker: str
    value: float
    risk_score: float
    weight: float


class RiskAssessment(BaseModel):
    overall_score: float
    risk_level: Literal["low", "moderate", "high"]
    breakdown: List[RiskBreakdownItem]


class AnomalyItem(BaseModel):
    marker: str
    latest_value: float
    mean: float
    z_score: float
    direction: str
    message: str


class TrendItem(BaseModel):
    marker: str
    slope: float
    pct_change_per_period: float
    direction: str
    message: str


class PreventativeAction(BaseModel):
    marker: str
    actions: List[str]


class MLInsightResponse(BaseModel):
    risk_assessment: RiskAssessment
    anomalies: List[AnomalyItem]
    trends: List[TrendItem]
    preventative_actions: List[PreventativeAction]
    summary: str


# ── Content Hub models ───────────────────────────────────────────────────────

class ArticleSummary(BaseModel):
    id: str
    title: str
    category: str
    tags: List[str]
    summary: str
    read_time_min: int
    video_url: str | None = None
    video_title: str | None = None


class ArticleDetail(ArticleSummary):
    content: str
    references: List[str] = Field(default_factory=list)


class VideoItem(BaseModel):
    id: str
    title: str
    category: str
    duration_min: int
    url: str
    thumbnail: str
    description: str
    tags: List[str]


class ContentSearchResponse(BaseModel):
    articles: List[ArticleSummary]
    videos: List[VideoItem]
    total: int


# ── Forum models ──────────────────────────────────────────────────────────────

class ForumPostCreate(BaseModel):
    title: str = Field(min_length=5, max_length=200)
    body: str = Field(min_length=10, max_length=2000)
    category: str = Field(default="general")


class ForumPost(BaseModel):
    id: int
    user_id: int
    username: str
    title: str
    body: str
    category: str
    created_at: str
    reply_count: int = 0


class ForumReplyCreate(BaseModel):
    body: str = Field(min_length=2, max_length=1000)


class ForumReply(BaseModel):
    id: int
    post_id: int
    user_id: int
    username: str
    body: str
    created_at: str


# ── Gamification models ───────────────────────────────────────────────────────

class Badge(BaseModel):
    id: str
    name: str
    description: str
    icon: str
    earned_at: str | None = None


class GamificationStatus(BaseModel):
    streak_days: int
    total_recommendations: int
    badges: List[Badge]
    next_badge: Badge | None = None


# ── Profile / Health Goals models ─────────────────────────────────────────────

class HealthGoals(BaseModel):
    goal_weight_kg: float | None = None
    goal_steps_per_day: int | None = None
    goal_sleep_hours: float | None = None
    goal_body_fat_percent: float | None = None
    focus_areas: List[str] = Field(default_factory=list,
        description="e.g. ['weight_loss','energy','cholesterol']")


class UserProfile(BaseModel):
    username: str
    health_goals: HealthGoals
    streak_days: int
    total_recommendations: int


# ── Provider Locator models ───────────────────────────────────────────────────

class ProviderSearchRequest(BaseModel):
    latitude: float
    longitude: float
    radius_km: float = Field(default=10.0, ge=1, le=100)
    type: Literal["lab", "clinic", "hospital", "pharmacy"] = "clinic"


class ProviderResult(BaseModel):
    name: str
    type: str
    address: str
    distance_km: float
    phone: str | None = None
    low_cost: bool
    maps_url: str


# ── Edge Notification models ──────────────────────────────────────────────────

class EdgeNotificationRequest(BaseModel):
    biomarkers: "Biomarkers"
    lifestyle: "LifestyleSignals"
    device_id: str = Field(default="unknown")


class EdgeNotification(BaseModel):
    severity: Literal["critical", "warning", "info"]
    title: str
    message: str
    action: str


class EdgeNotificationResponse(BaseModel):
    device_id: str
    notifications: List[EdgeNotification]
    processed_locally: bool = True


# ── Health Alert models ───────────────────────────────────────────────────────

class HealthAlertRequest(BaseModel):
    biomarkers: Biomarkers
    lifestyle: LifestyleSignals
    user_goals: dict[str, float] = Field(default_factory=dict, description="Optional user-defined goal values per marker")
    history: List[dict] = Field(default_factory=list)


class AlertItem(BaseModel):
    type: str
    severity: Literal["critical", "warning", "info", "positive"]
    marker: str
    label: str
    message: str
    action: str


class AlertSummary(BaseModel):
    total: int
    critical: int
    warnings: int
    positive: int


class HealthAlertResponse(BaseModel):
    alerts: List[AlertItem]
    summary: AlertSummary
    overall_status: Literal["critical", "warning", "good"]
