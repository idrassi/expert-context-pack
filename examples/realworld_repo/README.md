# Acme Inventory Service

This repository is a small but realistic demo codebase for the ECP PoC. It models a lightweight
inventory + order management service with authentication, persistence, and a minimal API surface.

## Architecture

- `main.py` bootstraps the application via `app.create_app`.
- `auth.py` provides password hashing and role checks.
- `db.py` manages a SQLite connection and transaction helpers.
- `app/` contains core app configuration, routing, and domain services.
- `migrations/` includes the schema used by the demo database.
- `scripts/` provides seed data utilities for local testing.
- `tests/` includes basic unit tests for auth and order flows.

## Key modules

- `app/routes.py`: HTTP-style handlers that translate requests into service calls.
- `app/services/orders.py`: order lifecycle, pricing, and status transitions.
- `app/services/inventory.py`: stock checks, reservations, and adjustments.
- `app/models.py`: dataclasses representing domain entities.

## Running locally (pseudo)

```bash
python main.py
```

This is intentionally lightweight; it is designed for indexing, retrieval, and evaluation demos.
