#!/usr/bin/env bash
set -euo pipefail

skill="examples/veracrypt-expert-hybrid-vector"
fallback_skill="examples/veracrypt-expert"
repo="examples/VeraCrypt"
out_dir="demo-output"
zip_path="${out_dir}/veracrypt-expert-hybrid-vector.zip"

if [[ ! -d "${repo}" ]]; then
  echo "Missing ${repo}."
  echo "Clone VeraCrypt first: git clone https://github.com/veracrypt/VeraCrypt ${repo}"
  exit 1
fi

mkdir -p "${out_dir}"

export PYTHONPATH="src"

if ! python - <<'PY'
import sqlite3
c = sqlite3.connect(":memory:")
c.execute("CREATE VIRTUAL TABLE t USING fts5(x);")
c.close()
PY
then
  echo "SQLite FTS5 not available; falling back to ${fallback_skill}"
  skill="${fallback_skill}"
  zip_path="${out_dir}/veracrypt-expert.zip"
fi

python -m ecp_reference.cli validate --skill "${skill}"
python -m ecp_reference.cli build --skill "${skill}"
python -m ecp_reference.cli validate --with-artifacts --skill "${skill}" --json       
python -m ecp_reference.cli query --skill "${skill}" --source-id repo "Where are the license terms located?"
python -m ecp_reference.cli query --skill "${skill}" --source-id repo "Where is Argon2 implemented?"
if [[ "${skill}" == "examples/veracrypt-expert-hybrid-vector" ]]; then
  qvec_file="${out_dir}/query_vector.json"
  python -c "import json; from ecp_reference.vectors import hash_embed; print(json.dumps(hash_embed('Where is Argon2 implemented?', dims=256, salt='veracrypt-hash-embed-v1', include_char_ngrams=True, char_ngram=3, char_ngram_weight=0.5), ensure_ascii=False))" > "${qvec_file}"
  python -m ecp_reference.cli query --skill "${skill}" --query-vector-file "${qvec_file}" --source-id repo "Where is Argon2 implemented?"
fi
if [[ -f ".env" ]] && grep -Eq '^[[:space:]]*(export[[:space:]]+)?OPENROUTER_API_KEY[[:space:]]*=' ".env"; then
  python -m ecp_reference.cli query --llm openrouter --skill "${skill}" "Summarize the main components involved in mounting a volume."
fi
python -m ecp_reference.cli run-evals --skill "${skill}"
python -m ecp_reference.cli run-evals --skill "${skill}" --suite-id conformance
python -m ecp_reference.cli refresh --dry-run --skill "${skill}" --json

python -m ecp_reference.cli pack --skill "${skill}" --out "${zip_path}" --json        
python -m ecp_reference.cli verify-pack --package "${zip_path}" --json
python -m ecp_reference.cli prune --skill "${skill}" --dry-run --json
