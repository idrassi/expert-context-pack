from auth import User, authenticate, hash_password


def test_authenticate_success() -> None:
    salt = "salt"
    user = User(user_id="u1", email="a@example.com", role="admin", password_hash=hash_password("pw", salt), salt=salt)
    assert authenticate("a@example.com", "pw", {"a@example.com": user})


def test_authenticate_failure() -> None:
    salt = "salt"
    user = User(user_id="u1", email="a@example.com", role="admin", password_hash=hash_password("pw", salt), salt=salt)
    assert authenticate("a@example.com", "bad", {"a@example.com": user}) is None
