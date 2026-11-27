#!/usr/bin/env bash
set -Eeuo pipefail

[[ $EUID -ne 0 ]] || { echo "Run as the desktop user, not root." >&2; exit 2; }
command -v ollama >/dev/null || { echo "Ollama is not installed." >&2; exit 2; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

sudo install -d -m 0755 /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/10-fenrir.conf >/dev/null <<'EOF'
[Service]
Environment=OLLAMA_FLASH_ATTENTION=1
Environment=OLLAMA_KV_CACHE_TYPE=q8_0
Environment=OLLAMA_CONTEXT_LENGTH=8192
Environment=OLLAMA_NUM_PARALLEL=1
Environment=OLLAMA_MAX_LOADED_MODELS=1
Environment=OLLAMA_KEEP_ALIVE=5m
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now ollama.service

ready=0
for _ in $(seq 1 60); do
  if curl -fsS http://127.0.0.1:11434/api/version >/dev/null; then
    ready=1
    break
  fi
  sleep 2
done
(( ready == 1 )) || { echo "Ollama API did not become ready." >&2; exit 1; }

python3 "$ROOT/scripts/ollama-benchmark.py"
