#!/usr/bin/env bash
# Restart user-local ollama daemons — one per GPU — with OLLAMA_NUM_PARALLEL each.
#
# Default behavior:
#   - Detect every visible NVIDIA GPU via nvidia-smi.
#   - Launch one ollama instance per GPU, pinned via CUDA_VISIBLE_DEVICES.
#   - Each instance binds 127.0.0.1:(BASE_PORT + i).
#   - All instances share $HOME/.ollama/models (read-only sharing is safe).
#
# Tunables (env vars):
#   GPUS                   — comma-separated GPU indices (default: all detected)
#   NUM_PARALLEL           — KV-cache slots per instance (default: 4)
#   OLLAMA_CONTEXT_LENGTH  — per-slot context tokens (default: 8192).
#                             gemma4:e4b's native max is 131072, but allocating
#                             that × NUM_PARALLEL OOMs the GPU. Our lm-only
#                             prompts stay well under 8K, so 8192 is plenty.
#   BASE_PORT              — first port (default: 11434)
#
# Outputs:
#   - One serve log per instance under <repo>/results/logs/ollama-gpu<i>.log
#   - hosts.list (one host:port per line) under <repo>/results/logs/
#
# Usage:
#   ./scripts/parallel/restart-ollama.sh                 # auto-detect GPUs
#   GPUS=0 ./scripts/parallel/restart-ollama.sh          # only GPU 0
#   GPUS=0,1 NUM_PARALLEL=8 ./scripts/parallel/restart-ollama.sh

set -euo pipefail

NUM_PARALLEL="${NUM_PARALLEL:-4}"
OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-8192}"
BASE_PORT="${BASE_PORT:-11434}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$REPO_ROOT/results/logs"
HOSTS_FILE="$LOG_DIR/hosts.list"
mkdir -p "$LOG_DIR"

# --- Locate ollama binary ---
if ! command -v ollama >/dev/null 2>&1; then
  if [ -x "$HOME/.local/bin/ollama" ]; then
    export PATH="$HOME/.local/bin:$PATH"
  else
    echo "[restart-ollama] ollama not on PATH" >&2; exit 1
  fi
fi

# --- Determine GPU set ---
if [ -n "${GPUS:-}" ]; then
  IFS=',' read -r -a GPU_LIST <<< "$GPUS"
else
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "[restart-ollama] nvidia-smi not found; set GPUS=<idx,...> manually" >&2
    exit 1
  fi
  mapfile -t GPU_LIST < <(nvidia-smi --query-gpu=index --format=csv,noheader)
fi
N=${#GPU_LIST[@]}
if (( N == 0 )); then
  echo "[restart-ollama] no GPUs selected" >&2; exit 1
fi

echo "[restart-ollama] launching $N ollama instance(s) — NUM_PARALLEL=$NUM_PARALLEL each"

# --- Stop any existing user-owned ollama processes ---
pkill -u "$(id -un)" -f "ollama serve" 2>/dev/null || true
# Brief grace for ports to release
sleep 2

# --- Start instances ---
mkdir -p "$HOME/.ollama"
: > "$HOSTS_FILE"
declare -a PORTS

for ((i=0; i<N; i++)); do
  GPU_ID="${GPU_LIST[i]}"
  PORT=$(( BASE_PORT + i ))
  HOST="127.0.0.1:$PORT"
  PORTS[i]="$PORT"
  LOG_FILE="$LOG_DIR/ollama-gpu${GPU_ID}.log"
  if [ -f "$LOG_FILE" ]; then mv -f "$LOG_FILE" "${LOG_FILE%.log}.prev.log"; fi

  echo "[restart-ollama]   gpu=$GPU_ID  →  $HOST  (log: $(realpath --relative-to="$REPO_ROOT" "$LOG_FILE"))"
  nohup env \
    CUDA_VISIBLE_DEVICES="$GPU_ID" \
    OLLAMA_NUM_PARALLEL="$NUM_PARALLEL" \
    OLLAMA_CONTEXT_LENGTH="$OLLAMA_CONTEXT_LENGTH" \
    OLLAMA_HOST="http://$HOST" \
    OLLAMA_KEEP_ALIVE="60m" \
    ollama serve > "$LOG_FILE" 2>&1 &
  disown
  echo "$HOST" >> "$HOSTS_FILE"
done

# --- Wait for each instance to come up ---
ok=0
for ((i=0; i<N; i++)); do
  HOST="127.0.0.1:${PORTS[i]}"
  for s in $(seq 1 30); do
    if curl -sf "http://$HOST/" >/dev/null 2>&1; then
      ok=$((ok+1))
      echo "[restart-ollama] up: http://$HOST"
      break
    fi
    sleep 1
  done
done

if (( ok != N )); then
  echo "[restart-ollama] FAILED: only $ok/$N instances responded. Check $LOG_DIR/ollama-gpu*.log" >&2
  exit 1
fi

echo "[restart-ollama] hosts.list →"
cat "$HOSTS_FILE"
