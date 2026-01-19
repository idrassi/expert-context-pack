#!/usr/bin/env bash
set -euo pipefail

skill="examples/codebase-expert"
out_dir="demo-output"
zip_path="${out_dir}/codebase-expert.zip"

mkdir -p "${out_dir}"

export PYTHONPATH="src"

python -m ecp_reference.cli validate --skill "${skill}"
python -m ecp_reference.cli build --skill "${skill}"
python -m ecp_reference.cli query --skill "${skill}" --source-id repo "Which modules handle authentication?"
python -m ecp_reference.cli query --skill "${skill}" --source-id spec "What is ECP-Core conformance?"
python -m ecp_reference.cli run-evals --skill "${skill}"
python -m ecp_reference.cli run-evals --skill "${skill}" --suite-id conformance
python -m ecp_reference.cli refresh --dry-run --skill "${skill}" --json

python -m ecp_reference.cli pack --skill "${skill}" --out "${zip_path}" --json
python -m ecp_reference.cli verify-pack --package "${zip_path}" --json

python -m ecp_reference.cli prune --skill "${skill}" --dry-run --json
