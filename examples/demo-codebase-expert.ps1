$ErrorActionPreference = "Stop"

$skill = "examples/codebase-expert"
$outDir = "demo-output"
$zip = Join-Path $outDir "codebase-expert.zip"

New-Item -ItemType Directory -Force $outDir | Out-Null

$env:PYTHONPATH = "src"

python -m ecp_poc.cli validate --skill $skill
python -m ecp_poc.cli build --skill $skill
python -m ecp_poc.cli query --skill $skill --source-id repo "Which modules handle authentication?"
python -m ecp_poc.cli query --skill $skill --source-id spec "What is ECP-Core conformance?"
python -m ecp_poc.cli run-evals --skill $skill
python -m ecp_poc.cli run-evals --skill $skill --suite-id conformance
python -m ecp_poc.cli refresh --dry-run --skill $skill --json | Out-Host

python -m ecp_poc.cli pack --skill $skill --out $zip --json | Out-Host
python -m ecp_poc.cli verify-pack --package $zip --json | Out-Host

python -m ecp_poc.cli prune --skill $skill --dry-run --json | Out-Host
