# Maintenance playbook (VeraCrypt demo)

- Preferred update mode: incremental (`git diff`) when possible.
- If too many files changed (see policy thresholds), rebuild.
- Always run eval suites after refresh.
- If evals fail, rollback to previous index state.

Operational commands:

- Validate: `ecpctl validate --skill <skill_dir>`
- Build: `ecpctl build --skill <skill_dir>`
- Refresh: `ecpctl refresh --skill <skill_dir>`
- Evals: `ecpctl run-evals --skill <skill_dir>`
