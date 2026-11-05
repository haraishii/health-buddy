#!/usr/bin/env bash
# Checks that OLLAMA_API_KEY in backend/.env works with Ollama Cloud and the model answers.
# Calls https://ollama.com directly, so it tests the account that owns the key, not the local `ollama` login.
#   bash scripts/check_ollama.sh        (from backend/)
set -euo pipefail
cd "$(dirname "$0")/.."

# Read only the OLLAMA_* lines: other values (e.g. a DATABASE_URL with & or <...>) break `. ./.env`.
if [ -f .env ]; then
  while IFS='=' read -r key value; do
    case "$key" in OLLAMA_*) [ -n "${!key:-}" ] || export "$key=${value%$'\r'}" ;; esac # the shell's value wins
  done < .env
fi
if [ -z "${OLLAMA_API_KEY:-}" ]; then
  echo "OLLAMA_API_KEY is empty. Put your key from https://ollama.com/settings/keys in backend/.env" >&2
  exit 1
fi
base="${OLLAMA_BASE_URL:-https://ollama.com}"
model="${OLLAMA_MODEL:-gpt-oss:120b}"
think=''
case "$model" in gpt-oss*) think='"think":"low",' ;; esac
out=$(mktemp)
trap 'rm -f "$out"' EXIT

echo "Asking $model at $base ..."
start=$(date +%s)
status=$(curl -sS -m 60 -o "$out" -w '%{http_code}' "$base/api/chat" \
  -H "Authorization: Bearer $OLLAMA_API_KEY" -H 'Content-Type: application/json' \
  -d "{\"model\":\"$model\",\"stream\":false,$think\"messages\":[{\"role\":\"user\",\"content\":\"Balas satu kalimat: tips minum air putih.\"}]}")
echo "HTTP $status in $(( $(date +%s) - start ))s"
cat "$out"; echo
[ "$status" = 200 ]
