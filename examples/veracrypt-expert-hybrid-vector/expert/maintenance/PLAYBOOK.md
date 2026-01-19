# Maintenance playbook (PoC)

- Preferred update mode: incremental.
- If too many files changed (see policy thresholds), rebuild.
- Always run eval suites after refresh.
- If evals fail, rollback to previous index state.

Operational commands:

- Build: `ecpctl build --skill <skill_dir>`
- Refresh: `ecpctl refresh --skill <skill_dir>`
- Validate: `ecpctl validate --skill <skill_dir>`
- Evals: `ecpctl run-evals --skill <skill_dir>`

Vector-specific notes:

- `vec-v1` uses a local hashing embedder by default (offline PoC).
- To plug in a real embedder, generate a compatible `query_vector` and pass it via `--query-vector-file`.

