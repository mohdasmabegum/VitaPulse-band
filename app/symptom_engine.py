from __future__ import annotations

# Maps symptom keywords → (deficiency_label, confidence_weight)
SYMPTOM_MAP: dict[str, list[tuple[str, float]]] = {
    "fatigue":          [("Vitamin D", 0.6), ("Vitamin B12", 0.7), ("Iron", 0.8)],
    "weakness":         [("Vitamin D", 0.5), ("Iron", 0.7)],
    "pale skin":        [("Iron", 0.9), ("Vitamin B12", 0.6)],
    "brain fog":        [("Vitamin B12", 0.8), ("Vitamin D", 0.4)],
    "tingling":         [("Vitamin B12", 0.9)],
    "numbness":         [("Vitamin B12", 0.9)],
    "bone pain":        [("Vitamin D", 0.9)],
    "muscle cramps":    [("Vitamin D", 0.7)],
    "hair loss":        [("Iron", 0.7), ("Vitamin D", 0.4)],
    "shortness of breath": [("Iron", 0.8), ("Vitamin B12", 0.5)],
    "cold hands":       [("Iron", 0.7)],
    "mood swings":      [("Vitamin D", 0.6), ("Vitamin B12", 0.5)],
    "depression":       [("Vitamin D", 0.7), ("Vitamin B12", 0.6)],
    "poor concentration": [("Vitamin B12", 0.7), ("Iron", 0.5)],
    "frequent illness": [("Vitamin D", 0.7)],
    "slow healing":     [("Vitamin D", 0.5), ("Iron", 0.5)],
}

# Follow-up questions to refine confidence per deficiency
FOLLOW_UP_QUESTIONS: dict[str, list[str]] = {
    "Vitamin D": [
        "Do you get less than 30 minutes of sunlight daily?",
        "Do you live in a region with limited sunlight (e.g., northern latitudes or mostly indoors)?",
    ],
    "Vitamin B12": [
        "Are you vegetarian or vegan?",
        "Do you experience occasional memory lapses or difficulty concentrating?",
    ],
    "Iron": [
        "Do you have heavy menstrual periods (if applicable)?",
        "Do you follow a plant-based or low-meat diet?",
    ],
}

DEFICIENCY_INSIGHTS: dict[str, str] = {
    "Vitamin D": (
        "Low Vitamin D is common in people with limited sun exposure. "
        "It can cause fatigue, bone pain, and mood issues. "
        "Consider fortified foods, fatty fish, or a supplement after consulting your doctor."
    ),
    "Vitamin B12": (
        "Vitamin B12 deficiency is frequent in vegetarians/vegans and older adults. "
        "Symptoms include fatigue, tingling, and brain fog. "
        "Eggs, dairy, fortified cereals, or B12 supplements can help."
    ),
    "Iron": (
        "Iron deficiency is the most common nutritional deficiency worldwide. "
        "Symptoms include fatigue, pale skin, and shortness of breath. "
        "Increase intake of lentils, spinach, red meat (if non-veg), and pair with Vitamin C."
    ),
}


def _normalize(text: str) -> str:
    return text.strip().lower()


def assess_symptoms(symptoms: list[str]) -> dict[str, float]:
    """Return deficiency → cumulative confidence score (0–1 capped)."""
    scores: dict[str, float] = {}
    for symptom in symptoms:
        norm = _normalize(symptom)
        for key, mappings in SYMPTOM_MAP.items():
            if key in norm or norm in key:
                for deficiency, weight in mappings:
                    scores[deficiency] = min(1.0, scores.get(deficiency, 0.0) + weight)
    # Normalize to 0-1
    for k in scores:
        scores[k] = round(min(scores[k], 1.0), 2)
    return scores


def get_follow_up_questions(scores: dict[str, float], answered: dict[str, bool]) -> list[str]:
    """Return next unanswered follow-up questions for top-scoring deficiencies."""
    questions: list[str] = []
    for deficiency in sorted(scores, key=lambda d: scores[d], reverse=True):
        for q in FOLLOW_UP_QUESTIONS.get(deficiency, []):
            if q not in answered:
                questions.append(q)
                break  # one question per deficiency per turn
    return questions


def apply_follow_up_answers(scores: dict[str, float], answers: dict[str, bool]) -> dict[str, float]:
    """Boost scores based on affirmative follow-up answers."""
    updated = dict(scores)
    for deficiency, questions in FOLLOW_UP_QUESTIONS.items():
        for q in questions:
            if answers.get(q) is True:
                updated[deficiency] = round(min(1.0, updated.get(deficiency, 0.0) + 0.15), 2)
    return updated


def build_insights(scores: dict[str, float], threshold: float = 0.3) -> list[dict]:
    """Return sorted list of deficiency insights above threshold."""
    results = []
    for deficiency, score in sorted(scores.items(), key=lambda x: x[1], reverse=True):
        if score >= threshold:
            results.append({
                "deficiency": deficiency,
                "confidence": score,
                "insight": DEFICIENCY_INSIGHTS[deficiency],
            })
    return results
