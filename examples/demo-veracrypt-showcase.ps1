# =============================================================================
# ECP v1.0 Showcase Demo — VeraCrypt Expert (PowerShell)
# =============================================================================
# A polished demo script for video recording and live presentations.
# Demonstrates: build -> query -> citations -> evals -> refresh -> packaging
#
# Prerequisites:
#   git clone https://github.com/veracrypt/VeraCrypt examples/VeraCrypt
#   pip install -e .
#
# Usage:
#   .\examples\demo-veracrypt-showcase.ps1           # Interactive (pauses)
#   .\examples\demo-veracrypt-showcase.ps1 -Fast    # No pauses (CI/testing)
#
# =============================================================================
param(
    [switch]$Fast
)

$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
$skill = "examples/veracrypt-expert-hybrid-vector"
$fallbackSkill = "examples/veracrypt-expert"
$repo = "examples/VeraCrypt"
$outDir = "demo-output"

# Interactive mode
$interactive = -not $Fast

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
function Write-Banner {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host ">> $Text" -ForegroundColor Blue
    Write-Host ("-" * 70) -ForegroundColor Blue
}

function Write-Info {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Text)
    Write-Host "[!] $Text" -ForegroundColor Yellow
}

function Invoke-Pause {
    if ($interactive) {
        Write-Host ""
        Write-Host "Press Enter to continue..." -ForegroundColor Yellow
        Read-Host | Out-Null
    }
}

function Invoke-Cmd {
    param([string]$Command)
    Write-Host "$ $Command" -ForegroundColor Cyan
    Invoke-Expression $Command
}

# -----------------------------------------------------------------------------
# Preflight checks
# -----------------------------------------------------------------------------
Write-Banner "ECP v1.0 Demo - Expert Context Packs for AI Agents"

Write-Section "Preflight Checks"

if (-not (Test-Path $repo)) {
    Write-Host "ERROR: Missing $repo" -ForegroundColor Red
    Write-Host "Clone VeraCrypt first:"
    Write-Host "  git clone https://github.com/veracrypt/VeraCrypt $repo"
    exit 1
}
Write-Info "VeraCrypt repository found at $repo"

# Check SQLite FTS5 availability
$fts5Available = $true
try {
    python -c "import sqlite3; c=sqlite3.connect(':memory:'); c.execute('CREATE VIRTUAL TABLE t USING fts5(x);'); c.close()" 2>$null
    if ($LASTEXITCODE -ne 0) { $fts5Available = $false }
} catch {
    $fts5Available = $false
}

if ($fts5Available) {
    Write-Info "SQLite FTS5 available - using optimized backend"
} else {
    Write-Warning "SQLite FTS5 not available - falling back to JSON keyword index"
    $skill = $fallbackSkill
}

# Count files
$fileCount = (Get-ChildItem -Path "$repo/src" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Info "VeraCrypt source contains ~$fileCount files"

New-Item -ItemType Directory -Force $outDir | Out-Null
$env:PYTHONPATH = "src"

Invoke-Pause

# =============================================================================
# PART 1: Build Expert Context
# =============================================================================
Write-Banner "PART 1: Building Expert Context"

Write-Section "1.1 Validate Skill Configuration"
Write-Host "ECP skills are self-describing via EXPERT.yaml manifest."
Write-Host ""
Invoke-Cmd "ecpctl validate --skill $skill"

Invoke-Pause

Write-Section "1.2 Build the Index"
Write-Host "Indexing ~$fileCount source files with chunking + tokenization..."
Write-Host ""
Invoke-Cmd "ecpctl build --skill $skill"

Invoke-Pause

Write-Section "1.3 View Build Statistics"
Write-Host "The build creates: index.json, chunks.jsonl, fts.sqlite (or index_data.json)"
Write-Host ""
Invoke-Cmd "ecpctl status --skill $skill"

Invoke-Pause

# =============================================================================
# PART 2: Query with Grounded Citations
# =============================================================================
Write-Banner "PART 2: Query with Grounded Citations"

Write-Section "2.1 Simple Query - License Location"
Write-Host "Every answer includes citations with file path + line numbers."
Write-Host ""
Invoke-Cmd "ecpctl query --skill $skill 'Where are the license terms located?'"

Invoke-Pause

Write-Section "2.2 Technical Query - Crypto Implementation"
Write-Host "Domain-specific queries retrieve relevant code snippets."
Write-Host ""
Invoke-Cmd "ecpctl query --skill $skill 'Where is Argon2 key derivation implemented?'"

Invoke-Pause

Write-Section "2.3 Vector Query - External query_vector"
Write-Host "Hybrid retrieval can accept a caller-provided query embedding (query_vector)."
Write-Host ""
if ($skill -eq "examples/veracrypt-expert-hybrid-vector") {
    $qvec = Join-Path $outDir "query_vector.json"
    python -c "import json; from ecp_reference.vectors import hash_embed; print(json.dumps(hash_embed('Where is Argon2 key derivation implemented?', dims=256, salt='veracrypt-hash-embed-v1', include_char_ngrams=True, char_ngram=3, char_ngram_weight=0.5), ensure_ascii=False))" | Out-File -Encoding utf8 $qvec
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate query_vector.json (python exited with code $LASTEXITCODE)"
    }
    if (-not (Test-Path $qvec) -or (Get-Item $qvec).Length -eq 0) {
        throw "Failed to generate query_vector.json (file is empty): $qvec"
    }
    Invoke-Cmd "ecpctl query --skill $skill --query-vector-file $qvec 'Where is Argon2 key derivation implemented?'"
} else {
    Write-Warning "Vector demo skipped (fallback skill selected)."
}

Invoke-Pause

Write-Section "2.4 JSON Output with Full Citations"
Write-Host "Machine-readable output for agent integration:"
Write-Host ""
$result = ecpctl query --json --skill $skill "What encryption algorithms are supported?"
$result | ConvertFrom-Json | ConvertTo-Json -Depth 5 | Select-Object -First 80

Invoke-Pause

Write-Section "2.5 Citation Provenance"
Write-Host "Each citation includes:"
Write-Host "  - source_id: which source the file came from"
Write-Host "  - artifact_path: relative path within the source"
Write-Host "  - loc.start_line / loc.end_line: exact line range"
Write-Host "  - chunk_sha256: content hash for verification"
Write-Host ""
$queryResult = ecpctl query --json --skill $skill "Where is AES implemented?" | ConvertFrom-Json
Write-Host "Citations found: $($queryResult.citations.Count)"
$queryResult.citations | Select-Object -First 3 | ForEach-Object {
    $path = $_.artifact_path
    $start = $_.loc.start_line
    $end = $_.loc.end_line
    Write-Host "  - ${path}:${start}-${end}"
}

Invoke-Pause

# =============================================================================
# PART 3: Optional LLM Synthesis
# =============================================================================
Write-Banner "PART 3: LLM-Synthesized Answers (Optional)"

Write-Section "3.1 Local vs Remote Synthesis"
Write-Host "By default, ECP uses a local heuristic summarizer (no API calls)."
Write-Host "With --llm openrouter, evidence is sent to an LLM for synthesis."
Write-Host ""

$hasOpenRouterKey = $false
if (Test-Path ".env") {
    $hasOpenRouterKey = Select-String -Path ".env" -Pattern '^\s*(export\s+)?OPENROUTER_API_KEY\s*=' -Quiet
}

if ($hasOpenRouterKey) {
    Write-Info "OpenRouter API key detected in .env"
    Write-Host ""
    Invoke-Cmd "ecpctl query --llm openrouter --skill $skill 'Summarize the main components involved in mounting an encrypted volume.'"
} else {
    Write-Warning "No OPENROUTER_API_KEY in .env - skipping LLM synthesis demo"
    Write-Host "To enable: Add-Content .env 'OPENROUTER_API_KEY=your-key'"
}

Invoke-Pause

# =============================================================================
# PART 4: Evaluation Suites
# =============================================================================
Write-Banner "PART 4: Evaluation-Gated Quality Assurance"

Write-Section "4.1 Smoke Tests"
Write-Host "Smoke suite validates that queries return expected citations."
Write-Host ""
Invoke-Cmd "ecpctl run-evals --skill $skill --suite-id smoke"

Invoke-Pause

Write-Section "4.2 Conformance Tests"
Write-Host "Conformance suite validates response shape and citation integrity."
Write-Host "Tests: citations_must_resolve, citations_must_match_hashes"
Write-Host ""
Invoke-Cmd "ecpctl run-evals --skill $skill --suite-id conformance"

Invoke-Pause

# =============================================================================
# PART 5: Incremental Refresh
# =============================================================================
Write-Banner "PART 5: Incremental Maintenance"

Write-Section "5.1 Dry-Run Refresh"
Write-Host "ECP detects changes via git-diff and shows what would be updated."
Write-Host ""
Invoke-Cmd "ecpctl refresh --dry-run --skill $skill"

Invoke-Pause

Write-Section "5.2 Policy-Driven Updates"
Write-Host "Maintenance policy (policy.json) controls:"
Write-Host "  - Budgets: max duration, max changed files"
Write-Host "  - Triggers: manual, scheduled, git-push event"
Write-Host "  - Validation: which eval suites must pass"
Write-Host "  - Rollback: automatic revert on eval failure"
Write-Host ""
Get-Content "$skill/expert/maintenance/policy.json" | ConvertFrom-Json | ConvertTo-Json -Depth 3 | Select-Object -First 30

Invoke-Pause

# =============================================================================
# PART 6: Packaging & Distribution
# =============================================================================
Write-Banner "PART 6: Packaging for Distribution"

$zipPath = Join-Path $outDir "$(Split-Path $skill -Leaf).zip"

Write-Section "6.1 Create Package"
Write-Host "Package includes all artifacts with SHA256 manifest."
Write-Host ""
Invoke-Cmd "ecpctl pack --skill $skill --out $zipPath"

Invoke-Pause

Write-Section "6.2 Verify Package Integrity"
Write-Host "Recipients can verify file hashes before use."
Write-Host ""
Invoke-Cmd "ecpctl verify-pack --package $zipPath"

Invoke-Pause

# =============================================================================
# Summary
# =============================================================================
Write-Banner "Demo Complete!"

Write-Host "Key Takeaways:" -ForegroundColor Green
Write-Host ""
Write-Host "  1. Persistent Context - Index once, query many times" -ForegroundColor White
Write-Host "  2. Grounded Citations - Every answer traceable to file:line:hash" -ForegroundColor White
Write-Host "  3. Incremental Updates - Git-aware refresh in seconds" -ForegroundColor White
Write-Host "  4. Eval-Gated Quality - Bad updates auto-rollback" -ForegroundColor White
Write-Host "  5. Portable Packages - Share experts as verified ZIPs" -ForegroundColor White
Write-Host ""
Write-Host "Learn more: spec/ECP-SPEC.md" -ForegroundColor Cyan
Write-Host ""
