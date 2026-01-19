# Examples

This directory contains example ECP-enabled skills, small demo corpora, and end-to-end demo scripts.

## Example skills

- `codebase-expert` — minimal codebase profile skill built against local demo sources.
- `codebase-expert-sqlite` — codebase profile using a SQLite FTS backend.
- `codebase-expert-hybrid` — hybrid retrieval (multiple indexes + RRF fusion).
- `ecp-conformance-pack` — fully offline conformance pack (unzip → query → evals).
- `ecp-vector-payloads-pack` — portable `vector-index-v1` examples (JSONL vs BIN/NPY).
- `veracrypt-expert` — VeraCrypt template (keyword index backend; requires cloning VeraCrypt locally).
- `veracrypt-expert-sqlite` — VeraCrypt template (SQLite FTS backend; requires cloning VeraCrypt locally).
- `veracrypt-expert-hybrid-vector` — VeraCrypt template (hybrid vector + SQLite FTS; requires cloning VeraCrypt locally).

## Demo corpora (not skills)

- `sample_repo` — tiny repository used by some unit tests and demos.
- `realworld_repo` — larger demo repository used by the `codebase-expert` examples.

## Demo scripts

- `demo-codebase-expert.(ps1|sh)` — validate → build/refresh → query → evals (and retention).
- `demo-ecp-conformance-pack.(ps1|sh)` — validate → query → evals → pack → verify → unzip → query → evals.
- `demo-veracrypt-expert.(ps1|sh)` — scripted VeraCrypt run (auto-selects hybrid when reminders are present).
- `demo-veracrypt-showcase.(ps1|sh)` — longer showcase run for community demos.

