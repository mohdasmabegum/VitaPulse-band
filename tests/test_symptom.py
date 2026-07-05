from fastapi.testclient import TestClient

from app.main import app
from app.symptom_engine import assess_symptoms, build_insights

client = TestClient(app)


def test_assess_symptoms_returns_scores():
    scores = assess_symptoms(["fatigue", "tingling", "pale skin"])
    assert "Iron" in scores
    assert "Vitamin B12" in scores
    assert all(0 <= v <= 1 for v in scores.values())


def test_build_insights_filters_threshold():
    scores = {"Vitamin D": 0.1, "Iron": 0.8}
    insights = build_insights(scores, threshold=0.3)
    assert len(insights) == 1
    assert insights[0]["deficiency"] == "Iron"


def test_symptom_check_endpoint_basic():
    response = client.post("/symptom-check", json={"symptoms": ["fatigue", "bone pain"]})
    assert response.status_code == 200
    data = response.json()
    assert "insights" in data
    assert "follow_up_questions" in data
    assert "disclaimer" in data
    assert any(i["deficiency"] == "Vitamin D" for i in data["insights"])


def test_symptom_check_with_follow_up_boosts_score():
    base = client.post("/symptom-check", json={"symptoms": ["fatigue"]}).json()
    boosted = client.post(
        "/symptom-check",
        json={
            "symptoms": ["fatigue"],
            "follow_up_answers": {"Are you vegetarian or vegan?": True},
        },
    ).json()
    base_b12 = next((i["confidence"] for i in base["insights"] if i["deficiency"] == "Vitamin B12"), 0)
    boosted_b12 = next((i["confidence"] for i in boosted["insights"] if i["deficiency"] == "Vitamin B12"), 0)
    assert boosted_b12 >= base_b12


def test_symptom_check_no_symptoms_fails():
    response = client.post("/symptom-check", json={"symptoms": []})
    assert response.status_code == 422
