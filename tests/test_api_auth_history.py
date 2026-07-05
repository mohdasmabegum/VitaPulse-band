from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def _unique_user() -> tuple[str, str]:
    import uuid

    suffix = uuid.uuid4().hex[:8]
    return f"user_{suffix}", "pass1234"


def test_register_login_and_history_flow() -> None:
    username, password = _unique_user()

    register_response = client.post(
        "/auth/register",
        json={"username": username, "password": password},
    )
    assert register_response.status_code == 200
    token = register_response.json()["token"]

    payload = {
        "age": 31,
        "sex": "female",
        "diet_type": "vegetarian",
        "allergies": ["milk"],
        "biomarkers": {
            "vitamin_d_ng_ml": 17,
            "vitamin_b12_pg_ml": 250,
            "iron_ferritin_ng_ml": 28,
            "ldl_mg_dl": 140,
            "hdl_mg_dl": 39,
            "triglycerides_mg_dl": 180,
        },
        "body_metrics": {
            "height_cm": 162,
            "weight_kg": 70,
            "body_fat_percent": 33,
        },
        "lifestyle": {
            "avg_daily_steps": 5000,
            "avg_sleep_hours": 6.5,
            "weekly_workouts": 2,
        },
    }

    save_response = client.post(
        "/recommend/save",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert save_response.status_code == 200

    history_response = client.get("/history", headers={"Authorization": f"Bearer {token}"})
    assert history_response.status_code == 200
    history_items = history_response.json()
    assert len(history_items) >= 1
    assert "recommendation" in history_items[0]


def test_history_requires_token() -> None:
    response = client.get("/history")
    assert response.status_code == 401
