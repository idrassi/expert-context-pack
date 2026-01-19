import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Config:
    database_url: str
    enable_audit: bool


def load_config() -> Config:
    return Config(
        database_url=os.environ.get("ACME_DATABASE_URL", "data.db"),
        enable_audit=os.environ.get("ACME_ENABLE_AUDIT", "false").lower() == "true",
    )
