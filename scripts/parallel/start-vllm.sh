#!/usr/bin/env bash
# Start one vLLM serve instance per GPU. OpenAI-compatible endpoint.
#
# Tunables (env):
#   GPUS               — comma-separated GPU indices (default: all detected)
#   MODEL              — HF model id (default: google/gemma-3n-E4B-it)
#   BASE_PORT          — first port (default: 8000)
#   MAX_MODEL_LEN      — max sequence length per slot (default: 8192)
#   MAX_NUM_SEQS       — concurrent sequences per instance (default: 16)
#   GPU_MEM_UTIL       — fraction of VRAM to reserve (default: 0.9)
#
# Outputs:
#   - vllm-gpu<i>.log under <repo>/results/logs/
#   - hosts.list (one host:port per line) under <repo>/results/logs/
#     (so run-sweep.sh discovers them automatically)

set -euo pipefail

MODEL="${MODEL:-google/gemma-3n-E4B-it}"
BASE_PORT="${BASE_PORT:-8000}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-8192}"
MAX_NUM_SEQS="${MAX_NUM_SEQS:-16}"
GPU_MEM_UTIL="${GPU_MEM_UTIL:-0.9}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$REPO_ROOT/results/logs"
HOSTS_FILE="$LOG_DIR/hosts.list"
mkdir -p "$LOG_DIR"

VENV="$REPO_ROOT/.venv"
if [ ! -x "$VENV/bin/vllm" ] && [ ! -x "$VENV/bin/python" ]; then
  echo "[start-vllm] .venv not ready at $VENV" >&2
  exit 1
fi

# --- Determine GPU set ---
if [ -n "${GPUS:-}" ]; then
  IFS=',' read -r -a GPU_LIST <<< "$GPUS"
else
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "[start-vllm] nvidia-smi not found; set GPUS=<idx,...>" >&2; exit 1
  fi
  mapfile -t GPU_LIST < <(nvidia-smi --query-gpu=index --format=csv,noheader)
fi
N=${#GPU_LIST[@]}

echo "[start-vllm] launching $N vllm instance(s) — model=$MODEL"

# Stop any existing user-owned vllm serve processes (use a tight pattern so we
# don't kill the launcher itself — its path contains "vllm").
pkill -u "$(id -un)" -f "vllm serve" 2>/dev/null || true
pkill -u "$(id -un)" -f "vllm.entrypoints" 2>/dev/null || true
sleep 2

: > "$HOSTS_FILE"
declare -a PORTS

for ((i=0; i<N; i++)); do
  GPU_ID="${GPU_LIST[i]}"
  PORT=$(( BASE_PORT + i ))
  HOST="127.0.0.1:$PORT"
  PORTS[i]="$PORT"
  LOG_FILE="$LOG_DIR/vllm-gpu${GPU_ID}.log"
  if [ -f "$LOG_FILE" ]; then mv -f "$LOG_FILE" "${LOG_FILE%.log}.prev.log"; fi

  echo "[start-vllm]   gpu=$GPU_ID  →  $HOST  log=results/logs/$(basename "$LOG_FILE")"
  nohup env \
    CUDA_VISIBLE_DEVICES="$GPU_ID" \
    "$VENV/bin/vllm" serve "$MODEL" \
      --host 127.0.0.1 \
      --port "$PORT" \
      --max-model-len "$MAX_MODEL_LEN" \
      --max-num-seqs "$MAX_NUM_SEQS" \
      --gpu-memory-utilization "$GPU_MEM_UTIL" \
      > "$LOG_FILE" 2>&1 &
  disown
  echo "$HOST" >> "$HOSTS_FILE"
done

# --- Wait for /v1/models to respond on each ---
ok=0
for ((i=0; i<N; i++)); do
  HOST="127.0.0.1:${PORTS[i]}"
  for s in $(seq 1 600); do  # up to 10 min for first model load
    if curl -sf "http://$HOST/v1/models" >/dev/null 2>&1; then
      ok=$((ok+1))
      echo "[start-vllm] up: http://$HOST"
      break
    fi
    sleep 1
  done
done

if (( ok != N )); then
  echo "[start-vllm] FAILED: only $ok/$N instances responded. Check $LOG_DIR/vllm-gpu*.log" >&2
  exit 1
fi

echo "[start-vllm] hosts.list →"
cat "$HOSTS_FILE"
