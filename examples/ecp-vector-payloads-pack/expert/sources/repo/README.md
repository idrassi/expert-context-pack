# Bundled Repo (for ECP conformance)

This repository is bundled inside `examples/ecp-conformance-pack` so that:
- `ecpctl query` works without cloning anything.
- `ecpctl run-evals --suite-id conformance` can validate citations offline.

Files:
- `auth.py`: authentication and session handling
- `db.py`: database connection and queries
- `main.py`: entrypoint wiring auth + db

