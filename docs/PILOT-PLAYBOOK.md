# Pilot Playbook - Create, validate, run, and publish ECP packs

This playbook is an operational, end-to-end guide for producing an **Expert Context Pack (ECP) v1.0** skill ("pack") using this repo's reference CLI (`ecpctl`): from **template creation** to **conformance**, **packaging**, **verification**, and **(optional) signing**.

If you get stuck, start with the **offline conformance pack** flow; it is designed to work with **no network** and **no external repo checkouts**.

---

## 0) Prerequisites

- Python **3.10+**
- `git` installed (recommended; required for `sources[].type: git` incremental refresh and for packaging some codebase packs)

Install the CLI from the repository root:

```bash
python -m pip install -e .
ecpctl --help
```

Or install from PyPI:

```bash
python -m pip install ecp-reference
ecpctl --help
```

If you prefer not to install, most commands also work as:

```bash
python -m ecp_reference.cli --help
```

---

## 1) Pick your pack type (choose one)

### A) Portable "conformance pack" (recommended for publishing)

Use this when you want `unzip -> query -> evals` to work for anyone without needing access to your private repo.

- `profile: conformance`
- `sources[].uri` is a **relative path inside the skill**, e.g. `expert/sources/repo`
- Evals run **offline** and validate response shape + citation integrity

### B) "Codebase pack" (internal / your team)

Use this when the pack points at a real repo checkout that recipients already have access to.

- `profile: codebase`
- `sources[].uri` usually points to a local checkout (often via `file:///...`)
- Publishing a ZIP is possible, but it typically won't be self-contained unless you also bundle a corpus

---

## 2) Create a new pack (skill template creation)

You can start by copying an existing example and editing a few fields.

### Option A: Start from the portable conformance template

Copy the template:

```bash
cp -R examples/ecp-conformance-pack /path/to/your-skill
```

PowerShell:

```powershell
Copy-Item -Recurse -Force examples/ecp-conformance-pack C:\path\to\your-skill
```

Then edit:

- `/path/to/your-skill/SKILL.md`
  - Update frontmatter: `name`, `description`, `license`, `allowed-tools`
- `/path/to/your-skill/expert/EXPERT.yaml`
  - Update `id`, `display_name`, `description`, `security.*` (especially `license`, `contains_secrets`, `contains_pii`)
  - Ensure sources point at an **in-skill** relative URI (e.g. keep `uri: expert/sources/repo`)
- `/path/to/your-skill/expert/sources/repo/`
  - Replace with your portable corpus (keep it small and redistributable)
- `/path/to/your-skill/expert/evals/*.yaml`
  - Update questions/expectations to match your bundled corpus

### Option B: Start from the codebase template

Copy the template:

```bash
cp -R examples/codebase-expert /path/to/your-skill
```

Point it at your repo checkout:

```bash
ecpctl set-source --skill /path/to/your-skill --source-id repo --uri file:///abs/path/to/your/repo
```

Windows file URIs typically look like `file:///C:/path/to/repo` (forward slashes).

If you want git-aware incremental refresh, set `sources[].type: git` in `expert/EXPERT.yaml` and ensure `git` is available. Running `ecpctl build`/`ecpctl refresh` records `sources[].revision.*` (including `revision.commit` for git sources).

Packaging note (codebase + git sources): `ecpctl pack` enforces commit pinning for `sources[].type: git` and will refuse to package if `sources[].revision.commit` is missing or set to `HEAD`. Fix by running `ecpctl refresh --skill ...` to record a concrete commit hash, then re-run `ecpctl pack`.

---

## 3) Validate early (schema + portability)

Validation should be your first "gate" before building artifacts.

```bash
ecpctl validate --skill /path/to/your-skill
```

For publishing, use strict validation (portability + provenance constraints):

```bash
ecpctl validate --strict --skill /path/to/your-skill
```

After you build, also validate the generated artifacts:

```bash
ecpctl validate --with-artifacts --skill /path/to/your-skill
```

Notes:
- `--with-artifacts` schema-checks index artifacts referenced from `expert/EXPERT.yaml`.
- Use `--max-chunks 0` if you want to validate every `chunks.jsonl` record (slower).

---

## 4) Build artifacts (`build`)

Build creates/updates artifacts under `expert/context/` and records `sources[].revision` in `expert/EXPERT.yaml`.

```bash
ecpctl build --skill /path/to/your-skill
```

Common flags:

- Preview what would happen (no file modifications): `ecpctl build --dry-run --skill ...`
- Force a full rebuild: `ecpctl build --rebuild --skill ...`
- Skip eval gating (not recommended for publishing): `ecpctl build --no-evals --skill ...`

---

## 5) Query the pack (`query`)

```bash
ecpctl query --skill /path/to/your-skill "Where is authentication implemented?"
```

Useful options:

- Machine output: `--json`
- Restrict retrieval: `--source-id <id>` and/or `--path-prefix <prefix>` (repeatable)
- Modes:
  - `--mode ephemeral` (default): answer without writing interaction logs
  - `--mode persistent`: may write Q/A logs depending on `logs.*` and `security.*`
  - `--mode summarized`: may cite derived summaries (see `expert/context/summaries/*`)

Remote LLM synthesis is optional (`--llm openrouter`) and is gated by `expert/EXPERT.yaml`:

- Blocked when `security.contains_secrets: true`
- Disabled unless `security.allow_remote_llm: true` (and provider allowlist if configured)
- Requires `OPENROUTER_API_KEY` in your environment; `ecpctl` auto-loads a local `.env` file from the current directory (avoid committing it).

---

## 6) Refresh safely (`refresh`) + rollback behavior

Refresh updates artifacts incrementally when possible (git diff or file-manifest diff), then runs eval suites.

```bash
ecpctl refresh --dry-run --skill /path/to/your-skill
ecpctl refresh --skill /path/to/your-skill
```

By default, `build`/`refresh` run the suite IDs listed in `expert/maintenance/policy.json` under `validation.eval_suites` (the suite definitions themselves live under `evals.suites` in `expert/EXPERT.yaml`).

If evals fail, the result depends on `expert/maintenance/policy.json`:

- `validation.fail_action: rollback` -> restore the previous state automatically
- `validation.fail_action: block` -> fail the command; rollback may still occur if `publishing.rollback_on_fail: true`
- `validation.fail_action: warn` -> keep changes even if evals fail

Where rollback comes from:

- Per-index backups are stored under `expert/context/indexes/<index_id>/.backup/` (files like `index_data.<timestamp>.json`, `chunks.<timestamp>.jsonl`, etc).
- Update logs (when enabled) are appended to `expert/logs/updates/<YYYY-MM-DD>.jsonl` and include whether a rollback occurred.

To force a full rebuild during refresh:

```bash
ecpctl refresh --rebuild --skill /path/to/your-skill
```

---

## 7) Evals (`run-evals`), interpreting failures, and fixing them

Run the suites declared in `expert/EXPERT.yaml`:

```bash
ecpctl run-evals --skill /path/to/your-skill
```

Run specific suites (repeat `--suite-id`):

```bash
ecpctl run-evals --skill /path/to/your-skill --suite-id smoke
ecpctl run-evals --skill /path/to/your-skill --suite-id conformance
```

### How to interpret common failures

- **`citations_must_resolve` fails**: citations point to missing files/paths (often caused by changing `sources[].scope`, moving files, or using non-portable absolute paths in a packaged corpus).
- **`citations_must_match_snippets` / `citations_must_match_hashes` fails**: the cited file content changed since the index/summaries were built; run `ecpctl refresh --skill ...` (or `--rebuild`) and re-run evals.
- **`must_cite` fails**: retrieval didn't surface the expected file(s); either the corpus changed, the question is too vague, or the `must_cite` expectation needs updating.

### A minimal eval authoring pattern (portable/offline)

For publishable conformance packs, keep evals offline and deterministic:

- Include at least one case with:
  - `citations_must_resolve: true`
  - and at least one of `citations_must_match_hashes: true` or `citations_must_match_snippets: true`
- Prefer questions that reliably retrieve a stable file in your bundled corpus (e.g., `README.md`, a known module file, or a short "fixture" file you control)

If you're creating a brand-new portable pack, the fastest route is to copy and adapt:

- `examples/ecp-conformance-pack/expert/evals/smoke.yaml`
- `examples/ecp-conformance-pack/expert/evals/conformance.yaml`

---

## 8) Package + verify (`pack`, `verify-pack`)

### Pre-flight checklist (recommended before publishing)

```bash
ecpctl validate --strict --with-artifacts --skill /path/to/your-skill
ecpctl run-evals --skill /path/to/your-skill --suite-id smoke --suite-id conformance
```

### Create the ZIP

```bash
ecpctl pack --skill /path/to/your-skill --out your-skill.zip
```

Defaults:
- Excludes `expert/logs/**` and `**/.backup/**` and common junk (`**/.git/**`, `**/.env`, etc).
- Produces a deterministic ZIP by default (stable timestamps), which is useful for reproducible publishing.

Options:
- Include logs: `--include-logs`
- Include backups: `--include-backups`
- Do not force deterministic timestamps: `--non-deterministic`

Safety:
- `ecpctl pack` refuses when `security.contains_secrets: true` unless you pass `--allow-secrets` (strongly discouraged for public distribution).

### Verify the ZIP

```bash
ecpctl verify-pack --package your-skill.zip
```

What verification does:
- Confirms file hashes listed in `expert/package.json` match the ZIP contents.
- Optionally extracts and schema-validates the skill (`--no-validate` skips the schema validation step).

---

## 9) Signing (optional, recommended for public publishing)

`ecpctl verify-pack` verifies **integrity**, not **authorship**. If you publish packs publicly, also publish a signature.

Recommended workflow (detached signature):

1) Create the ZIP with deterministic settings (default).
2) Compute the ZIP SHA256.
3) Sign that hash (or the whole blob) with a tool like Sigstore Cosign or GPG.
4) Publish: `your-skill.zip` + signature + public key / certificate information.

Examples:

- Cosign (detached signature over the ZIP blob):
  - `cosign sign-blob --output-signature your-skill.zip.sig your-skill.zip`
  - Verify: `cosign verify-blob --signature your-skill.zip.sig --certificate-identity ... --certificate-oidc-issuer ... your-skill.zip`

- GPG (detached signature):
  - `gpg --detach-sign --armor your-skill.zip`
  - Verify: `gpg --verify your-skill.zip.asc your-skill.zip`

Spec note: ECP v1.0 supports optional `signatures[]` metadata in `expert/package.json` (see `spec/ECP-SPEC.md`). The reference CLI verifies integrity but does not manage signature metadata; use detached signatures when publishing.

---

## 10) Security do's / don'ts

**Do**
- Set `security.contains_secrets` honestly; leave `security.allow_remote_llm: false` unless you explicitly want remote synthesis.
- Use `sources[].scope.exclude` to prevent accidental inclusion of secrets (`.env`, keys, credential files, build outputs).
- Prefer **portable relative paths** in `sources[].uri` for packs you intend to publish.
- Keep conformance packs' corpora small and license-clean; set `security.license` appropriately.

**Don't**
- Don't enable remote LLMs on sensitive repos (even if your tool supports it); remote calls send evidence snippets off-machine.
- Don't publish packs that require access to proprietary repos unless recipients are authorized (a ZIP of the skill directory does not automatically include the repo content).
- Don't rely on eval-less updates for long-lived packs; use eval gating + rollback to keep quality stable.

---

## 11) Publish checklist (copy/paste)

For a publishable, portable pack:

```bash
SKILL=/path/to/your-skill

ecpctl validate --strict --skill "$SKILL"
ecpctl build --skill "$SKILL"
ecpctl run-evals --skill "$SKILL" --suite-id smoke --suite-id conformance
ecpctl validate --strict --with-artifacts --skill "$SKILL"

ecpctl pack --skill "$SKILL" --out "$(basename "$SKILL").zip"
ecpctl verify-pack --package "$(basename "$SKILL").zip"
```
