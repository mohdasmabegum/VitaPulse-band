from __future__ import annotations

from app.food_db import CHOLESTEROL_HELPERS, CHOLESTEROL_LIMIT, FAT_LOSS_BASE, VITAMIN_FOODS
from app.models import DailyPlan, FoodSuggestion, NutrientStatus, RecommendationResponse, UserInput


def _level(value: float, low_cutoff: float, border_cutoff: float) -> str:
    if value < low_cutoff:
        return "low"
    if value < border_cutoff:
        return "borderline"
    return "normal"


def _filter_allergic_items(items: list[str], allergies: list[str]) -> list[str]:
    allergy_terms = [item.strip().lower() for item in allergies if item.strip()]
    if not allergy_terms:
        return items

    filtered: list[str] = []
    for candidate in items:
        normalized = candidate.lower()
        if any(term in normalized for term in allergy_terms):
            continue
        filtered.append(candidate)
    return filtered


def build_recommendation(user: UserInput) -> RecommendationResponse:
    diet_key = "vegetarian" if user.diet_type == "vegetarian" else "omnivore"

    d_level = _level(user.biomarkers.vitamin_d_ng_ml, low_cutoff=20, border_cutoff=30)
    b12_level = _level(user.biomarkers.vitamin_b12_pg_ml, low_cutoff=200, border_cutoff=300)
    iron_level = _level(user.biomarkers.iron_ferritin_ng_ml, low_cutoff=30, border_cutoff=60)

    ldl_high = user.biomarkers.ldl_mg_dl >= 130
    hdl_low = user.biomarkers.hdl_mg_dl < 40
    tg_high = user.biomarkers.triglycerides_mg_dl >= 150

    high_body_fat = user.body_metrics.body_fat_percent > 30

    nutrient_status = [
        NutrientStatus(
            nutrient="Vitamin D",
            level=d_level,
            current_value=user.biomarkers.vitamin_d_ng_ml,
            min_target=30,
            note="Aim for safe sunlight and fortified foods.",
        ),
        NutrientStatus(
            nutrient="Vitamin B12",
            level=b12_level,
            current_value=user.biomarkers.vitamin_b12_pg_ml,
            min_target=300,
            note="Prioritize B12-rich foods from your diet type.",
        ),
        NutrientStatus(
            nutrient="Iron/Ferritin",
            level=iron_level,
            current_value=user.biomarkers.iron_ferritin_ng_ml,
            min_target=60,
            note="Pair iron foods with vitamin C sources for absorption.",
        ),
    ]

    risk_summary = []
    if d_level != "normal":
        risk_summary.append("Vitamin D is below desired range.")
    if b12_level != "normal":
        risk_summary.append("Vitamin B12 is below desired range.")
    if iron_level != "normal":
        risk_summary.append("Iron/ferritin is below desired range.")
    if ldl_high or hdl_low or tg_high:
        risk_summary.append("Lipid profile indicates cardiovascular risk.")
    if high_body_fat:
        risk_summary.append("Body fat is above recommended range.")

    food_suggestions = []
    if d_level != "normal":
        food_suggestions.append(
            FoodSuggestion(
                purpose="Improve Vitamin D",
                foods=_filter_allergic_items(VITAMIN_FOODS["vitamin_d"][diet_key], user.allergies),
            )
        )
    if b12_level != "normal":
        food_suggestions.append(
            FoodSuggestion(
                purpose="Improve Vitamin B12",
                foods=_filter_allergic_items(VITAMIN_FOODS["vitamin_b12"][diet_key], user.allergies),
            )
        )
    if iron_level != "normal":
        food_suggestions.append(
            FoodSuggestion(
                purpose="Improve Iron/Ferritin",
                foods=_filter_allergic_items(VITAMIN_FOODS["iron"][diet_key], user.allergies),
            )
        )
    if ldl_high or hdl_low or tg_high:
        food_suggestions.append(
            FoodSuggestion(
                purpose="Reduce LDL and triglycerides",
                foods=_filter_allergic_items(CHOLESTEROL_HELPERS, user.allergies),
                avoid_or_limit=_filter_allergic_items(CHOLESTEROL_LIMIT, user.allergies),
            )
        )
    if high_body_fat:
        food_suggestions.append(
            FoodSuggestion(
                purpose="Reduce body fat with basic foods",
                foods=_filter_allergic_items(FAT_LOSS_BASE, user.allergies),
                avoid_or_limit=_filter_allergic_items(
                    ["sugary drinks", "late-night snacking", "highly processed snacks"], user.allergies
                ),
            )
        )

    breakfast = ["oats with milk and nuts", "1 fruit"]
    lunch = ["dal or lean protein", "2 cups mixed vegetables", "small portion brown rice"]
    dinner = ["grilled protein or paneer", "salad", "soup"]
    snacks = ["curd/greek yogurt", "roasted chickpeas"]

    if user.diet_type == "vegetarian":
        lunch[0] = "dal or rajma/chole"
        dinner[0] = "paneer or tofu"

    breakfast = _filter_allergic_items(breakfast, user.allergies)
    lunch = _filter_allergic_items(lunch, user.allergies)
    dinner = _filter_allergic_items(dinner, user.allergies)
    snacks = _filter_allergic_items(snacks, user.allergies)

    lifestyle_actions = [
        "Walk at least 8000 steps/day.",
        "Perform strength training 2-3 times/week.",
        "Sleep 7-8 hours daily to support fat loss and lipid balance.",
        "Retest vitamin and lipid biomarkers every 8-12 weeks.",
    ]

    return RecommendationResponse(
        risk_summary=risk_summary or ["No major nutrition risk flags from provided values."],
        nutrient_status=nutrient_status,
        food_suggestions=food_suggestions,
        daily_plan=DailyPlan(
            breakfast=breakfast,
            lunch=lunch,
            dinner=dinner,
            snacks=snacks,
        ),
        lifestyle_actions=lifestyle_actions,
        disclaimer="This tool provides wellness guidance and is not a medical diagnosis. Consult a doctor for treatment decisions.",
    )
