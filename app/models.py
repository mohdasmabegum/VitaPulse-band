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
