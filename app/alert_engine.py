from __future__ import annotations

from typing import Any

from app.ml_engine import RANGES, _marker_risk_score, detect_anomalies, detect_trends

# ── Alert severity levels ─────────────────────────────────────────────────────
CRITICAL = "critical"
WARNING  = "warning"
INFO     = "info"
POSITIVE = "positive"

# ── Goal thresholds (defaults if user doesn't set goals) ─────────────────────
DEFAULT_GOALS: dict[str, float] = {
    "vitamin_d_ng_ml":     30.0,
    "vitamin_b12_pg_ml":   300.0,
    "iron_ferritin_ng_ml": 60.0,
    "ldl_mg_dl":           100.0,
    "hdl_mg_dl":           60.0,
    "triglycerides_mg_dl": 100.0,
    "body_fat_percent":    25.0,
    "avg_daily_steps":     10000,
    "avg_sleep_hours":     8.0,
    "weekly_workouts":     4,
}

# ── Human-readable marker names ───────────────────────────────────────────────
MARKER_LABELS: dict[str, str] = {
    "vitamin_d_ng_ml":     "Vitamin D",
    "vitamin_b12_pg_ml":   "Vitamin B12",
    "iron_ferritin_ng_ml": "Iron/Ferritin",
    "ldl_mg_dl":           "LDL Cholesterol",
    "hdl_mg_dl":           "HDL Cholesterol",
    "triglycerides_mg_dl": "Triglycerides",
    "body_fat_percent":    "Body Fat %",
    "avg_daily_steps":     "Daily Steps",
    "avg_sleep_hours":     "Sleep Hours",
    "weekly_workouts":     "Weekly Workouts",
}

# Markers where lower is worse (goal = minimum target)
LOWER_IS_WORSE = {
    "vitamin_d_ng_ml", "vitamin_b12_pg_ml", "iron_ferritin_ng_ml",
    "hdl_mg_dl", "avg_daily_steps", "avg_sleep_hours", "weekly_workouts",
}


def _goal_alert(marker: str, value: float, goal: float) -> dict | None:
    label = MARKER_LABELS.get(marker, marker)
    risk = _marker_risk_score(marker, value)

    if marker in LOWER_IS_WORSE:
        if value < goal * 0.5:
            return {
                "type": "goal",
                "severity": CRITICAL,
                "marker": marker,
                "label": label,
                "value": value,
                "goal": goal,
                "message": f"🚨 {label} is critically below your goal ({value} vs target {goal}). Immediate action needed.",
                "action": f"Prioritize improving {label} — consult a healthcare provider if this persists.",
            }
        if value < goal * 0.75:
            return {
                "type": "goal",
                "severity": WARNING,
                "marker": marker,
                "label": label,
                "value": value,
                "goal": goal,
                "message": f"⚠️ {label} is below your goal ({value} vs target {goal}).",
                "action": f"Review your diet and lifestyle habits to improve {label}.",
            }
        if value >= goal:
            return {
                "type": "goal",
                "severity": POSITIVE,
                "marker": marker,
                "label": label,
                "value": value,
                "goal": goal,
                "message": f"✅ {label} has reached your goal ({value} ≥ {goal}). Great work!",
                "action": "Maintain your current habits.",
            }
    else:
        # Higher is worse
        if value > goal * 1.5:
            return {
                "type": "goal",
                "severity": CRITICAL,
                "marker": marker,
                "label": label,
                "value": value,
                "goal": goal,
                "message": f"🚨 {label} is critically above your goal ({value} vs target {goal}). Immediate action needed.",
                "action": f"Reduce {label} urgently — consult a healthcare provider.",
            }
        if value > goal * 1.2:
            return {
                "type": "goal",
                "severity": WARNING,
                "marker": marker,
                "label": label,
                "value": value,
                "goal": goal,
                "message": f"⚠️ {label} exceeds your goal ({value} vs target {goal}).",
                "action": f"Take steps to reduce {label} through diet and exercise.",
            }
        if value <= goal:
            return {
                "type": "goal",
                "severity": POSITIVE,
                "marker": marker,
                "label": label,
                "value": value,
                "goal": goal,
                "message": f"✅ {label} is within your goal ({value} ≤ {goal}). Keep it up!",
                "action": "Maintain your current habits.",
            }
    return None


def _engagement_alerts(lifestyle: dict[str, float]) -> list[dict]:
    """Nudge alerts to encourage consistent healthy behaviour."""
    alerts = []
    steps = lifestyle.get("avg_daily_steps", 0)
    sleep = lifestyle.get("avg_sleep_hours", 0)
    workouts = lifestyle.get("weekly_workouts", 0)

    if steps < 5000:
        alerts.append({
            "type": "engagement",
            "severity": WARNING,
            "marker": "avg_daily_steps",
            "label": "Daily Steps",
            "message": f"🚶 You're averaging only {int(steps)} steps/day. Try to reach 8,000 steps.",
            "action": "Add a 15-min walk after lunch and dinner to boost your step count.",
        })
    if sleep < 6:
        alerts.append({
            "type": "engagement",
            "severity": WARNING,
            "marker": "avg_sleep_hours",
            "label": "Sleep",
            "message": f"😴 You're sleeping only {sleep}h/night. Aim for 7–8 hours.",
            "action": "Set a fixed bedtime and avoid screens 1 hour before sleep.",
        })
    if workouts < 2:
        alerts.append({
            "type": "engagement",
            "severity": INFO,
            "marker": "weekly_workouts",
            "label": "Weekly Workouts",
            "message": f"🏋️ Only {int(workouts)} workout(s) this week. Try to hit at least 3.",
            "action": "Schedule 3 x 30-min sessions this week — even a brisk walk counts.",
        })
    return alerts


def _anomaly_alerts(anomalies: list[dict]) -> list[dict]:
    alerts = []
    for a in anomalies:
        label = MARKER_LABELS.get(a["marker"], a["marker"])
        severity = CRITICAL if abs(a["z_score"]) >= 3 else WARNING
        alerts.append({
            "type": "anomaly",
            "severity": severity,
            "marker": a["marker"],
            "label": label,
            "message": f"📊 Anomaly detected: {a['message']}",
            "action": f"Review recent changes in diet, medication, or lifestyle that may have affected {label}.",
        })
    return alerts


def _trend_alerts(trends: list[dict]) -> list[dict]:
    alerts = []
    for t in trends:
        label = MARKER_LABELS.get(t["marker"], t["marker"])
        if t["direction"] == "worsening":
            alerts.append({
                "type": "trend",
                "severity": WARNING,
                "marker": t["marker"],
                "label": label,
                "message": f"📉 {t['message']}",
                "action": f"Address the worsening trend in {label} before it becomes critical.",
            })
        elif t["direction"] == "improving":
            alerts.append({
                "type": "trend",
                "severity": POSITIVE,
                "marker": t["marker"],
                "label": label,
                "message": f"📈 {t['message']}",
                "action": "Keep up the good work — your efforts are paying off!",
            })
    return alerts


def generate_health_alerts(
    biomarkers: dict[str, float],
    lifestyle: dict[str, float],
    user_goals: dict[str, float] | None = None,
    history: list[dict[str, float]] | None = None,
) -> dict[str, Any]:
    """
    Generate all health alerts: goal-based, engagement nudges,
    anomaly alerts, and trend alerts.
    """
    goals = {**DEFAULT_GOALS, **(user_goals or {})}
    all_markers = {**biomarkers, **lifestyle}

    alerts: list[dict] = []

    # Goal-based alerts
    for marker, value in all_markers.items():
        if marker in goals:
            alert = _goal_alert(marker, value, goals[marker])
            if alert:
                alerts.append(alert)

    # Engagement nudges
    alerts.extend(_engagement_alerts(lifestyle))

    # Anomaly alerts from history
    if history and len(history) >= 3:
        anomalies = detect_anomalies(history)
        alerts.extend(_anomaly_alerts(anomalies))
        trends = detect_trends(history)
        alerts.extend(_trend_alerts(trends))

    # Sort: critical first, then warning, then info, then positive
    severity_order = {CRITICAL: 0, WARNING: 1, INFO: 2, POSITIVE: 3}
    alerts.sort(key=lambda a: severity_order.get(a["severity"], 4))

    # Deduplicate by marker (keep highest severity)
    seen: dict[str, dict] = {}
    for alert in alerts:
        m = alert["marker"]
        if m not in seen or severity_order[alert["severity"]] < severity_order[seen[m]["severity"]]:
            seen[m] = alert
    deduped = sorted(seen.values(), key=lambda a: severity_order.get(a["severity"], 4))

    critical_count = sum(1 for a in deduped if a["severity"] == CRITICAL)
    warning_count  = sum(1 for a in deduped if a["severity"] == WARNING)
    positive_count = sum(1 for a in deduped if a["severity"] == POSITIVE)

    return {
        "alerts": deduped,
        "summary": {
            "total": len(deduped),
            "critical": critical_count,
            "warnings": warning_count,
            "positive": positive_count,
        },
        "overall_status": (
            "critical" if critical_count > 0 else
            "warning"  if warning_count > 0  else
            "good"
        ),
    }
