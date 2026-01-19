#!/usr/bin/env bash
set -euo pipefail

SKILL="examples/ecp-conformance-pack"
OUT_DIR="demo-output"
ZIP_PATH="${OUT_DIR}/ecp-conformance-pack.zip"
UNPACK_DIR="${OUT_DIR}/unpacked-ecp-conformance-pack"

mkdir -p "${OUT_DIR}"
export PYTHONPATH="src"

python -m ecp_reference.cli validate --with-artifacts --skill "${SKILL}"
python -m ecp_reference.cli query --skill "${SKILL}" "Which modules handle authentication?"
python -m ecp_reference.cli run-evals --skill "${SKILL}" --suite-id conformance

python -m ecp_reference.cli pack --skill "${SKILL}" --out "${ZIP_PATH}"
python -m ecp_reference.cli verify-pack --package "${ZIP_PATH}"

rm -rf "${UNPACK_DIR}"
mkdir -p "${UNPACK_DIR}"
python -m zipfile -e "${ZIP_PATH}" "${UNPACK_DIR}"

python -m ecp_reference.cli query --skill "${UNPACK_DIR}/ecp-conformance-pack" "Which modules handle authentication?"
python -m ecp_reference.cli run-evals --skill "${UNPACK_DIR}/ecp-conformance-pack" --suite-id conformance
