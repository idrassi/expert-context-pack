$ErrorActionPreference = "Stop"

$skill = "examples/ecp-conformance-pack"
$outDir = "demo-output"
$zipPath = Join-Path $outDir "ecp-conformance-pack.zip"
$unpackDir = Join-Path $outDir "unpacked-ecp-conformance-pack"

New-Item -ItemType Directory -Force $outDir | Out-Null
$env:PYTHONPATH = "src"

python -m ecp_reference.cli validate --with-artifacts --skill $skill
python -m ecp_reference.cli query --skill $skill "Which modules handle authentication?"
python -m ecp_reference.cli run-evals --skill $skill --suite-id conformance

python -m ecp_reference.cli pack --skill $skill --out $zipPath
python -m ecp_reference.cli verify-pack --package $zipPath

if (Test-Path $unpackDir) {
    Remove-Item -Recurse -Force $unpackDir
}
New-Item -ItemType Directory -Force $unpackDir | Out-Null
python -m zipfile -e $zipPath $unpackDir

$unpackedSkill = Join-Path $unpackDir "ecp-conformance-pack"
python -m ecp_reference.cli query --skill $unpackedSkill "Which modules handle authentication?"
python -m ecp_reference.cli run-evals --skill $unpackedSkill --suite-id conformance
