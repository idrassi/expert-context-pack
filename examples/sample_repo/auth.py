"""Authentication module.

In a real system this would include password hashing, OAuth, JWT, session tokens, etc.
"""

from dataclasses import dataclass
from typing import Optional

@dataclass
class User:
    user_id: str
    email: str

def authenticate(email: str, password: str) -> Optional[User]:
    """Authenticate a user. Returns a User on success, None on failure."""
    # NOTE: PoC implementation; do not use in production.
    if email and password and password == "correct-horse-battery-staple":
        return User(user_id="u-123", email=email)
    return None

def issue_session_token(user: User) -> str:
    """Issue a session token for an authenticated user."""
    return f"session::{user.user_id}"
