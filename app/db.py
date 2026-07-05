from __future__ import annotations

import hashlib
import json
import secrets
import sqlite3
from pathlib import Path
from typing import Any

from app.models import RecommendationResponse, SavedRecommendation, UserInput

BASE_DIR = Path(__file__).resolve().parent.parent
DB_PATH = BASE_DIR / "diet_system.db"


def _connect() -> sqlite3.Connection:
    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row
    return connection


def init_db() -> None:
    with _connect() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                salt TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS sessions (
                token TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(user_id) REFERENCES users(id)
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS recommendation_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                payload_json TEXT NOT NULL,
                response_json TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(user_id) REFERENCES users(id)
            )
            """
        )


def _hash_password(password: str, salt: str) -> str:
    return hashlib.sha256(f"{salt}:{password}".encode("utf-8")).hexdigest()


def register_user(username: str, password: str) -> bool:
    salt = secrets.token_hex(16)
    password_hash = _hash_password(password, salt)

    try:
        with _connect() as conn:
            conn.execute(
                "INSERT INTO users (username, password_hash, salt) VALUES (?, ?, ?)",
                (username.strip().lower(), password_hash, salt),
            )
        return True
    except sqlite3.IntegrityError:
        return False


def verify_user(username: str, password: str) -> int | None:
    with _connect() as conn:
        row = conn.execute(
            "SELECT id, password_hash, salt FROM users WHERE username = ?",
            (username.strip().lower(),),
        ).fetchone()

    if not row:
        return None

    if _hash_password(password, row["salt"]) != row["password_hash"]:
        return None

    return int(row["id"])


def create_session(user_id: int) -> str:
    token = secrets.token_urlsafe(32)
    with _connect() as conn:
        conn.execute("INSERT INTO sessions (token, user_id) VALUES (?, ?)", (token, user_id))
    return token


def get_user_id_by_token(token: str) -> int | None:
    with _connect() as conn:
        row = conn.execute("SELECT user_id FROM sessions WHERE token = ?", (token,)).fetchone()
    return int(row["user_id"]) if row else None


def save_recommendation(user_id: int, payload: UserInput, recommendation: RecommendationResponse) -> int:
    payload_json = json.dumps(payload.model_dump(), separators=(",", ":"))
    response_json = json.dumps(recommendation.model_dump(), separators=(",", ":"))

    with _connect() as conn:
        cursor = conn.execute(
            """
            INSERT INTO recommendation_history (user_id, payload_json, response_json)
            VALUES (?, ?, ?)
            """,
            (user_id, payload_json, response_json),
        )
        return int(cursor.lastrowid)


def get_history(user_id: int, limit: int = 20) -> list[SavedRecommendation]:
    with _connect() as conn:
        rows = conn.execute(
            """
            SELECT id, payload_json, response_json, created_at
            FROM recommendation_history
            WHERE user_id = ?
            ORDER BY id DESC
            LIMIT ?
            """,
            (user_id, limit),
        ).fetchall()

    history: list[SavedRecommendation] = []
    for row in rows:
        payload_obj: dict[str, Any] = json.loads(row["payload_json"])
        response_obj: dict[str, Any] = json.loads(row["response_json"])
        history.append(
            SavedRecommendation(
                id=int(row["id"]),
                created_at=str(row["created_at"]),
                payload=UserInput(**payload_obj),
                recommendation=RecommendationResponse(**response_obj),
            )
        )
    return history
