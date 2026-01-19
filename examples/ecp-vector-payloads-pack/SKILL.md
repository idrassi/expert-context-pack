---
name: ecp-vector-payloads-pack
description: Demonstrates vector-index-v1 with both JSONL and binary (NPY/BIN) vector payloads while keeping chunk_id/chunks.jsonl as the interoperability anchor.
license: Apache-2.0
compatibility: Requires local filesystem access only (no network).
allowed-tools: Read Grep Glob
---

# ECP Vector Payloads Pack

Use this skill to demonstrate `vector-index-v1` portability and scalability options.

When active:
1. Prefer `expert.query` (or `ecpctl query`) for questions about the bundled repo.
2. Provide answers with citations (file path + line ranges).
3. Compare `vec-v1` (JSONL) vs `vec-v1-npy` (NPY) vector payloads.
