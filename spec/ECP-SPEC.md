# Expert Context Pack (ECP) v1.0
## An extension profile for Agent Skills that enables persistent, maintainable, and testable expert context

**Status:** Stable
**Version:** 1.0
**Date:** 2026-01-19
**Author:** Mounir IDRASSI (AM Crypto)

---

### Abstract

Agent Skills provide a portable, filesystem-based format for packaging agent capabilities (instructions + optional scripts/resources). The Expert Context Pack (ECP) specification defines a *backward-compatible extension* that adds persistent domain context, lifecycle maintenance policy, evaluation harnesses, and auditable provenance to an Agent Skill.

ECP enables "Expert Agents" that can answer domain questions quickly and repeatedly without re-discovering context each time, while still being governed by explicit freshness, cost, security, and evaluation controls.

---

## 1. Scope

ECP v1.0 defines:

1. **A directory extension** (`expert/`) that may be added to any Agent Skill directory.
2. **A manifest** (`expert/EXPERT.yaml`) that declares expert identity, sources, context artifacts, maintenance policy, evaluation suites, and logging.
3. **Standard artifact formats** for provenance/citations, maintenance policy, and evaluation suites.
4. **A minimal runtime contract** for querying an expert and receiving an answer with citations.
5. **Conformance levels** that allow incremental adoption.

### 1.1 Non-goals (v1.0)

ECP v1.0 does **not** standardize:

- A specific embedding model, vector database, or retrieval algorithm.
- A specific "memory write" policy for all use cases (only a minimal gating model).
- A specific packaging/distribution mechanism beyond what Agent Skills already support (ZIP or directory).
- A cross-vendor evaluation benchmark format (only a practical harness).

---

## 2. Normative language

The key words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as described in RFC 2119 / RFC 8174.

### 2.1 Normative schemas and versioning

This specification publishes **normative JSON Schemas** under `spec/schemas/` that define the required structure of ECP artifacts.
Implementations MUST validate artifacts against the schemas referenced by this specification.

Schema identifiers are the schema documents' `$id` values (for example, `https://ecp.amcrypto.org/ecp/schemas/ecp-manifest.schema.json`).
Implementations MUST NOT require network access to resolve `$id` URLs; they SHOULD use the bundled copies under `spec/schemas/`.
If the prose and a referenced JSON Schema disagree on structural constraints (field presence, types, allowed values), the JSON Schema is authoritative.

#### 2.1.1 Compatibility rules (major/minor/patch)

ECP uses semantic versioning for the specification itself:

- **Major** version changes MAY be breaking (non-backward-compatible).
- **Minor** version changes MUST be backward-compatible (additive; existing valid instances remain valid).
- **Patch** version changes MUST be backward-compatible bug fixes/clarifications.

---

## 3. Relationship to Agent Skills

### 3.1 Backward compatibility

ECP is an *extension* to the Agent Skills directory format.

An Agent Skill implementation that does not understand ECP MUST still treat an ECP-enhanced skill as a valid Skill, because:

- ECP only adds an optional subdirectory (`expert/`).
- ECP does not modify the required `SKILL.md` requirements.

Implementations that support ECP MUST ignore any ECP artifacts they do not recognize.

### 3.2 Skill metadata requirements

`SKILL.md` frontmatter MUST include `name` and `description`, as required by the Agent Skills specification. The skill directory name MUST match the `name` value.

ECP does not change these requirements.

### 3.3 Recommended Skill frontmatter for experts

For ECP-enabled skills, the `SKILL.md` frontmatter SHOULD include:

- `license` (if redistributable)
- `compatibility` describing runtime requirements (e.g., "Requires git and local repo access")
- `allowed-tools` to restrict tool usage in security-sensitive environments (if supported by the host agent runtime)

---

## 4. Directory structure

An ECP-enabled Expert Skill MUST have the following structure:

```
skill-name/
|-- SKILL.md                      # Required by Agent Skills
`-- expert/
    |-- EXPERT.yaml               # Required by ECP
    |-- context/                  # Optional but recommended
    |   |-- snapshots/            # Optional
    |   |-- indexes/              # Optional but recommended
    |   `-- summaries/            # Optional but recommended
    |-- maintenance/
    |   |-- policy.json           # Required by ECP
    |   `-- PLAYBOOK.md           # Optional
    |-- evals/
    |   `-- *.yaml                # Required by ECP (at least one suite)
    `-- logs/                     # Optional (generated at runtime)
        |-- updates/              # Optional
        `-- queries/              # Optional
```

### 4.1 Path conventions

All paths declared in `EXPERT.yaml` MUST be relative to the *skill root directory* unless explicitly marked as absolute.

Paths MUST use POSIX-style separators (`/`) inside manifests for portability.

---

## 5. Manifest: `expert/EXPERT.yaml`

### 5.1 File format

`EXPERT.yaml` MUST be a UTF-8 text file containing YAML 1.2 (or a JSON subset compatible with YAML).
The parsed YAML value MUST validate against the JSON Schema with `$id` `https://ecp.amcrypto.org/ecp/schemas/ecp-manifest.schema.json` (also distributed as `spec/schemas/ecp-manifest.schema.json`).

### 5.2 Required top-level fields

`EXPERT.yaml` MUST contain at least the following fields:

- `ecp_version` (string): The ECP spec version this pack targets. MUST be `"1.0"` for this specification.
- `id` (string): Stable identifier for the expert within a skill ecosystem.
- `skill` (object): Linkage to the Skill.
- `sources` (array): One or more source descriptors.
- `context` (object): The context strategy and artifact declarations.
- `maintenance` (object): Links to maintenance policy and optional playbook.
- `evals` (object): One or more evaluation suites.

### 5.3 Required linkage: `skill`

`skill` MUST include:

- `name` (string): MUST equal the `name` in `SKILL.md` frontmatter and MUST equal the skill directory name.

`skill` MAY include:

- `min_agent_skills_spec` (string): A reference to the Agent Skills spec version/revision.
- `surfaces` (array): Intended agent surfaces (e.g., `["claude-code", "api", "vscode"]`).

### 5.4 Expert identity and metadata

The following fields are RECOMMENDED:

- `display_name` (string)
- `description` (string)
- `tags` (array of strings)
- `owners` (array of objects with `{name, email, team}`)

### 5.5 Security metadata

`security` is RECOMMENDED and SHOULD include:

- `classification` (enum): `public | internal | confidential | restricted`
- `retention_days` (integer)
- `contains_secrets` (boolean, default false)
- `contains_pii` (enum): `none | possible | likely`
- `license` (string): content licensing for redistributable packs
- `allow_remote_llm` (boolean, default false): whether a runtime may send retrieved excerpts to a remote LLM provider for answer synthesis
- `allowed_remote_llm_providers` (array of strings, optional): allowlist of remote providers (for example, `["openai", "anthropic", "openrouter"]`)

If `contains_secrets` is `true`, the pack MUST NOT be distributed outside approved secure channels and SHOULD NOT be bundled as a ZIP skill without encryption.
If `contains_secrets` is `true`, runtimes MUST NOT use remote LLM synthesis with any excerpted content from this pack.

### 5.6 Source descriptors: `sources[]`

Each source descriptor MUST include:

- `source_id` (string): Unique within this pack.
- `type` (enum): `git | filesystem | web | database | artifact`
- `uri` (string): A resolvable identifier (URL, file URI, DSN, etc.).
- `scope` (object): Inclusion/exclusion rules.
- `revision` (object): Declares the "as-of" state captured by the current context pack build.
- `refresh` (object): Declares the default update strategy.

#### 5.6.1 `scope`

`scope` MUST contain at least one of:

- `include` (array of glob strings)
- `exclude` (array of glob strings)

Implementations SHOULD interpret globbing as gitignore-like patterns for `git`/`filesystem` sources.

#### 5.6.2 `revision`

`revision` MUST contain sufficient information to answer: "What was the source state when this context was built?"

For `git` sources, `revision` SHOULD include:
- `commit` (string)
- `branch` (string, optional)
- `timestamp` (RFC3339 string)

For `web` sources, `revision` SHOULD include:
- `retrieved_at` (RFC3339 string)
- `etag` (string, optional)
- `last_modified` (string, optional)

For `filesystem` sources, `revision` SHOULD include:
- `hash` (string): a stable content hash for the *scoped* file set (for example, a `sha256` computed from a canonicalized file manifest of `{path -> {sha256,size,skipped}}` with keys sorted).
- `timestamp` (RFC3339 string)

For `database` sources, `revision` SHOULD include:
- `timestamp` (RFC3339 string): when the database state was captured
- `query_hash` (string, optional): a hash of the query/view definition used to extract data
- `row_count` (integer, optional): number of rows in the extracted dataset

#### 5.6.3 `refresh`

`refresh` MUST include:
- `strategy` (enum): `none | incremental | rebuild`
- `incremental` (object, required if strategy is `incremental`)
- `rebuild` (object, required if strategy is `rebuild`)

For `git` sources, incremental refresh SHOULD support `git diff`-based update.
For `filesystem` sources, incremental refresh SHOULD support a file-manifest or content-hash diff when git metadata is not available.

### 5.7 Context: `context`

`context` MUST include:
- `strategy` (enum): `snapshot | retrieval | hybrid`
- `artifacts` (object)

#### 5.7.1 `artifacts`

`artifacts` MAY include:
- `snapshots` (array)
- `indexes` (array)
- `summaries` (array)
- `provenance` (object)

At least one of `indexes` or `summaries` MUST be present.

##### Snapshots

A snapshot entry SHOULD include:
- `id` (string)
- `path` (string)
- `format` (string, e.g., `tar.zst`, `zip`, `directory`)
- `content_hash` (string, e.g., `sha256:...`)
- `as_of` (object): `{source_id, revision_ref}`

##### Indexes

An index entry MUST include:
- `id` (string)
- `type` (enum): `vector | keyword | graph | hybrid`
- `path` (string)
- `descriptor` (string): path to an index descriptor JSON

##### Summaries

A summary entry MUST include:
- `id` (string)
- `type` (enum): `overview | hierarchical | changelog | topic`
- `path` (string)

##### Provenance

If present, `provenance` MUST include:
- `chunks_path` (string): mapping from chunk IDs to source locations
- `build_info_path` (string): build metadata (tooling, parameters, hashes)

### 5.8 Logging configuration (optional)

`logs` MAY be provided to configure runtime logging behavior (see Section 9):

- `enabled` (boolean, default false): whether the runtime should write logs under `expert/logs/`
- `store_question` (boolean, default false): whether to store the raw question text in query logs (runtimes SHOULD store hashes even when raw text is disabled)
- `store_answer` (boolean, default false): whether to store the raw answer text in query logs (runtimes SHOULD store hashes even when raw text is disabled)
- `retention_days` (integer, optional): retention window for logs; if omitted, runtimes MAY fall back to `security.retention_days`

---

## 6. Standard artifacts

### 6.1 Index descriptor (`index.json`)

Each index entry's `descriptor` MUST point to a JSON file with:

Normative schema: `$id` `https://ecp.amcrypto.org/ecp/schemas/ecp-index-descriptor.schema.json` (also distributed as `spec/schemas/ecp-index-descriptor.schema.json`).

- `index_id` (string): must match the entry `id`
- `type` (string): must match the entry `type`
- `created_at` (RFC3339 string)
- `chunking` (object): `{method, max_chars, overlap_chars, language_hints}`
- `embedding` (object, optional): `{model, dimensions, provider, params}`
- `retrieval_defaults` (object): `{top_k, filters_supported}`
- `provenance` (object): pointers to chunk provenance mapping

If `type` is `vector`, `embedding` MUST be present and MUST include `model` and `dimensions` at minimum.

### 6.1.1 Baseline portable retrieval artifact (recommended): `keyword-index-v2`

ECP is intentionally flexible about retrieval/embedding implementations, but for practical interoperability ECP defines a **baseline portable retrieval artifact** that runtimes MAY implement: a filesystem-based keyword index called `keyword-index-v2`.

If a pack declares an index artifact of `type: keyword`, the corresponding index directory SHOULD contain:

- `index.json` (descriptor; Section 6.1)
- `index_data.json` (index payload; baseline format `keyword-index-v2`)
- `chunks.jsonl` (chunk provenance; Section 6.2)
- `build_info.json` (build metadata; optional but recommended)

#### 6.1.1.1 `index_data.json` (keyword-index-v2)

`index_data.json` MUST be a JSON object that includes at least:

Normative schema: `$id` `https://ecp.amcrypto.org/ecp/schemas/ecp-keyword-index.schema.json` (also distributed as `spec/schemas/ecp-keyword-index.schema.json`).

- `format`: MUST be `"keyword-index-v2"`
- `index_id` (string)
- `created_at` (RFC3339 string)
- `built_at` (RFC3339 string)
- `sources` (array): `{source_id, source_type, uri, revision, classification?, license?}`
- `config` (object): includes tokenizer + chunking parameters used to build the index
- `documents` (object): mapping from `chunk_id -> {source_id, path, start_line, end_line, file_sha256, chunk_sha256, ...}`
- `terms` (object): mapping from `token -> {df, postings}` where `postings` references `chunk_id`s

This format is designed to be **portable**: it MUST NOT embed absolute build-machine paths.

#### 6.1.1.2 Canonical tokenization (baseline)

To reduce fragmentation across implementations, `keyword-index-v2` defines a baseline tokenizer:

- Token regex: `[A-Za-z0-9_]+` (ASCII alphanumeric and underscore; this is intentionally ASCII-only for simplicity and cross-platform consistency)
- Lowercase normalization
- Stopword removal (implementation-defined list is allowed, but SHOULD be stable per index)
- Drop tokens with length `< 2`

Packs SHOULD record the tokenizer in `index_data.json.config.tokenizer`.

Implementations MAY additionally emit identifier-derived token variants (for example, splitting snake_case, CamelCase, or letter/digit boundaries) to improve code retrieval, but SHOULD retain the original whole-token form and MUST record the effective tokenizer in `index_data.json.config.tokenizer`.

### 6.1.2 Optional scalable retrieval artifact (informative): `sqlite-fts-index-v1`

The baseline `keyword-index-v2` format is intentionally simple and portable, but can become large for big corpora because `terms.postings` contains a full inverted index.
For scaling and faster query-time access, packs MAY instead (or in addition) provide a SQLite-backed FTS index with a lightweight JSON metadata header.

If a pack provides a `sqlite-fts-index-v1`, the corresponding index directory SHOULD contain:

- `index.json` (descriptor; Section 6.1)
- `index_data.json` (index metadata; format `sqlite-fts-index-v1`)
- `fts.sqlite` (SQLite database)
- `chunks.jsonl` (chunk provenance; Section 6.2)
- `file_manifest.json` (optional but recommended)
- `build_info.json` (optional but recommended)

`index_data.json` for `sqlite-fts-index-v1` MUST include at least:

Normative schema: `$id` `https://ecp.amcrypto.org/ecp/schemas/ecp-sqlite-fts-index.schema.json` (also distributed as `spec/schemas/ecp-sqlite-fts-index.schema.json`).

- `format`: MUST be `"sqlite-fts-index-v1"`
- `index_id`, `created_at`, `built_at`
- `sources` (array): `{source_id, source_type, uri, revision, classification?, license?}`
- `config` (object): includes tokenizer + chunking parameters used to build the index
- `sqlite` (object): `{path, table, fts5?}`

Runtimes that implement this format SHOULD support the same basic filters as `keyword-index-v2` (`source_id`, `path_prefix`) and SHOULD ensure `chunk_id` values match the canonical format in Section 6.2.1.

### 6.1.3 Baseline portable vector retrieval artifact (recommended): `vector-index-v1`

ECP does not standardize a specific embedding model, but for practical interoperability packs MAY provide a **portable vector index artifact**: a filesystem-based vector index called `vector-index-v1`.
This artifact enables semantic retrieval when the runtime can compute (or is provided) query embeddings that match the index's `embedding` configuration.

If a pack declares an index artifact of `type: vector`, the corresponding index directory SHOULD contain:

- `index.json` (descriptor; Section 6.1)
- `index_data.json` (index metadata; format `vector-index-v1`)
- a vector payload file referenced by `index_data.json.config.vector.vectors_path` (for example `vectors.jsonl` or `vectors.npy`/`vectors.bin`)
- `chunks.jsonl` (chunk provenance; Section 6.2)
- `file_manifest.json` (optional but recommended)
- `build_info.json` (optional but recommended)

#### 6.1.3.1 `index_data.json` (vector-index-v1)

`index_data.json` MUST be a JSON object that includes at least:

Normative schema: `$id` `https://ecp.amcrypto.org/ecp/schemas/ecp-vector-index.schema.json` (also distributed as `spec/schemas/ecp-vector-index.schema.json`).

- `format`: MUST be `"vector-index-v1"`
- `index_id`, `created_at`, `built_at`
- `sources` (array): `{source_id, source_type, uri, revision, classification?, license?}`
- `config` (object) including:
  - `chunking` (object): `{method, max_chars, overlap_chars, language_hints}`
  - `embedding` (object): `{model, dimensions, provider?, params?}`
  - `vector` (object): `{metric, vectors_path, vector_format, dtype?, endianness?, encoding?, chunk_id_order?}`
- `documents` (object): mapping from `chunk_id -> {source_id, path, start_line, end_line, file_sha256, chunk_sha256, ...}`

The `vector.metric` MUST be one of:
- `cosine` (recommended baseline)
- `dot` (allowed when embeddings are already normalized)

The `vector.vectors_path` MUST be a relative path under the index directory.

#### 6.1.3.2 `vectors.jsonl` (JSONL vector payload)

`vectors.jsonl` MUST be JSON Lines, one record per chunk:

- `chunk_id` (string)
- `vector` (dense or sparse representation)

Dense representation:
- `vector` is an array of numbers of length `embedding.dimensions`.

Sparse representation (recommended for portability):
- `vector` is an array of `[index, value]` pairs where `index` is an integer in `0..(embedding.dimensions-1)` and `value` is a number.
- Pairs MUST have unique indices. Pairs SHOULD be sorted by `index` ascending (for deterministic serialization and faster scoring).

For `metric: cosine`, implementations MUST L2-normalize vectors at build time and treat similarity as the dot product between normalized vectors. Runtimes MUST L2-normalize query vectors (or reject unnormalized query vectors) when using `metric: cosine`.

For portability, packs MUST set `config.vector.vector_format` to declare the encoding used in `vectors.jsonl` (dense array of numbers vs sparse `[index, value]` pairs).

#### 6.1.3.3 `vectors.bin` / `vectors.npy` (binary vector payloads; optional)

To reduce size and improve load performance for large corpora, a `vector-index-v1` pack MAY store vectors in a binary payload file (for example `vectors.bin` or `vectors.npy`) referenced by `config.vector.vectors_path`.

Binary payloads MUST:

- store a **dense** matrix of shape `(num_chunks, embedding.dimensions)` in **row-major** order (`config.vector.encoding: row-major`)
- define how rows map to chunks via `config.vector.chunk_id_order` (recommended baseline: `chunk_id_lex`, meaning rows are ordered by lexicographic sort of `chunk_id`)
- specify numeric representation via `config.vector.dtype` (`float32` or `float64`) and `config.vector.endianness` (`little` or `big`)

`vectors.bin`:
- MUST be a raw, headerless binary stream of `num_chunks * embedding.dimensions` values encoded per `{dtype, endianness}`.

`vectors.npy`:
- MUST be a NumPy `.npy` file containing a 2D array of shape `(num_chunks, embedding.dimensions)` with `fortran_order: false` and a dtype/endianness compatible with `{dtype, endianness}`.

For `metric: cosine`, the same normalization requirements apply as for JSONL payloads (L2-normalize at build time; query vectors MUST be normalized).

### 6.2 Chunk provenance map (`chunks.jsonl`)

Normative schema (per JSONL record): `$id` `https://ecp.amcrypto.org/ecp/schemas/ecp-chunk-provenance.schema.json` (also distributed as `spec/schemas/ecp-chunk-provenance.schema.json`).

If provenance is supported, `chunks.jsonl` SHOULD be provided as JSON Lines, one record per chunk:

- `chunk_id` (string)
- `source_id` (string)
- `uri` (string)
- `artifact_path` (string)
- `revision` (object)
- `loc` (object): e.g., `{start_line, end_line}` or `{byte_start, byte_end}`
- `chunk_hash` (string)
- `classification` (string, optional)
- `license` (string, optional)

#### 6.2.1 Chunk ID and path conventions (baseline)

For portable, cross-runtime chunk identity, `keyword-index-v2` uses a canonical chunk ID format:

```
<source_id>::<artifact_path>#L<start_line>-L<end_line>
```

Where:
- `artifact_path` MUST be a POSIX-style relative path under the cited source root (no leading `/`).
- `start_line` / `end_line` MUST be 1-based inclusive line numbers.

### 6.3 Query response contract (for expert runtimes)

Any ECP runtime that answers expert questions MUST return a response object that includes:

- `answer` (string)
- `as_of` (object): MUST describe the source state(s) the answer is based on. It MUST be either:
  - **Single-source form:** `{"source_id": "...", "revision": {...}}`
  - **Multi-source form:** `{"sources": [{"source_id": "...", "revision": {...}}, ...]}`
  - **Timestamp-only form (fallback):** `{"timestamp": "..."}` (SHOULD be avoided for reproducible packs)
- `citations` (array of Citation objects)

If the multi-source form is used, `as_of.sources[]` MUST include an entry for every `source_id` that may appear in `citations[]`.
If the pack declares multiple `sources[]`, runtimes SHOULD return the multi-source form.

A **Citation object** MUST include:
- `source_id`
- `source_type`
- `uri`
- `revision`
- `artifact_path` (if applicable)
- `chunk_id` (if applicable)
- `retrieved_at` (RFC3339 string)

Citation objects SHOULD include `loc` when citing a specific excerpt within a text artifact (see Section 6.3.1).

Citation objects MAY additionally include fields to support offline integrity checks and policy enforcement, such as:

- `chunk_hash` (string, optional): a content hash for the cited excerpt text (recommended: lowercase hex SHA-256 over the excerpt text with normalized `\n` newlines, encoded as UTF-8)
- `classification` (string, optional): security classification for the cited content (if applicable)
- `license` (string, optional): license identifier for the cited content (if applicable)

#### 6.3.1 `artifact_path` and `loc` semantics

When present, `artifact_path` MUST be a POSIX-style relative path that is interpreted as being **relative to the cited source root**:

- For `git` and `filesystem` sources, the source root is the repository/filesystem root resolved from `sources[].uri`.
- For `artifact` sources, the source root is the artifact root resolved from `sources[].uri` (commonly the skill root `.`).

When a citation refers to a specific excerpt within a text artifact, runtimes SHOULD include `loc` using line-based locations like `{start_line, end_line}`.

If a runtime includes `artifact_path` for a text artifact and can compute line ranges, it MUST include `loc.start_line` and `loc.end_line`.

#### 6.3.2 Derived artifact citations

Runtimes MAY cite derived artifacts (for example, `expert/context/summaries/*.md`) by using a `source_type` of `artifact` and a conventional `source_id` (for example, `ecp_artifacts`).
If a runtime cites a derived artifact, it MUST ensure the `as_of` object includes an entry for that `source_id`.
Packs MAY also declare an explicit `sources[]` entry of type `artifact` when the host treats artifact sources as first-class inputs (for example, for indexing).
If a runtime cites a derived artifact, it SHOULD (when feasible) also cite underlying primary sources for key claims.

Runtimes MAY include:
- `chunks` (array of Evidence Chunk objects): retrieved evidence snippets used to produce the answer.
- `synthesis` (object): metadata describing how `answer` was produced (recommended)
- `confidence` (0..1)
- `limitations` (string)
- `followups` (array)

If `chunks[]` is present:
- Each chunk MUST include:
  - `snippet` (string): the retrieved excerpt text
  - `citation` (Citation object)
- Each chunk MAY include:
  - `score` (number): retrieval score used for ranking
  - `path` (string): convenience duplicate of `citation.artifact_path`
  - `line_start`, `line_end` (integers): convenience duplicates of `citation.loc.start_line` / `citation.loc.end_line`
- `citations[]` SHOULD be the deduplicated set of `chunks[].citation` plus any additional citations the runtime chooses to provide.

#### 6.3.3 Synthesis metadata (recommended)

If `synthesis` is provided, it SHOULD include:

- `provider` (string): e.g., `local`, `openrouter`, `openai`, `anthropic`
- `model` (string, optional): provider model identifier, when applicable
- `method` (string, optional): e.g., `heuristic`, `llm`
- `max_evidence_chunks` (integer, optional): cap applied to `chunks[]` for synthesis

Runtimes SHOULD treat `chunks[]` + `citations[]` as the primary contract for downstream agents; `answer` is a convenience summary that MAY be regenerated by a host agent.

### 6.4 Citation coverage requirement

Every non-trivial expert answer MUST include at least **one** citation, and SHOULD include citations for each key claim.

### 6.5 Package manifest for distribution (optional but recommended): `expert/package.json`

When an ECP-enabled skill is distributed as an archive (e.g., ZIP), packagers MAY include a package manifest at:

```
expert/package.json
```

`expert/package.json` SHOULD include:
- `ecp_package_version` (string): format version for the package manifest (MUST be `"1.0"` for this specification)
- `created_at` (RFC3339 string)
- `skill_root_dir` (string): root directory name inside the archive
- `skill_name` (string)
- `ecp_version` (string)
- `excludes` (array): glob patterns excluded from the archive
- `files` (array): `{path, sha256, size?}` for every included file (paths relative to skill root)
- `package_sha256` (string): sha256 of the canonicalized `expert/package.json` content (with `package_sha256` omitted during hashing)
- `signatures` (array, optional): detached authenticity metadata for the package (see below)

#### 6.5.1 Package signatures (optional, informative)

Hash manifests detect tampering, but do not establish who produced a package. If `signatures[]` is present, runtimes MAY use it to verify authenticity in addition to file integrity.

Each `signatures[]` entry SHOULD include:
- `algorithm` (string): e.g., `ed25519`, `ecdsa-p256`
- `key_id` (string) or equivalent key identity metadata
- `signed_at` (RFC3339 string)
- `signature` (string): signature over `package_sha256` (or over canonicalized `expert/package.json` with `package_sha256` and `signatures` omitted)
- `public_key` / `certificate` / `issuer` metadata (optional; depends on the signing system)

If `security.contains_secrets: true`, a pack MUST NOT be distributed as an unencrypted archive, and runtimes SHOULD refuse to package it by default.

---

## 7. Maintenance policy: `expert/maintenance/policy.json`

### 7.1 Required fields

`policy.json` MUST be JSON and MUST contain:

Normative schema: `$id` `https://ecp.amcrypto.org/ecp/schemas/ecp-policy.schema.json` (also distributed as `spec/schemas/ecp-policy.schema.json`).

- `policy_version` (string): MUST be `"1.0"`
- `budgets` (object)
- `refresh_triggers` (array)
- `update_strategy` (object)
- `validation` (object)
- `publishing` (object)

### 7.2 Budgets

`budgets` MUST include at least one of:
- `max_update_duration_seconds` (integer)
- `max_update_cost_usd` (number)
- `max_tokens` (integer)
- `max_changed_files` (integer)

### 7.3 Refresh triggers

Each trigger entry MUST contain:
- `type` (enum): `schedule | event | manual`
- `spec` (string): cron expression, event name, etc.

### 7.4 Update strategy

`update_strategy` MUST include:
- `default` (enum): `incremental | rebuild`
- `incremental` (object)
- `rebuild` (object)
- `rebuild_thresholds` (object)

Example thresholds:
- `changed_files_gt`
- `changed_lines_gt`
- `days_since_full_rebuild_gt`

### 7.5 Validation and publishing

`validation` MUST include:
- `eval_suites` (array of suite IDs to run)
- `fail_action` (enum): `block | warn | rollback`

`publishing` MUST include:
- `on_pass` (enum): `auto_publish | require_approval`
- `rollback_on_fail` (boolean)

### 7.6 Retention (optional)

`policy.json` MAY include a `retention` object to constrain on-disk growth for generated artifacts (indexes, backups, logs).
Runtimes SHOULD implement retention as a safe, best-effort cleanup step (for example, only deleting files under `expert/context/**/.backup/` and `expert/logs/**`).

Common fields:
- `max_backups_per_index` (integer): keep at most N backup snapshots per index
- `max_backup_age_days` (integer): delete backup snapshots older than N days
- `prune_logs_after_days` (integer): delete log files older than N days

---

## 8. Evaluations: `expert/evals/*.yaml`

### 8.1 Suite format

An eval suite file MUST be YAML with:

The parsed YAML value MUST validate against the JSON Schema with `$id` `https://ecp.amcrypto.org/ecp/schemas/ecp-eval-suite.schema.json` (also distributed as `spec/schemas/ecp-eval-suite.schema.json`).

- `suite_id` (string)
- `suite_version` (string)
- `description` (string, optional)
- `cases` (array)

### 8.2 Case format

Each case MUST contain:

- `case_id` (string)
- `mode` (enum): `ephemeral | persistent | summarized`
- `question` (string)

Each case MAY include:
- `top_k` (integer): retrieval depth for this case
- `filters` (object): retrieval filters (for example, `{source_id, path_prefix}`)

Each case SHOULD contain at least one assertion in `assertions`, such as:

- `must_cite` (array): expected paths/modules/URIs that should appear in citations
- `must_not_cite` (array): paths/modules/URIs that must NOT appear in citations
- `must_cite_source_ids` (array): expected `source_id` values that must appear in `citations[]`
- `min_citations` (integer)
- `max_citations` (integer)
- `answer_must_include` (array of strings)
- `answer_must_not_include` (array of strings)
- `answer_must_match` (array of regex strings)
- `response_must_include_fields` (array of strings): required top-level fields that MUST be present in the query response object
- `as_of_must_include_source_ids` (array of strings): required `source_id` values that MUST appear in `response.as_of` (single-source or multi-source forms)
- `citations_must_resolve` (boolean): whether citations MUST resolve to real files/locations under their declared source roots
- `citations_must_match_snippets` (boolean): whether `chunks[].snippet` MUST exactly match the cited excerpt text
- `citations_must_match_hashes` (boolean): whether `citation.chunk_hash` MUST match a computed hash of `chunks[].snippet`

### 8.3 Assertion semantics

The assertions above are intentionally simple so they can run fully offline (for example, in conformance packs).

- `response_must_include_fields`: the response object MUST include each listed top-level key (for example, `answer`, `as_of`, `citations`, `chunks`, `synthesis`).
- `as_of_must_include_source_ids`: the response MUST use the single-source or multi-source `as_of` form (not timestamp-only fallback) and MUST include each expected `source_id`.
- `citations_must_resolve`: for each evidence item (prefer `chunks[].citation`, otherwise `citations[]`), `artifact_path` MUST resolve under the cited source root, MUST NOT escape the root, and MUST be within the source's declared `scope`; if `loc` is present, the line range MUST be valid for the target file. If a `git` source provides a commit in `citation.revision.commit`, resolvers MUST validate against that revision (and MUST NOT silently fall back to the working tree).
- `citations_must_match_snippets`: requires `chunks[]` with `snippet` plus `citation.artifact_path` and `citation.loc`; the excerpt text addressed by `loc` MUST exactly equal `snippet` after normalizing newlines to `\n`.
- `citations_must_match_hashes`: requires `chunks[]` and `citation.chunk_hash`; the runtime MUST compute a lowercase hex SHA-256 of the normalized `snippet` bytes (UTF-8) and compare it to `chunk_hash`.

---

## 9. Logging (optional but recommended)

If logging is enabled (for example, via `logs.enabled: true` in `EXPERT.yaml`), the runtime SHOULD write:

- `logs/updates/YYYY-MM-DD.jsonl` with update events
- `logs/queries/YYYY-MM-DD.jsonl` with query metadata (excluding sensitive prompts if prohibited)

Log entries SHOULD include:
- timestamp
- actor (service/user)
- operation
- inputs (redacted as required)
- outputs (hashes)
- eval results
- publish/rollback decision

Runtimes SHOULD support redacting or hashing sensitive fields by default (for example, storing `question_sha256` instead of `question` unless `logs.store_question: true` is set and allowed by `security.contains_secrets`).
If `logs.retention_days` (or `security.retention_days`) is set, runtimes SHOULD enforce retention by deleting old log files.

---

## 10. Optional MCP interface (recommended for interoperability)

ECP runtimes MAY expose their capabilities via Model Context Protocol (MCP) tools. This specification defines a conventional tool namespace prefix `expert.`.

Recommended MCP tools:

- `expert.query`
- `expert.refresh`
- `expert.run_evals`
- `expert.status`

### 10.1 Tool schemas (normative for ECP-MCP)

For **ECP-MCP** conformance (Section 11.3), the tool names and minimum input/output contracts below are **normative**.
Implementations MAY accept additional fields and MAY return additional output fields, but MUST support the required fields.

`expert.query` input:
- `question` (string)
- `mode` (string)
- `as_of` (object, optional)
- `filters` (object, optional)
- `query_vector` (array or object, optional): a caller-provided embedding to use for vector retrieval (allows runtimes to support vector indexes without bundling an embedder)
- `query_embedding` (object, optional): `{model, dimensions, provider?, params?}` describing `query_vector`

`expert.query` output:
- Response object as defined in Section 6.3

`expert.refresh` input (optional fields):
- `dry_run` (boolean)
- `rebuild` (boolean)
- `no_evals` (boolean)

`expert.run_evals` input (optional fields):
- `suite_id` (array of strings)

`expert.status` input:
- (empty object)

---

## 11. Conformance levels

### 11.1 ECP-Core (minimum)

An implementation is **ECP-Core conformant** if it:

1. Detects `expert/EXPERT.yaml`
2. Validates required fields
3. Loads `maintenance/policy.json`
4. Loads at least one eval suite
5. Provides an `expert.query` equivalent interface that returns `answer + citations + as_of`

### 11.2 ECP-Maintenance

Adds:
- incremental refresh support per `policy.json`
- eval-gated publishing/rollback

### 11.3 ECP-MCP

Adds:
- MCP tool exposure for query/refresh/evals/status

### 11.4 Conformance packs (recommended)

To support community interoperability without sharing sensitive data, ECP encourages publishing at least one **conformance pack**: a small, redistributable skill+source bundle with eval suites that validate:

- response shape (`answer`, `as_of`, `citations[]`, and optional `chunks[]`)
- citation integrity (paths + line ranges resolve; snippet hashes match)
- retrieval correctness for canonical questions (must cite expected files)

Conformance packs SHOULD avoid remote LLM dependencies and SHOULD be runnable fully offline.
For maximum portability, conformance packs SHOULD bundle their source corpus under the skill root (for example, under `expert/sources/` or `expert/context/snapshots/`) and reference it via `sources[].uri` as a relative path, so that `unzip -> query -> evals` works without additional checkouts.
For deterministic auditability, a conformance pack's `conformance` suite SHOULD include at least one case that enables `citations_must_resolve: true` and at least one of `citations_must_match_snippets: true` or `citations_must_match_hashes: true`.
Conformance packs MAY declare `profile: conformance` in `EXPERT.yaml` to opt into stricter, testable portability constraints intended for public distribution.

### 11.5 Profiles (optional)

Packs MAY declare a `profile` field in `EXPERT.yaml` to communicate intent and interoperability expectations (for example, `codebase`, `docs`, `web`, `mixed`, `conformance`). Profiles are normatively enforced in strict validation mode.

### 11.6 Profile Requirements (normative; strict validators)

If a pack declares a **string** `profile` in `EXPERT.yaml` and is validated in a mode that enforces profiles (for example, `ecpctl validate --strict`), it MUST satisfy the requirements below for that profile.
These requirements are intentionally limited to constraints that can be checked from the pack contents (manifest + referenced artifacts).

**Common safety rule (all profiles)**:

- Remote LLM synthesis MUST be disabled unless explicitly allowed by the pack:
  - If `security.allow_remote_llm` is `true`, `security.allowed_remote_llm_providers` MUST be a non-empty allowlist.
  - If `security.contains_secrets` is `true`, `security.allow_remote_llm` MUST be `false`.

**`conformance` profile**

- **Sources**
  - MUST include at least one `sources[]` entry with `type: filesystem` or `type: artifact`.
  - For `filesystem` sources, `sources[].uri` MUST be a relative path under the skill root and MUST NOT contain `..` path segments (conformance packs are intended to work as `unzip -> query -> evals`).
  - For `filesystem` sources, `sources[].revision` MUST include `hash` and `timestamp`.
- **Artifacts**
  - MUST declare at least one index in `context.artifacts.indexes[]`.
  - Each declared index MUST include an `index_data.json` payload and a `chunks.jsonl` provenance map (as referenced by the index descriptor's `provenance.index_data_path` and `provenance.chunks_path`).
- **Security**
  - `security.allow_remote_llm` MUST be `false` (conformance packs SHOULD be runnable fully offline).
- **Citations / provenance fields**
  - For any `chunks.jsonl` record whose `source_id` refers to a `filesystem` source, `revision.hash` and `revision.timestamp` MUST be present.

**`codebase` profile**

- **Sources**
  - MUST include at least one `sources[]` entry with `type: git` or `type: filesystem`.
  - For `git` sources, `sources[].revision` MUST include `commit` and `timestamp`, and `commit` MUST be a concrete commit hash (MUST NOT be `HEAD`).
  - For `filesystem` sources, `sources[].revision` MUST include `hash` and `timestamp`.
- **Artifacts**
  - MUST declare at least one index in `context.artifacts.indexes[]`.
  - Each declared index MUST include an `index_data.json` payload and a `chunks.jsonl` provenance map (as referenced by the index descriptor's `provenance.index_data_path` and `provenance.chunks_path`).
- **Citations / provenance fields**
  - For any `chunks.jsonl` record whose `source_id` refers to a `git` source, `revision.commit` and `revision.timestamp` MUST be present.
  - For any `chunks.jsonl` record whose `source_id` refers to a `filesystem` source, `revision.hash` and `revision.timestamp` MUST be present.

**`docs` profile**

- **Sources**
  - MUST include at least one `sources[]` entry with `type: filesystem`, `type: git`, or `type: web`.
  - For `git` sources, `sources[].revision` MUST include `commit` and `timestamp`.
  - For `filesystem` sources, `sources[].revision` MUST include `hash` and `timestamp`.
  - For `web` sources, `sources[].revision` MUST include `retrieved_at`.
- **Artifacts**
  - MUST declare at least one summary in `context.artifacts.summaries[]`.

**`web` profile**

- **Sources**
  - MUST include at least one `sources[]` entry with `type: web`.
  - For `web` sources, `sources[].revision` MUST include `retrieved_at`.
- **Artifacts**
  - MUST declare at least one snapshot in `context.artifacts.snapshots[]`.
  - MUST declare at least one index in `context.artifacts.indexes[]`.
  - Each declared index MUST include an `index_data.json` payload and a `chunks.jsonl` provenance map (as referenced by the index descriptor's `provenance.index_data_path` and `provenance.chunks_path`).
- **Citations / provenance fields**
  - For any `chunks.jsonl` record whose `source_id` refers to a `web` source, `revision.retrieved_at` MUST be present.

**`mixed` profile**

- **Sources**
  - MUST declare at least two `sources[]` entries.
  - For `git` sources, `sources[].revision` MUST include `commit` and `timestamp`.
  - For `filesystem` sources, `sources[].revision` MUST include `hash` and `timestamp`.
  - For `web` sources, `sources[].revision` MUST include `retrieved_at`.
- **Artifacts**
  - MUST declare at least one index in `context.artifacts.indexes[]`.
  - MUST declare at least one summary in `context.artifacts.summaries[]`.
  - Each declared index MUST include an `index_data.json` payload and a `chunks.jsonl` provenance map (as referenced by the index descriptor's `provenance.index_data_path` and `provenance.chunks_path`).

---

## 12. Example: Codebase Expert

### 12.1 Minimal `SKILL.md`

```markdown
---
name: codebase-expert
description: Answers questions about this repository's architecture and modules with file+commit citations. Use for navigation, ownership, and design questions.
compatibility: Requires git and local filesystem access to the repository.
allowed-tools: Read Grep Glob Bash(git:*)
---

# Codebase Expert

When active:
1. Prefer `expert.query` (ECP runtime) for architecture/module questions.
2. Provide answers with citations pointing to files and commits.
3. If citations are not available, say so and suggest how to obtain them.
```

### 12.2 Minimal `expert/EXPERT.yaml`

```yaml
ecp_version: "1.0"
id: codebase-expert
display_name: Codebase Expert
description: Repository-aware expert with incremental refresh via git diff.
skill:
  name: codebase-expert
security:
  classification: internal
  retention_days: 90
  contains_secrets: false
  contains_pii: possible
sources:
  - source_id: repo
    type: git
    uri: file:///ABS/PATH/TO/REPO
    scope:
      include: ["**/*"]
      exclude: ["**/.git/**", "**/node_modules/**", "**/dist/**", "**/build/**"]
    revision:
      commit: "0123456789abcdef0123456789abcdef01234567"
      timestamp: "2026-01-19T00:00:00Z"
    refresh:
      strategy: incremental
      incremental:
        method: git-diff
      rebuild:
        method: full-scan
context:
  strategy: hybrid
  artifacts:
    indexes:
      - id: code-vector-v1
        type: vector
        path: expert/context/indexes/code-vector-v1
        descriptor: expert/context/indexes/code-vector-v1/index.json
    summaries:
      - id: repo-overview
        type: overview
        path: expert/context/summaries/repo-overview.md
maintenance:
  policy_path: expert/maintenance/policy.json
  playbook_path: expert/maintenance/PLAYBOOK.md
evals:
  suites:
    - suite_id: smoke
      path: expert/evals/smoke.yaml
```

### 12.3 Minimal `expert/maintenance/policy.json`

```json
{
  "policy_version": "1.0",
  "budgets": {
    "max_update_duration_seconds": 600,
    "max_changed_files": 500
  },
  "refresh_triggers": [
    {"type": "manual", "spec": "on-demand"},
    {"type": "event", "spec": "git-push"}
  ],
  "update_strategy": {
    "default": "incremental",
    "incremental": {"method": "git-diff"},
    "rebuild": {"method": "full-scan"},
    "rebuild_thresholds": {
      "changed_files_gt": 500,
      "changed_lines_gt": 50000,
      "days_since_full_rebuild_gt": 30
    }
  },
  "validation": {
    "eval_suites": ["smoke"],
    "fail_action": "block"
  },
  "publishing": {
    "on_pass": "auto_publish",
    "rollback_on_fail": true
  }
}
```

### 12.4 Minimal `expert/evals/smoke.yaml`

```yaml
suite_id: smoke
suite_version: "1.0"
cases:
  - case_id: auth-modules
    mode: ephemeral
    question: "What modules handle authentication and where is the login flow implemented?"
    assertions:
      must_cite:
        - "auth"
        - "login"
      answer_must_include:
        - "authentication"
```

### 12.5 Minimal database `sources[]` entry (optional)

If your corpus is extracted from a database, declare a `database` source with a DSN-style `uri` (credentials omitted or injected out-of-band), a coarse `scope`, and a `revision` snapshot that captures *what* was extracted and *when*:

```yaml
- source_id: warehouse
  type: database
  uri: postgres://USER@HOST:5432/dbname
  scope:
    include: ["public.*"]
  revision:
    timestamp: "2026-01-19T00:00:00Z"
    query_hash: "sha256:0123456789abcdef..."
    row_count: 123456
  refresh:
    strategy: rebuild
    incremental:
      method: none
    rebuild:
      method: sql-export
      query: "SELECT * FROM public.users"
```

---

## 13. Change log

- v1.0 (2026-01-19): First public release. Consolidates and stabilizes all features from internal development.

---

## 14. References (informative)

- Agent Skills Specification: https://agentskills.io/specification
- Anthropic Engineering Blog (Agent Skills architecture): https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- Claude Docs (Agent Skills overview): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- Model Context Protocol Specification (2025-11-25): https://modelcontextprotocol.io/specification/2025-11-25
- AGENTS.md: https://agents.md/
- Linux Foundation AAIF Launch: https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation
