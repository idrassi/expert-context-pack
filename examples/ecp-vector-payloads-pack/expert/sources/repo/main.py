"""Entrypoint.

Wires authentication + database access.
"""

from auth import authenticate, issue_session_token
from db import connect, fetch_user


def login_flow(email: str, password: str) -> str:
    user = authenticate(email, password)
    if not user:
        return "DENIED"
    token = issue_session_token(user)
    return token


def get_profile(db_path: str, user_id: str) -> dict | None:
    conn = connect(db_path)
    return fetch_user(conn, user_id)

