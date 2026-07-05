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
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS user_profiles (
                user_id INTEGER PRIMARY KEY,
                goals_json TEXT NOT NULL DEFAULT '{}',
                FOREIGN KEY(user_id) REFERENCES users(id)
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS forum_posts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                title TEXT NOT NULL,
                body TEXT NOT NULL,
                category TEXT NOT NULL DEFAULT 'general',
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(user_id) REFERENCES users(id)
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS forum_replies (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                post_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                body TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(post_id) REFERENCES forum_posts(id),
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


# ── Profile / Goals ───────────────────────────────────────────────────────────

def get_user_goals(user_id: int) -> dict[str, Any]:
    with _connect() as conn:
        row = conn.execute("SELECT goals_json FROM user_profiles WHERE user_id = ?", (user_id,)).fetchone()
    return json.loads(row["goals_json"]) if row else {}


def save_user_goals(user_id: int, goals: dict[str, Any]) -> None:
    goals_json = json.dumps(goals, separators=(",", ":"))
    with _connect() as conn:
        conn.execute(
            "INSERT INTO user_profiles (user_id, goals_json) VALUES (?, ?) "
            "ON CONFLICT(user_id) DO UPDATE SET goals_json = excluded.goals_json",
            (user_id, goals_json),
        )


def get_username(user_id: int) -> str:
    with _connect() as conn:
        row = conn.execute("SELECT username FROM users WHERE id = ?", (user_id,)).fetchone()
    return str(row["username"]) if row else "unknown"


def get_recommendation_count(user_id: int) -> int:
    with _connect() as conn:
        row = conn.execute(
            "SELECT COUNT(*) as cnt FROM recommendation_history WHERE user_id = ?", (user_id,)
        ).fetchone()
    return int(row["cnt"]) if row else 0


def get_streak_days(user_id: int) -> int:
    """Count consecutive days (ending today) with at least one recommendation."""
    with _connect() as conn:
        rows = conn.execute(
            "SELECT DATE(created_at) as day FROM recommendation_history "
            "WHERE user_id = ? GROUP BY day ORDER BY day DESC",
            (user_id,),
        ).fetchall()
    if not rows:
        return 0
    from datetime import date, timedelta
    today = date.today()
    streak = 0
    for row in rows:
        expected = today - timedelta(days=streak)
        if str(row["day"]) == str(expected):
            streak += 1
        else:
            break
    return streak


# ── Forum ─────────────────────────────────────────────────────────────────────

def create_forum_post(user_id: int, title: str, body: str, category: str) -> int:
    with _connect() as conn:
        cur = conn.execute(
            "INSERT INTO forum_posts (user_id, title, body, category) VALUES (?, ?, ?, ?)",
            (user_id, title, body, category),
        )
        return int(cur.lastrowid)


def get_forum_posts(category: str | None = None, limit: int = 50) -> list[dict[str, Any]]:
    with _connect() as conn:
        if category:
            rows = conn.execute(
                "SELECT fp.*, u.username, "
                "(SELECT COUNT(*) FROM forum_replies fr WHERE fr.post_id = fp.id) as reply_count "
                "FROM forum_posts fp JOIN users u ON fp.user_id = u.id "
                "WHERE fp.category = ? ORDER BY fp.id DESC LIMIT ?",
                (category, limit),
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT fp.*, u.username, "
                "(SELECT COUNT(*) FROM forum_replies fr WHERE fr.post_id = fp.id) as reply_count "
                "FROM forum_posts fp JOIN users u ON fp.user_id = u.id "
                "ORDER BY fp.id DESC LIMIT ?",
                (limit,),
            ).fetchall()
    return [dict(r) for r in rows]


def create_forum_reply(post_id: int, user_id: int, body: str) -> int:
    with _connect() as conn:
        cur = conn.execute(
            "INSERT INTO forum_replies (post_id, user_id, body) VALUES (?, ?, ?)",
            (post_id, user_id, body),
        )
        return int(cur.lastrowid)


def get_forum_replies(post_id: int) -> list[dict[str, Any]]:
    with _connect() as conn:
        rows = conn.execute(
            "SELECT fr.*, u.username FROM forum_replies fr "
            "JOIN users u ON fr.user_id = u.id WHERE fr.post_id = ? ORDER BY fr.id ASC",
            (post_id,),
        ).fetchall()
    return [dict(r) for r in rows]
