#!/usr/bin/env bash
set -euo pipefail

skill="examples/codebase-expert"
out_dir="demo-output"
zip_path="${out_dir}/codebase-expert.zip"

mkdir -p "${out_dir}"

export PYTHONPATH="src"

python -m ecp_poc.cli validate --skill "${skill}"
python -m ecp_poc.cli build --skill "${skill}"
python -m ecp_poc.cli query --skill "${skill}" --source-id repo "Which modules handle authentication?"
python -m ecp_poc.cli query --skill "${skill}" --source-id spec "What is ECP-Core conformance?"
python -m ecp_poc.cli run-evals --skill "${skill}"
python -m ecp_poc.cli run-evals --skill "${skill}" --suite-id conformance
python -m ecp_poc.cli refresh --dry-run --skill "${skill}" --json

python -m ecp_poc.cli pack --skill "${skill}" --out "${zip_path}" --json
python -m ecp_poc.cli verify-pack --package "${zip_path}" --json

python -m ecp_poc.cli prune --skill "${skill}" --dry-run --json
