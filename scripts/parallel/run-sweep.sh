#!/usr/bin/env bash
# Run the lm-only sweep with N parallel pnpm shards across one or more
# ollama daemons. Each shard targets exactly one ollama instance via
# --llm-base-url; shards are round-robin'd across the host pool.
#
# Prereqs:
#   1. ollama daemon(s) running with OLLAMA_NUM_PARALLEL >= shards-per-host.
#      Use ./scripts/parallel/restart-ollama.sh to start them.
#   2. Node 25.9.0 + pnpm 10.33.0 active (source ~/.local/bin/bm-env.sh).
#
# Host discovery (in order):
#   1. $HOSTS env var:   HOSTS="127.0.0.1:11434,127.0.0.1:11435"
#   2. results/logs/hosts.list (written by restart-ollama.sh)
#   3. fallback to 127.0.0.1:11434
#
# Usage examples:
#
#   # Default: 8 shards × 18 boards × 3 seeds (54 games), round-robin across 2 hosts
#   SHARDS=8 ./scripts/parallel/run-sweep.sh
#
#   # Mini speedup test: 4 concurrent single-game runs
#   SHARDS=4 SEEDS=1 BOARDS="B17,B18,B16,B15" LABEL=lm-only-mini \
#     ./scripts/parallel/run-sweep.sh
#
#   # Single-host fallback
#   HOSTS=127.0.0.1:11434 SHARDS=4 ./scripts/parallel/run-sweep.sh

set -euo pipefail

SHARDS="${SHARDS:-8}"
SEEDS="${SEEDS:-3}"
SEED_START="${SEED_START:-0}"
MODEL="${MODEL:-gemma4:e4b}"
LABEL="${LABEL:-lm-only-gemma4-e4b-all3-par${SHARDS}}"
PARTICLES="${PARTICLES:-500}"
PROTOCOL="${PROTOCOL:-paper}"
BELIEF="${BELIEF:-mcmc}"
PROVIDER="${PROVIDER:-ollama}"
BASE_URL_PATH="${BASE_URL_PATH:-}"

DEFAULT_BOARDS="B01,B02,B03,B04,B05,B06,B07,B08,B09,B10,B11,B12,B13,B14,B15,B16,B17,B18"
BOARDS_RAW="${BOARDS:-$DEFAULT_BOARDS}"

# --- Locate repo root ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"
HOSTS_FILE="$REPO_ROOT/results/logs/hosts.list"

# --- Activate user-local env (idempotent) ---
if [ -f "$HOME/.local/bin/bm-env.sh" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.local/bin/bm-env.sh" >/dev/null
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "[run-sweep] pnpm not on PATH. source ~/.local/bin/bm-env.sh first." >&2
  exit 1
fi

# --- Resolve host list ---
if [ -n "${HOSTS:-}" ]; then
  IFS=',' read -r -a HOST_LIST <<< "$HOSTS"
elif [ -f "$HOSTS_FILE" ]; then
  mapfile -t HOST_LIST < "$HOSTS_FILE"
else
  HOST_LIST=("127.0.0.1:11434")
fi
NUM_HOSTS=${#HOST_LIST[@]}
if (( NUM_HOSTS == 0 )); then
  echo "[run-sweep] no hosts resolved" >&2; exit 1
fi

# Sanity: each host responds
for h in "${HOST_LIST[@]}"; do
  # Accept any HTTP response (200 / 404 / etc.) — just verify the host listens.
  if ! curl -s -o /dev/null -m 5 -w "%{http_code}" "http://$h/" 2>/dev/null | grep -qE "^[0-9]+$"; then
    echo "[run-sweep] LLM daemon not responding at http://$h" >&2
    exit 1
  fi
done

# --- Split BOARDS into SHARDS groups (round-robin) ---
IFS=',' read -r -a ALL_BOARDS <<< "$BOARDS_RAW"
N=${#ALL_BOARDS[@]}
if (( N == 0 )); then
  echo "[run-sweep] no boards parsed from BOARDS=$BOARDS_RAW" >&2; exit 1
fi
if (( SHARDS > N )); then
  echo "[run-sweep] SHARDS=$SHARDS > #boards=$N — clamping to $N" >&2
  SHARDS=$N
fi

declare -a shard_lists
for ((i=0; i<SHARDS; i++)); do shard_lists[i]=""; done
for ((j=0; j<N; j++)); do
  i=$(( j % SHARDS ))
  if [ -z "${shard_lists[i]}" ]; then
    shard_lists[i]="${ALL_BOARDS[j]}"
  else
    shard_lists[i]="${shard_lists[i]},${ALL_BOARDS[j]}"
  fi
done

# --- Plan ---
LAUNCH_TS="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="$REPO_ROOT/results/logs/sweep-${LABEL}-${LAUNCH_TS}"
mkdir -p "$LOG_DIR"

echo "=== Parallel sweep plan ==="
echo "  label-prefix : $LABEL"
echo "  provider     : $PROVIDER  base-url-path='$BASE_URL_PATH'"
echo "  shards       : $SHARDS"
echo "  hosts        : ${HOST_LIST[*]}  (${NUM_HOSTS} instance(s))"
echo "  seeds        : start=$SEED_START count=$SEEDS"
echo "  model        : $MODEL"
echo "  protocol     : $PROTOCOL  belief=$BELIEF  particles=$PARTICLES"
echo "  shard logs   : $(realpath --relative-to="$REPO_ROOT" "$LOG_DIR")"
for ((i=0; i<SHARDS; i++)); do
  cnt=$(awk -F',' '{print NF}' <<< "${shard_lists[i]}")
  host="${HOST_LIST[$(( i % NUM_HOSTS ))]}"
  printf "  shard-%-2d     : host=%s boards=%s  (%d boards × %d seeds)\n" \
    "$i" "$host" "${shard_lists[i]}" "$cnt" "$SEEDS"
done
echo

# --- Launch shards ---
declare -a PIDS
for ((i=0; i<SHARDS; i++)); do
  host="${HOST_LIST[$(( i % NUM_HOSTS ))]}"
  log="$LOG_DIR/shard-$i.log"
  echo "[run-sweep] shard-$i → $log"
  nohup pnpm run exp:run -- \
    --strategy lm-only \
    --llm-provider "$PROVIDER" \
    --llm-base-url "http://${host}${BASE_URL_PATH}" \
    --model "$MODEL" \
    --boards "${shard_lists[i]}" \
    --seeds "$SEEDS" \
    --seed-start "$SEED_START" \
    --protocol "$PROTOCOL" \
    --belief "$BELIEF" \
    --particles "$PARTICLES" \
    --label "${LABEL}-shard${i}" \
    > "$log" 2>&1 &
  PIDS[i]=$!
done

echo
echo "=== Running PIDs: ${PIDS[*]} ==="
echo "Live partial aggregate:  watch -n 60 'python3 scripts/parallel/aggregate.py $LABEL'"
echo

# --- Wait for all shards (track per-shard exit) ---
START_EPOCH=$(date +%s)
fail=0
for ((i=0; i<SHARDS; i++)); do
  if wait "${PIDS[i]}"; then
    echo "[run-sweep] shard-$i: ok"
  else
    echo "[run-sweep] shard-$i: FAILED (see $LOG_DIR/shard-$i.log)" >&2
    fail=$((fail+1))
  fi
done
END_EPOCH=$(date +%s)
ELAPSED=$(( END_EPOCH - START_EPOCH ))
printf "[run-sweep] all shards done in %dm%ds (failures: %d)\n" $((ELAPSED/60)) $((ELAPSED%60)) "$fail"

# --- Aggregate ---
echo
python3 "$SCRIPT_DIR/aggregate.py" "$LABEL" || true

if [ "$fail" -gt 0 ]; then exit 1; fi
exit 0
