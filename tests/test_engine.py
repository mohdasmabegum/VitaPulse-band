from app.engine import build_recommendation
from app.models import Biomarkers, BodyMetrics, LifestyleSignals, UserInput


def _sample_user() -> UserInput:
    return UserInput(
        age=35,
        sex="male",
        diet_type="omnivore",
        allergies=[],
        biomarkers=Biomarkers(
            vitamin_d_ng_ml=15,
            vitamin_b12_pg_ml=180,
            iron_ferritin_ng_ml=22,
            ldl_mg_dl=150,
            hdl_mg_dl=35,
            triglycerides_mg_dl=200,
        ),
        body_metrics=BodyMetrics(height_cm=175, weight_kg=86, body_fat_percent=32),
        lifestyle=LifestyleSignals(avg_daily_steps=3500, avg_sleep_hours=6.0, weekly_workouts=1),
    )


def test_recommendation_flags_risks() -> None:
    response = build_recommendation(_sample_user())
    assert any("Vitamin D" in x for x in response.risk_summary)
    assert any("Lipid profile" in x for x in response.risk_summary)
    assert any(s.purpose == "Reduce body fat with basic foods" for s in response.food_suggestions)


def test_recommendation_contains_daily_plan() -> None:
    response = build_recommendation(_sample_user())
    assert len(response.daily_plan.breakfast) > 0
    assert len(response.daily_plan.lunch) > 0
    assert len(response.daily_plan.dinner) > 0


def test_allergy_filtering_removes_matching_foods() -> None:
    user = _sample_user()
    user.allergies = ["milk"]
    response = build_recommendation(user)

    all_suggested_foods = []
    for suggestion in response.food_suggestions:
        all_suggested_foods.extend(suggestion.foods)

    assert not any("milk" in food.lower() for food in all_suggested_foods)
