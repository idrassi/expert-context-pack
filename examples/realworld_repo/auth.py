"""Authentication helpers for the demo service."""

import hashlib
import hmac
from dataclasses import dataclass
from typing import Optional


@dataclass
class User:
    user_id: str
    email: str
    role: str
    password_hash: str
    salt: str


def hash_password(password: str, salt: str) -> str:
    payload = (salt + password).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def verify_password(password: str, salt: str, expected_hash: str) -> bool:
    candidate = hash_password(password, salt)
    return hmac.compare_digest(candidate, expected_hash)


def authenticate(email: str, password: str, user_store: dict[str, User]) -> Optional[User]:
    user = user_store.get(email)
    if not user:
        return None
    if not verify_password(password, user.salt, user.password_hash):
        return None
    return user


def require_role(user: User, required: str) -> None:
    if user.role != required:
        raise PermissionError(f"Requires role {required}")
