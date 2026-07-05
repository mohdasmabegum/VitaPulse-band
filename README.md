# Diet Recommendation System (MVP)

A practical MVP backend for a diet recommendation system that uses health markers to:

- Suggest foods for low vitamin levels (Vitamin D, B12, Iron/Ferritin)
- Suggest basic food strategies to reduce excess fat
- Suggest heart-friendly foods to improve cholesterol profile

## Tech Stack

- Python 3.10+
- FastAPI
- Pydantic v2

## Project Structure

```text
app/
  main.py        # API routes
  models.py      # Input/output schema
  food_db.py     # Food recommendation lists
  engine.py      # Rule-based recommendation logic
data/
  sample_user.json
tests/
  test_engine.py
requirements.txt
```

## Run Locally

```bash
python -m venv .venv
.venv\\Scripts\\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Open API docs at `http://127.0.0.1:8000/docs`.
Open dashboard at `http://127.0.0.1:8000/dashboard`.

## Main Endpoint

`POST /recommend`

## Auth And History

- `POST /auth/register` with `{ "username": "...", "password": "..." }`
- `POST /auth/login` with `{ "username": "...", "password": "..." }`
- `POST /recommend/save` with `Authorization: Bearer <token>` to save result in SQLite
- `GET /history?limit=10` with `Authorization: Bearer <token>` to fetch saved recommendations

SQLite file is created as `diet_system.db` in project root.

## Dashboard UI

- Route: `GET /dashboard`
- Static assets are served from `/static/*`
- Register or login in the Account section to enable persistent history.
- Without login, dashboard submits to `/recommend`; with login, it submits to `/recommend/save`.
- Allergies entered in the form are used to filter matching food suggestions.

Example request body is available at `data/sample_user.json`.

Example with curl:

```bash
curl -X POST "http://127.0.0.1:8000/recommend" ^
  -H "Content-Type: application/json" ^
  -d @data/sample_user.json
```

## Notes

- This is a rule-based prototype for explainable guidance.
- Wearables can estimate behavior trends continuously, while vitamin/lipid biomarkers are typically periodic lab values.
- Not a diagnostic system; medical consultation is required for treatment decisions.

## Flutter Mobile App

The `diet_app/` folder contains a Flutter app with 4 screens:
- **Symptoms** — interactive symptom checker chatbot (`POST /symptom-check`)
- **Recommend** — full biomarker form (`POST /recommend` or `/recommend/save`)
- **History** — saved recommendations (requires login)
- **Account** — register / login / logout

### Prerequisites
1. Install Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Add `C:\flutter\bin` to PATH
3. Install Android Studio + Android SDK
4. Run `flutter doctor --android-licenses`

### Build APK
```bash
cd diet_app
flutter pub get
flutter build apk --release
```
APK output: `diet_app/build/app/outputs/flutter-apk/app-release.apk`

### Run on emulator / device
```bash
flutter run
```

> The app connects to `http://10.0.2.2:8000` (Android emulator → your localhost).  
> For a physical device, replace with your machine's local IP in `lib/api_service.dart`.

## Next Iteration Ideas

- Add user authentication
- Persist user history in a database
- Build a frontend dashboard
- Add India/region-specific food packs
- Add personalization with feedback loops
