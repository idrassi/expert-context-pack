"""Database module.

Demonstrates where data access would be implemented.
"""

import sqlite3
from typing import Any

def connect(db_path: str) -> sqlite3.Connection:
    return sqlite3.connect(db_path)

def fetch_user(conn: sqlite3.Connection, user_id: str) -> dict[str, Any] | None:
    cur = conn.cursor()
    cur.execute("SELECT user_id, email FROM users WHERE user_id = ?", (user_id,))
    row = cur.fetchone()
    if not row:
        return None
    return {"user_id": row[0], "email": row[1]}
