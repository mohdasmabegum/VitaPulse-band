from __future__ import annotations

import math
from typing import Any


# ── Reference ranges ──────────────────────────────────────────────────────────
RANGES: dict[str, dict[str, float]] = {
    "vitamin_d_ng_ml":      {"critical_low": 10, "low": 20, "borderline": 30, "optimal": 60},
    "vitamin_b12_pg_ml":    {"critical_low": 100, "low": 200, "borderline": 300, "optimal": 900},
    "iron_ferritin_ng_ml":  {"critical_low": 10, "low": 30, "borderline": 60, "optimal": 150},
    "ldl_mg_dl":            {"optimal": 100, "borderline": 130, "high": 160, "critical_high": 190},
    "hdl_mg_dl":            {"critical_low": 30, "low": 40, "borderline": 50, "optimal": 60},
    "triglycerides_mg_dl":  {"optimal": 100, "borderline": 150, "high": 200, "critical_high": 500},
    "body_fat_percent":     {"low": 10, "optimal": 25, "borderline": 30, "high": 35},
    "avg_daily_steps":      {"critical_low": 2000, "low": 5000, "borderline": 7500, "optimal": 10000},
    "avg_sleep_hours":      {"critical_low": 4, "low": 6, "borderline": 7, "optimal": 8},
    "weekly_workouts":      {"critical_low": 0, "low": 1, "borderline": 2, "optimal": 4},
}

# ── Risk weights per marker ───────────────────────────────────────────────────
RISK_WEIGHTS: dict[str, float] = {
    "vitamin_d_ng_ml":     0.12,
    "vitamin_b12_pg_ml":   0.12,
    "iron_ferritin_ng_ml": 0.10,
    "ldl_mg_dl":           0.15,
    "hdl_mg_dl":           0.10,
    "triglycerides_mg_dl": 0.12,
    "body_fat_percent":    0.10,
    "avg_daily_steps":     0.08,
    "avg_sleep_hours":     0.06,
    "weekly_workouts":     0.05,
}

# ── Preventative action map ───────────────────────────────────────────────────
PREVENTATIVE_ACTIONS: dict[str, list[str]] = {
    "vitamin_d_ng_ml": [
        "Get 20–30 min of morning sunlight daily.",
        "Add fortified milk, eggs, or fatty fish to your diet.",
        "Consider Vitamin D3 supplement (consult doctor for dosage).",
    ],
    "vitamin_b12_pg_ml": [
        "Include eggs, dairy, or B12-fortified foods daily.",
        "If vegetarian/vegan, a B12 supplement is strongly recommended.",
        "Retest B12 levels in 8 weeks after dietary changes.",
    ],
    "iron_ferritin_ng_ml": [
        "Eat iron-rich foods (lentils, spinach, lean meat) with Vitamin C.",
        "Avoid tea/coffee within 1 hour of iron-rich meals.",
        "Check for underlying causes if ferritin stays critically low.",
    ],
    "ldl_mg_dl": [
        "Replace saturated fats with olive oil, nuts, and avocado.",
        "Eat oats, barley, and legumes daily for soluble fiber.",
        "Reduce processed and fried foods significantly.",
    ],
    "hdl_mg_dl": [
        "Increase aerobic exercise (brisk walk, cycling) 5x/week.",
        "Add healthy fats: walnuts, almonds, olive oil.",
        "Quit smoking if applicable — it directly lowers HDL.",
    ],
    "triglycerides_mg_dl": [
        "Cut sugar, refined carbs, and alcohol intake.",
        "Eat omega-3 rich foods: flaxseed, walnuts, fatty fish.",
        "Maintain a caloric deficit if overweight.",
    ],
    "body_fat_percent": [
        "Aim for a 300–500 kcal daily deficit through diet and exercise.",
        "Prioritize protein at every meal to preserve muscle.",
        "Track weekly weight trends rather than daily fluctuations.",
    ],
    "avg_daily_steps": [
        "Set a reminder to walk 10 min after each meal.",
        "Take stairs instead of elevators whenever possible.",
        "Target 500 more steps per day each week until you reach 8000.",
    ],
    "avg_sleep_hours": [
        "Set a consistent sleep and wake time, even on weekends.",
        "Avoid screens 1 hour before bed.",
        "Keep bedroom cool (18–20°C) and dark for better sleep quality.",
    ],
    "weekly_workouts": [
        "Start with 2 sessions/week of 30-min moderate exercise.",
        "Mix strength training and cardio for best metabolic outcomes.",
        "Schedule workouts like appointments — block time in your calendar.",
    ],
}


def _z_score(value: float, mean: float, std: float) -> float:
    """Simple z-score for anomaly detection."""
    if std == 0:
        return 0.0
    return (value - mean) / std


def _linear_trend(values: list[float]) -> float:
    """Returns slope of best-fit line (positive = improving/worsening depending on marker)."""
    n = len(values)
    if n < 2:
        return 0.0
    x_mean = (n - 1) / 2
    y_mean = sum(values) / n
    numerator = sum((i - x_mean) * (v - y_mean) for i, v in enumerate(values))
    denominator = sum((i - x_mean) ** 2 for i in range(n))
    return numerator / denominator if denominator else 0.0


def _marker_risk_score(marker: str, value: float) -> float:
    """Returns 0.0 (optimal) to 1.0 (critical) risk score for a single marker."""
    r = RANGES.get(marker, {})
    if not r:
        return 0.0

    # Markers where lower is worse
    if marker in ("vitamin_d_ng_ml", "vitamin_b12_pg_ml", "iron_ferritin_ng_ml",
                  "hdl_mg_dl", "avg_daily_steps", "avg_sleep_hours", "weekly_workouts"):
        if value <= r.get("critical_low", 0):
            return 1.0
        if value <= r.get("low", 0):
            return 0.75
        if value <= r.get("borderline", 0):
            return 0.4
        return 0.0

    # Markers where higher is worse
    if marker in ("ldl_mg_dl", "triglycerides_mg_dl", "body_fat_percent"):
        if value >= r.get("critical_high", r.get("high", float("inf"))):
            return 1.0
        if value >= r.get("high", float("inf")):
            return 0.75
        if value >= r.get("borderline", float("inf")):
            return 0.4
        return 0.0

    return 0.0


def compute_overall_risk(biomarkers: dict[str, float], lifestyle: dict[str, float]) -> dict[str, Any]:
    """
    Weighted risk score across all markers.
    Returns overall_score (0–100), risk_level, and per-marker breakdown.
    """
    all_markers = {**biomarkers, **lifestyle}
    total_weight = 0.0
    weighted_score = 0.0
    breakdown: list[dict] = []

    for marker, value in all_markers.items():
        weight = RISK_WEIGHTS.get(marker, 0.0)
        risk = _marker_risk_score(marker, value)
        weighted_score += risk * weight
        total_weight += weight
        if risk > 0:
            breakdown.append({
                "marker": marker,
                "value": value,
                "risk_score": round(risk, 2),
                "weight": weight,
            })

    overall = round((weighted_score / total_weight) * 100, 1) if total_weight else 0.0
    breakdown.sort(key=lambda x: x["risk_score"] * x["weight"], reverse=True)

    if overall >= 60:
        risk_level = "high"
    elif overall >= 35:
        risk_level = "moderate"
    else:
        risk_level = "low"

    return {
        "overall_score": overall,
        "risk_level": risk_level,
        "breakdown": breakdown[:5],  # top 5 contributors
    }


def detect_anomalies(history: list[dict[str, float]]) -> list[dict]:
    """
    Detect anomalies across a time series of biomarker snapshots.
    Uses z-score: |z| > 2 = anomaly.
    """
    if len(history) < 3:
        return []

    anomalies: list[dict] = []
    markers = history[0].keys()

    for marker in markers:
        values = [snap[marker] for snap in history if marker in snap]
        if len(values) < 3:
            continue
        mean = sum(values) / len(values)
        std = math.sqrt(sum((v - mean) ** 2 for v in values) / len(values))
        latest = values[-1]
        z = _z_score(latest, mean, std)
        if abs(z) >= 2.0:
            anomalies.append({
                "marker": marker,
                "latest_value": latest,
                "mean": round(mean, 2),
                "z_score": round(z, 2),
                "direction": "high" if z > 0 else "low",
                "message": f"{marker.replace('_', ' ').title()} is unusually {'high' if z > 0 else 'low'} compared to your history.",
            })

    return anomalies


def detect_trends(history: list[dict[str, float]]) -> list[dict]:
    """
    Detect improving or worsening trends using linear regression slope.
    """
    if len(history) < 3:
        return []

    trends: list[dict] = []
    markers = history[0].keys()

    # Markers where increasing is bad
    higher_is_worse = {"ldl_mg_dl", "triglycerides_mg_dl", "body_fat_percent"}

    for marker in markers:
        values = [snap[marker] for snap in history if marker in snap]
        if len(values) < 3:
            continue
        slope = _linear_trend(values)
        pct_change = (slope / (values[0] + 1e-9)) * 100

        if abs(pct_change) < 2:
            continue  # ignore negligible trends

        worsening = (marker in higher_is_worse and slope > 0) or \
                    (marker not in higher_is_worse and slope < 0)

        trends.append({
            "marker": marker,
            "slope": round(slope, 3),
            "pct_change_per_period": round(pct_change, 1),
            "direction": "worsening" if worsening else "improving",
            "message": (
                f"{marker.replace('_', ' ').title()} is {'worsening' if worsening else 'improving'} "
                f"({'+' if slope > 0 else ''}{round(pct_change, 1)}% per period)."
            ),
        })

    trends.sort(key=lambda x: abs(x["pct_change_per_period"]), reverse=True)
    return trends


def generate_ml_insights(
    biomarkers: dict[str, float],
    lifestyle: dict[str, float],
    history: list[dict[str, float]] | None = None,
) -> dict[str, Any]:
    """
    Main ML insight function. Combines risk scoring, anomaly detection,
    trend analysis, and preventative action recommendations.
    """
    risk = compute_overall_risk(biomarkers, lifestyle)
    anomalies = detect_anomalies(history or [])
    trends = detect_trends(history or [])

    # Collect top markers needing action
    flagged_markers: set[str] = set()
    for item in risk["breakdown"]:
        flagged_markers.add(item["marker"])
    for a in anomalies:
        flagged_markers.add(a["marker"])
    for t in trends:
        if t["direction"] == "worsening":
            flagged_markers.add(t["marker"])

    # Build personalized preventative actions
    actions: list[dict] = []
    for marker in flagged_markers:
        if marker in PREVENTATIVE_ACTIONS:
            actions.append({
                "marker": marker,
                "actions": PREVENTATIVE_ACTIONS[marker],
            })

    return {
        "risk_assessment": risk,
        "anomalies": anomalies,
        "trends": trends,
        "preventative_actions": actions,
        "summary": _build_summary(risk, anomalies, trends),
    }


def _build_summary(risk: dict, anomalies: list, trends: list) -> str:
    parts = [f"Overall health risk is {risk['risk_level'].upper()} (score: {risk['overall_score']}/100)."]
    if anomalies:
        parts.append(f"{len(anomalies)} anomaly(ies) detected in recent biomarkers.")
    worsening = [t for t in trends if t["direction"] == "worsening"]
    if worsening:
        parts.append(f"{len(worsening)} marker(s) showing a worsening trend.")
    improving = [t for t in trends if t["direction"] == "improving"]
    if improving:
        parts.append(f"{len(improving)} marker(s) showing improvement — keep it up!")
    return " ".join(parts)
