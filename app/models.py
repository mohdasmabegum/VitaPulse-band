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
