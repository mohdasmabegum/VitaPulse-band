from __future__ import annotations

ARTICLES: list[dict] = [
    {
        "id": "art_vd_001",
        "title": "Vitamin D Deficiency: The Silent Epidemic",
        "category": "vitamin_d",
        "tags": ["vitamin d", "bone health", "immunity", "fatigue"],
        "summary": "Over 1 billion people worldwide are Vitamin D deficient. Learn how it affects your bones, mood, and immune system.",
        "content": (
            "Vitamin D is a fat-soluble vitamin that acts as a hormone in the body. It is essential for calcium absorption, "
            "bone mineralization, immune function, and mood regulation.\n\n"
            "**Causes of Deficiency:**\n"
            "- Limited sun exposure (indoor lifestyle, northern latitudes)\n"
            "- Dark skin pigmentation reduces UV absorption\n"
            "- Obesity (Vitamin D gets sequestered in fat tissue)\n"
            "- Malabsorption conditions (Crohn's, celiac disease)\n\n"
            "**Health Impacts:**\n"
            "- Rickets in children, osteomalacia in adults\n"
            "- Increased risk of depression and seasonal affective disorder\n"
            "- Weakened immune response — higher susceptibility to infections\n"
            "- Muscle weakness and chronic fatigue\n\n"
            "**Prevention:**\n"
            "- 20–30 minutes of midday sunlight on arms and legs\n"
            "- Foods: fatty fish (salmon, mackerel), egg yolks, fortified dairy\n"
            "- Supplement: 1000–2000 IU/day D3 (consult doctor for higher doses)\n\n"
            "**Target Level:** 30–60 ng/mL (75–150 nmol/L)"
        ),
        "read_time_min": 5,
        "video_url": "https://www.youtube.com/watch?v=HkFCFCBFByI",
        "video_title": "Vitamin D Deficiency Explained",
        "references": ["NIH Office of Dietary Supplements", "Holick MF, NEJM 2007"],
    },
    {
        "id": "art_b12_001",
        "title": "Vitamin B12: Why Vegetarians Are at High Risk",
        "category": "vitamin_b12",
        "tags": ["vitamin b12", "vegetarian", "nerve health", "brain fog", "anemia"],
        "summary": "B12 is found almost exclusively in animal products. Deficiency causes irreversible nerve damage if untreated.",
        "content": (
            "Vitamin B12 (cobalamin) is critical for DNA synthesis, red blood cell formation, and neurological function.\n\n"
            "**Who Is at Risk:**\n"
            "- Vegetarians and vegans (no animal products)\n"
            "- Adults over 50 (reduced stomach acid impairs absorption)\n"
            "- People on metformin (diabetes medication)\n"
            "- Those with pernicious anemia or gastric bypass surgery\n\n"
            "**Symptoms of Deficiency:**\n"
            "- Fatigue, weakness, pale or yellowish skin\n"
            "- Tingling or numbness in hands and feet (nerve damage)\n"
            "- Memory problems, brain fog, depression\n"
            "- Megaloblastic anemia (large, dysfunctional red blood cells)\n\n"
            "**Dietary Sources:**\n"
            "- Meat, fish, poultry, eggs, dairy\n"
            "- Fortified cereals and nutritional yeast (for vegans)\n"
            "- B12 supplements (cyanocobalamin or methylcobalamin)\n\n"
            "**Important:** Nerve damage from B12 deficiency can be irreversible if not treated early. "
            "Retest every 3 months if supplementing.\n\n"
            "**Target Level:** >300 pg/mL"
        ),
        "read_time_min": 6,
        "video_url": "https://www.youtube.com/watch?v=_ByEBjf9ktY",
        "video_title": "Vitamin B12 Deficiency — Causes, Symptoms & Treatment",
        "references": ["NIH B12 Fact Sheet", "Stabler SP, NEJM 2013"],
    },
    {
        "id": "art_iron_001",
        "title": "Iron Deficiency Anemia: The World's Most Common Deficiency",
        "category": "iron",
        "tags": ["iron", "ferritin", "anemia", "fatigue", "women's health"],
        "summary": "Iron deficiency affects 2 billion people globally. It's especially common in women of reproductive age.",
        "content": (
            "Iron is essential for hemoglobin production (oxygen transport) and energy metabolism.\n\n"
            "**Types of Iron:**\n"
            "- Heme iron (from meat) — absorbed at 15–35%\n"
            "- Non-heme iron (from plants) — absorbed at 2–20%\n\n"
            "**Risk Factors:**\n"
            "- Heavy menstrual periods\n"
            "- Pregnancy and breastfeeding\n"
            "- Vegetarian/vegan diet\n"
            "- Gastrointestinal bleeding (ulcers, colorectal cancer)\n\n"
            "**Symptoms:**\n"
            "- Extreme fatigue and weakness\n"
            "- Pale skin, brittle nails, hair loss\n"
            "- Shortness of breath on exertion\n"
            "- Pica (craving non-food items like ice or dirt)\n\n"
            "**Boost Absorption:**\n"
            "- Pair iron-rich foods with Vitamin C (lemon juice, bell peppers)\n"
            "- Avoid tea/coffee within 1 hour of iron-rich meals\n"
            "- Cook in cast iron pans\n\n"
            "**Target Ferritin:** >60 ng/mL (women), >100 ng/mL (men)"
        ),
        "read_time_min": 5,
        "video_url": "https://www.youtube.com/watch?v=PkMpetGLHgc",
        "video_title": "Iron Deficiency Anemia — Everything You Need to Know",
        "references": ["WHO Iron Deficiency Report", "Lopez A et al., Lancet 2016"],
    },
    {
        "id": "art_chol_001",
        "title": "Understanding Your Cholesterol Numbers",
        "category": "cholesterol",
        "tags": ["ldl", "hdl", "triglycerides", "heart health", "cardiovascular"],
        "summary": "Not all cholesterol is bad. Learn what LDL, HDL, and triglycerides mean for your heart health.",
        "content": (
            "Cholesterol is a waxy substance essential for cell membranes and hormone production. "
            "Problems arise when levels are imbalanced.\n\n"
            "**LDL (Bad Cholesterol):**\n"
            "- Deposits in artery walls → atherosclerosis → heart attack/stroke\n"
            "- Target: <100 mg/dL (optimal), <130 mg/dL (near optimal)\n\n"
            "**HDL (Good Cholesterol):**\n"
            "- Removes LDL from arteries back to liver\n"
            "- Target: >60 mg/dL (protective), <40 mg/dL (risk factor)\n\n"
            "**Triglycerides:**\n"
            "- Stored fat from excess calories, sugar, and alcohol\n"
            "- Target: <150 mg/dL\n\n"
            "**Lifestyle Changes That Work:**\n"
            "- Replace saturated fats with unsaturated fats (olive oil, nuts)\n"
            "- Eat 25–30g of fiber daily (oats, legumes, vegetables)\n"
            "- Exercise 150 min/week of moderate aerobic activity\n"
            "- Quit smoking — raises HDL by 5–10%\n"
            "- Limit alcohol to 1 drink/day"
        ),
        "read_time_min": 7,
        "video_url": "https://www.youtube.com/watch?v=9VXgONMFNMU",
        "video_title": "Cholesterol Explained — LDL, HDL & Triglycerides",
        "references": ["AHA Cholesterol Guidelines 2019", "Grundy SM et al., Circulation 2019"],
    },
    {
        "id": "art_sleep_001",
        "title": "Sleep and Metabolic Health: The Hidden Connection",
        "category": "lifestyle",
        "tags": ["sleep", "metabolism", "weight", "cortisol", "insulin"],
        "summary": "Poor sleep disrupts hormones, raises cortisol, and increases risk of obesity and diabetes.",
        "content": (
            "Sleep is not passive recovery — it's when your body repairs, consolidates memory, and regulates hormones.\n\n"
            "**What Happens During Sleep Deprivation:**\n"
            "- Ghrelin (hunger hormone) increases by 28%\n"
            "- Leptin (satiety hormone) decreases by 18%\n"
            "- Cortisol rises → promotes fat storage, especially abdominal\n"
            "- Insulin sensitivity drops → higher blood sugar\n\n"
            "**Health Consequences of <6 Hours/Night:**\n"
            "- 48% higher risk of heart disease\n"
            "- 36% higher risk of colorectal cancer\n"
            "- Impaired immune function\n"
            "- Cognitive decline and mood disorders\n\n"
            "**Sleep Hygiene Tips:**\n"
            "- Consistent sleep/wake schedule (even weekends)\n"
            "- Keep bedroom at 18–20°C\n"
            "- No screens 1 hour before bed (blue light suppresses melatonin)\n"
            "- Avoid caffeine after 2 PM\n"
            "- 10-min wind-down routine (reading, stretching)"
        ),
        "read_time_min": 6,
        "video_url": "https://www.youtube.com/watch?v=5MuIMqhT8oU",
        "video_title": "Why Sleep Is the Most Important Pillar of Health",
        "references": ["Walker M, Why We Sleep 2017", "Cappuccio FP, Sleep 2010"],
    },
    {
        "id": "art_steps_001",
        "title": "10,000 Steps: Myth or Science?",
        "category": "lifestyle",
        "tags": ["steps", "walking", "cardiovascular", "weight loss", "activity"],
        "summary": "The 10,000 steps goal has real science behind it. Even 7,000 steps/day significantly reduces mortality risk.",
        "content": (
            "The 10,000 steps goal originated from a 1960s Japanese marketing campaign, but modern research validates it.\n\n"
            "**What the Research Shows:**\n"
            "- 7,000–8,000 steps/day reduces all-cause mortality by 50–65%\n"
            "- Each additional 1,000 steps reduces cardiovascular risk by 10%\n"
            "- Walking after meals reduces post-meal blood sugar spikes by 30%\n\n"
            "**Benefits of Daily Walking:**\n"
            "- Burns 300–500 kcal/day (at 10,000 steps)\n"
            "- Reduces LDL cholesterol and blood pressure\n"
            "- Improves insulin sensitivity\n"
            "- Boosts mood via endorphin release\n\n"
            "**How to Increase Steps:**\n"
            "- Park farther away from destinations\n"
            "- Take stairs instead of elevators\n"
            "- Walk during phone calls\n"
            "- 10-min walk after each meal\n"
            "- Use a step tracker for accountability"
        ),
        "read_time_min": 4,
        "video_url": "https://www.youtube.com/watch?v=njeZ29umqVE",
        "video_title": "The Science of Walking 10,000 Steps a Day",
        "references": ["Saint-Maurice PF, JAMA 2020", "Paluch AE, Nature Medicine 2022"],
    },
    {
        "id": "art_bodyfat_001",
        "title": "Body Fat Percentage: What It Means and How to Reduce It",
        "category": "body_composition",
        "tags": ["body fat", "obesity", "metabolism", "weight loss", "muscle"],
        "summary": "Body fat percentage is a better health indicator than BMI. Learn healthy ranges and evidence-based reduction strategies.",
        "content": (
            "Body fat percentage measures the proportion of fat to total body weight. "
            "Unlike BMI, it distinguishes between fat mass and muscle mass.\n\n"
            "**Healthy Ranges:**\n"
            "- Women: 20–25% (fit), 25–31% (acceptable)\n"
            "- Men: 10–18% (fit), 18–25% (acceptable)\n"
            "- Above 30% (women) / 25% (men) = increased metabolic risk\n\n"
            "**Health Risks of High Body Fat:**\n"
            "- Type 2 diabetes and insulin resistance\n"
            "- Hypertension and cardiovascular disease\n"
            "- Sleep apnea and joint problems\n"
            "- Hormonal imbalances\n\n"
            "**Evidence-Based Reduction Strategies:**\n"
            "- Caloric deficit of 300–500 kcal/day (sustainable fat loss)\n"
            "- High protein intake (1.6–2.2g/kg body weight) preserves muscle\n"
            "- Resistance training 3x/week builds metabolically active muscle\n"
            "- HIIT (High Intensity Interval Training) burns fat efficiently\n"
            "- Prioritize sleep — sleep deprivation increases fat storage"
        ),
        "read_time_min": 6,
        "video_url": "https://www.youtube.com/watch?v=ruNrdmJlNyQ",
        "video_title": "Body Fat Percentage Explained",
        "references": ["Gallagher D et al., AJCN 2000", "ACSM Guidelines 2021"],
    },
]

VIDEOS: list[dict] = [
    {
        "id": "vid_001",
        "title": "How Nutrient Deficiencies Affect Your Body",
        "category": "general",
        "duration_min": 8,
        "url": "https://www.youtube.com/watch?v=4Yb2f0wMCgA",
        "thumbnail": "https://img.youtube.com/vi/4Yb2f0wMCgA/hqdefault.jpg",
        "description": "A comprehensive overview of how common deficiencies manifest as symptoms.",
        "tags": ["deficiency", "symptoms", "nutrition", "overview"],
    },
    {
        "id": "vid_002",
        "title": "Reading Your Blood Test Results",
        "category": "biomarkers",
        "duration_min": 12,
        "url": "https://www.youtube.com/watch?v=lHnMma0_xhQ",
        "thumbnail": "https://img.youtube.com/vi/lHnMma0_xhQ/hqdefault.jpg",
        "description": "Learn to interpret CBC, lipid panel, and vitamin levels from your lab report.",
        "tags": ["blood test", "lab results", "biomarkers", "interpretation"],
    },
    {
        "id": "vid_003",
        "title": "Anti-Inflammatory Diet: A Beginner's Guide",
        "category": "diet",
        "duration_min": 10,
        "url": "https://www.youtube.com/watch?v=Yx2qkMJFMoI",
        "thumbnail": "https://img.youtube.com/vi/Yx2qkMJFMoI/hqdefault.jpg",
        "description": "Foods that fight inflammation and reduce chronic disease risk.",
        "tags": ["anti-inflammatory", "diet", "chronic disease", "nutrition"],
    },
    {
        "id": "vid_004",
        "title": "Strength Training for Metabolic Health",
        "category": "exercise",
        "duration_min": 15,
        "url": "https://www.youtube.com/watch?v=2tM1LFFxeKg",
        "thumbnail": "https://img.youtube.com/vi/2tM1LFFxeKg/hqdefault.jpg",
        "description": "How resistance training improves insulin sensitivity, cholesterol, and body composition.",
        "tags": ["strength training", "metabolism", "insulin", "muscle"],
    },
    {
        "id": "vid_005",
        "title": "Gut Health and Nutrient Absorption",
        "category": "gut_health",
        "duration_min": 9,
        "url": "https://www.youtube.com/watch?v=1sISguPDlhY",
        "thumbnail": "https://img.youtube.com/vi/1sISguPDlhY/hqdefault.jpg",
        "description": "How gut microbiome health directly impacts how well you absorb vitamins and minerals.",
        "tags": ["gut health", "microbiome", "absorption", "probiotics"],
    },
]

CATEGORIES = ["vitamin_d", "vitamin_b12", "iron", "cholesterol", "lifestyle", "body_composition", "general", "biomarkers", "diet", "exercise", "gut_health"]


def get_articles(category: str | None = None, tag: str | None = None) -> list[dict]:
    results = ARTICLES
    if category:
        results = [a for a in results if a["category"] == category]
    if tag:
        results = [a for a in results if tag.lower() in a["tags"]]
    return results


def get_article_by_id(article_id: str) -> dict | None:
    return next((a for a in ARTICLES if a["id"] == article_id), None)


def get_videos(category: str | None = None, tag: str | None = None) -> list[dict]:
    results = VIDEOS
    if category:
        results = [v for v in results if v["category"] == category]
    if tag:
        results = [v for v in results if tag.lower() in v["tags"]]
    return results


def search_content(query: str) -> dict:
    q = query.lower()
    articles = [a for a in ARTICLES if q in a["title"].lower() or q in a["summary"].lower() or any(q in t for t in a["tags"])]
    videos   = [v for v in VIDEOS   if q in v["title"].lower() or q in v["description"].lower() or any(q in t for t in v["tags"])]
    return {"articles": articles, "videos": videos, "total": len(articles) + len(videos)}
