$ErrorActionPreference = "Stop"

$skill = "examples/veracrypt-expert-hybrid-vector"
$fallbackSkill = "examples/veracrypt-expert"
$repo = "examples/VeraCrypt"
$outDir = "demo-output"
$zip = Join-Path $outDir "veracrypt-expert-hybrid-vector.zip"

if (-not (Test-Path $repo)) {
  throw "Missing $repo. Clone VeraCrypt first: git clone https://github.com/veracrypt/VeraCrypt $repo"
}

New-Item -ItemType Directory -Force $outDir | Out-Null

$env:PYTHONPATH = "src"

# If SQLite FTS5 isn't available in the current Python environment, fall back to
# the JSON keyword index demo.
python -c "import sqlite3; c=sqlite3.connect(':memory:'); c.execute('CREATE VIRTUAL TABLE t USING fts5(x);'); c.close()" | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "SQLite FTS5 not available; falling back to $fallbackSkill"
  $skill = $fallbackSkill
  $zip = Join-Path $outDir "veracrypt-expert.zip"
}

python -m ecp_reference.cli validate --skill $skill
python -m ecp_reference.cli build --skill $skill
python -m ecp_reference.cli validate --with-artifacts --skill $skill --json | Out-Host
python -m ecp_reference.cli query --skill $skill --source-id repo "Where are the license terms located?"
python -m ecp_reference.cli query --skill $skill --source-id repo "Where is Argon2 implemented?"
if ($skill -eq "examples/veracrypt-expert-hybrid-vector") {
  $qvec = Join-Path $outDir "query_vector.json"
  python -c "import json; from ecp_reference.vectors import hash_embed; print(json.dumps(hash_embed('Where is Argon2 implemented?', dims=256, salt='veracrypt-hash-embed-v1', include_char_ngrams=True, char_ngram=3, char_ngram_weight=0.5), ensure_ascii=False))" | Out-File -Encoding utf8 $qvec
  python -m ecp_reference.cli query --skill $skill --query-vector-file $qvec --source-id repo "Where is Argon2 implemented?"
}
$hasOpenRouterKey = $false
if (Test-Path ".env") {
  $hasOpenRouterKey = Select-String -Path ".env" -Pattern '^\s*(export\s+)?OPENROUTER_API_KEY\s*=' -Quiet
}
if ($hasOpenRouterKey) {
  python -m ecp_reference.cli query --llm openrouter --skill $skill "Summarize the main components involved in mounting a volume."
}
python -m ecp_reference.cli run-evals --skill $skill
python -m ecp_reference.cli run-evals --skill $skill --suite-id conformance
python -m ecp_reference.cli refresh --dry-run --skill $skill --json | Out-Host

python -m ecp_reference.cli pack --skill $skill --out $zip --json | Out-Host
python -m ecp_reference.cli verify-pack --package $zip --json | Out-Host
python -m ecp_reference.cli prune --skill $skill --dry-run --json | Out-Host
