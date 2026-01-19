# VeraCrypt Expert (Hybrid: Vector + SQLite FTS) (placeholder summary)

This file exists so that `ecpctl validate --strict` can validate the pack layout without requiring you to build artifacts first.

To populate real context artifacts:

1. Clone VeraCrypt into `examples/VeraCrypt` (or update `sources[0].uri` in `expert/EXPERT.yaml`).
2. Build indexes:
   - `ecpctl build --skill examples/veracrypt-expert-hybrid-vector`
3. Optionally generate richer summaries:
   - `ecpctl generate-summaries --skill examples/veracrypt-expert-hybrid-vector`

