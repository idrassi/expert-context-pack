#!/usr/bin/env bash
# =============================================================================
# ECP v1.0 Showcase Demo — VeraCrypt Expert
# =============================================================================
# A polished demo script for video recording and live presentations.
# Demonstrates: build → query → citations → evals → refresh → packaging
#
# Prerequisites:
#   git clone https://github.com/veracrypt/VeraCrypt examples/VeraCrypt
#   pip install -e .
#
# Usage:
#   ./examples/demo-veracrypt-showcase.sh           # Interactive (pauses)
#   ./examples/demo-veracrypt-showcase.sh --fast    # No pauses (CI/testing)
#
# =============================================================================
set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
SKILL="examples/veracrypt-expert-hybrid-vector"
FALLBACK_SKILL="examples/veracrypt-expert"
REPO="examples/VeraCrypt"
OUT_DIR="demo-output"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Interactive mode (pause between sections)
INTERACTIVE=true
if [[ "${1:-}" == "--fast" ]]; then
  INTERACTIVE=false
fi

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
banner() {
  echo ""
  echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
  echo ""
}

section() {
  echo ""
  echo -e "${BOLD}${BLUE}▶ $1${NC}"
  echo -e "${BLUE}───────────────────────────────────────────────────────────────────${NC}"
}

info() {
  echo -e "${GREEN}✓${NC} $1"
}

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

pause() {
  if $INTERACTIVE; then
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
  fi
}

run_cmd() {
  echo -e "${CYAN}\$ $1${NC}"
  eval "$1"
}

# -----------------------------------------------------------------------------
# Preflight checks
# -----------------------------------------------------------------------------
banner "ECP v1.0 Demo — Expert Context Packs for AI Agents"

section "Preflight Checks"

if [[ ! -d "${REPO}" ]]; then
  echo -e "${RED}ERROR: Missing ${REPO}${NC}"
  echo "Clone VeraCrypt first:"
  echo "  git clone https://github.com/veracrypt/VeraCrypt ${REPO}"
  exit 1
fi
info "VeraCrypt repository found at ${REPO}"

# Check SQLite FTS5 availability
if python - <<'PY' 2>/dev/null
import sqlite3
c = sqlite3.connect(":memory:")
c.execute("CREATE VIRTUAL TABLE t USING fts5(x);")
c.close()
PY
then
  info "SQLite FTS5 available — using optimized backend"
else
  warn "SQLite FTS5 not available — falling back to JSON keyword index"
  SKILL="${FALLBACK_SKILL}"
fi

# Count files in VeraCrypt
FILE_COUNT=$(find "${REPO}/src" -type f 2>/dev/null | wc -l | tr -d ' ')
info "VeraCrypt source contains ~${FILE_COUNT} files"

mkdir -p "${OUT_DIR}"
export PYTHONPATH="src"

pause

# =============================================================================
# PART 1: Build Expert Context
# =============================================================================
banner "PART 1: Building Expert Context"

section "1.1 Validate Skill Configuration"
echo "ECP skills are self-describing via EXPERT.yaml manifest."
echo ""
run_cmd "ecpctl validate --skill ${SKILL}"

pause

section "1.2 Build the Index"
echo "Indexing ~${FILE_COUNT} source files with chunking + tokenization..."
echo ""
run_cmd "ecpctl build --skill ${SKILL}"

pause

section "1.3 View Build Statistics"
echo "The build creates: index.json, chunks.jsonl, fts.sqlite (or index_data.json)"
echo ""
run_cmd "ecpctl status --skill ${SKILL}"

pause

# =============================================================================
# PART 2: Query with Grounded Citations
# =============================================================================
banner "PART 2: Query with Grounded Citations"

section "2.1 Simple Query — License Location"
echo "Every answer includes citations with file path + line numbers."
echo ""
run_cmd "ecpctl query --skill ${SKILL} 'Where are the license terms located?'"

pause

section "2.2 Technical Query — Crypto Implementation"
echo "Domain-specific queries retrieve relevant code snippets."
echo ""
run_cmd "ecpctl query --skill ${SKILL} 'Where is Argon2 key derivation implemented?'"

pause

section "2.3 Vector Query - External query_vector"
echo "Hybrid retrieval can accept a caller-provided query embedding (query_vector)."
echo ""
if [[ "${SKILL}" == "examples/veracrypt-expert-hybrid-vector" ]]; then
  qvec_file="${OUT_DIR}/query_vector.json"
  python -c "import json; from ecp_poc.vectors import hash_embed; print(json.dumps(hash_embed('Where is Argon2 key derivation implemented?', dims=256, salt='veracrypt-hash-embed-v1', include_char_ngrams=True, char_ngram=3, char_ngram_weight=0.5), ensure_ascii=False))" > "${qvec_file}"
  run_cmd "ecpctl query --skill ${SKILL} --query-vector-file '${qvec_file}' 'Where is Argon2 key derivation implemented?'"
else
  warn "Vector demo skipped (fallback skill selected)."
fi

pause

section "2.4 JSON Output with Full Citations"
echo "Machine-readable output for agent integration:"
echo ""
run_cmd "ecpctl query --json --skill ${SKILL} 'What encryption algorithms are supported?' | python -m json.tool | head -80"

pause

section "2.5 Citation Provenance"
echo "Each citation includes:"
echo "  • source_id: which source the file came from"
echo "  • artifact_path: relative path within the source"
echo "  • loc.start_line / loc.end_line: exact line range"
echo "  • chunk_sha256: content hash for verification"
echo ""
run_cmd "ecpctl query --json --skill ${SKILL} 'Where is AES implemented?' | python -c \"
import json, sys
data = json.load(sys.stdin)
print('Citations found:', len(data.get('citations', [])))
for c in data.get('citations', [])[:3]:
    print(f\\\"  - {c.get('artifact_path')}:{c.get('loc',{}).get('start_line')}-{c.get('loc',{}).get('end_line')}\\\")
\""

pause

# =============================================================================
# PART 3: Optional LLM Synthesis
# =============================================================================
banner "PART 3: LLM-Synthesized Answers (Optional)"

section "3.1 Local vs Remote Synthesis"
echo "By default, ECP uses a local heuristic summarizer (no API calls)."
echo "With --llm openrouter, evidence is sent to an LLM for synthesis."
echo ""

if [[ -f ".env" ]] && grep -Eq '^[[:space:]]*(export[[:space:]]+)?OPENROUTER_API_KEY[[:space:]]*=' ".env"; then
  info "OpenRouter API key detected in .env"
  echo ""
  run_cmd "ecpctl query --llm openrouter --skill ${SKILL} 'Summarize the main components involved in mounting an encrypted volume.'"
else
  warn "No OPENROUTER_API_KEY in .env — skipping LLM synthesis demo"
  echo "To enable: echo 'OPENROUTER_API_KEY=your-key' >> .env"
fi

pause

# =============================================================================
# PART 4: Evaluation Suites
# =============================================================================
banner "PART 4: Evaluation-Gated Quality Assurance"

section "4.1 Smoke Tests"
echo "Smoke suite validates that queries return expected citations."
echo ""
run_cmd "ecpctl run-evals --skill ${SKILL} --suite-id smoke"

pause

section "4.2 Conformance Tests"
echo "Conformance suite validates response shape and citation integrity."
echo "Tests: citations_must_resolve, citations_must_match_hashes"
echo ""
run_cmd "ecpctl run-evals --skill ${SKILL} --suite-id conformance"

pause

# =============================================================================
# PART 5: Incremental Refresh
# =============================================================================
banner "PART 5: Incremental Maintenance"

section "5.1 Dry-Run Refresh"
echo "ECP detects changes via git-diff and shows what would be updated."
echo ""
run_cmd "ecpctl refresh --dry-run --skill ${SKILL}"

pause

section "5.2 Policy-Driven Updates"
echo "Maintenance policy (policy.json) controls:"
echo "  • Budgets: max duration, max changed files"
echo "  • Triggers: manual, scheduled, git-push event"
echo "  • Validation: which eval suites must pass"
echo "  • Rollback: automatic revert on eval failure"
echo ""
run_cmd "cat ${SKILL}/expert/maintenance/policy.json | python -m json.tool | head -30"

pause

# =============================================================================
# PART 6: Packaging & Distribution
# =============================================================================
banner "PART 6: Packaging for Distribution"

ZIP_PATH="${OUT_DIR}/$(basename "${SKILL}").zip"

section "6.1 Create Package"
echo "Package includes all artifacts with SHA256 manifest."
echo ""
run_cmd "ecpctl pack --skill ${SKILL} --out ${ZIP_PATH}"

pause

section "6.2 Verify Package Integrity"
echo "Recipients can verify file hashes before use."
echo ""
run_cmd "ecpctl verify-pack --package ${ZIP_PATH}"

pause

# =============================================================================
# Summary
# =============================================================================
banner "Demo Complete!"

echo -e "${GREEN}Key Takeaways:${NC}"
echo ""
echo "  1. ${BOLD}Persistent Context${NC} — Index once, query many times"
echo "  2. ${BOLD}Grounded Citations${NC} — Every answer traceable to file:line:hash"
echo "  3. ${BOLD}Incremental Updates${NC} — Git-aware refresh in seconds"
echo "  4. ${BOLD}Eval-Gated Quality${NC} — Bad updates auto-rollback"
echo "  5. ${BOLD}Portable Packages${NC} — Share experts as verified ZIPs"
echo ""
echo -e "${CYAN}Learn more: spec/ECP-SPEC.md${NC}"
echo ""
