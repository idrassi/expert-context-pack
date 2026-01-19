---
name: ecp-conformance-pack
description: Self-contained, offline ECP v1.0 conformance pack (skill + bundled source + prebuilt indexes) for validating response shape and citation integrity.
license: Apache-2.0
compatibility: Requires local filesystem access only (no network).
allowed-tools: Read Grep Glob
---

# ECP Conformance Pack

Use this skill to demonstrate and validate ECP behavior in a fully offline, reproducible way.

When active:
1. Prefer `expert.query` (or `ecpctl query`) for questions about the bundled repo.
2. Provide answers with citations (file path + line ranges).
3. Use `expert.run_evals` (or `ecpctl run-evals`) to verify conformance.
