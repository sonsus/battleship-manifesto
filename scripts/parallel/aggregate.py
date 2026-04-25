#!/usr/bin/env python3
"""
Combine per-shard results from a parallel sweep into one Avg F1 / Win Rate.

Usage:
  python3 scripts/parallel/aggregate.py <label-prefix>

For every shard run dir matching:
    results/runs/<label-prefix>-shard*-*

we look for, in order:
  1. summary.json            — final per-shard summary (run completed)
  2. games.jsonl + games/    — partial: re-aggregate from completed games
                               (works even if the shard was killed mid-run)
  3. nothing                 — shard never produced data

This survives mid-sweep instance kills: any game that finished writing
its row into games.jsonl is included in the aggregate.
"""
from __future__ import annotations

import glob
import json
import os
import sys
from typing import Iterable


def load_summary(run_dir: str) -> dict | None:
    """Return the run-level summary if `summary.json` exists, else None."""
    path = os.path.join(run_dir, "summary.json")
    if not os.path.exists(path):
        return None
    try:
        with open(path) as fh:
            return json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"  [warn] {run_dir}: summary.json unreadable: {exc}", file=sys.stderr)
        return None


def iter_completed_games(run_dir: str) -> Iterable[dict]:
    """
    Yield the per-game summary dicts from games.jsonl for COMPLETED games.

    Each row contains the fields written in file-experiment-logger.ts: at
    minimum boardId, seed, targetingF1, won, shotsFired, hitCount, missCount,
    questionsAsked. Failed games (status != "completed") are skipped.

    Rows with questionsAsked == 0 are also skipped — they correspond to
    games where the LLM endpoint died and every turn fell back to the
    uniform un-revealed-cell shoot, which is not a real lm-only datapoint.
    """
    path = os.path.join(run_dir, "games.jsonl")
    if not os.path.exists(path):
        return
    with open(path) as fh:
        for raw in fh:
            raw = raw.strip()
            if not raw:
                continue
            try:
                row = json.loads(raw)
            except json.JSONDecodeError:
                continue
            if row.get("status") != "completed":
                continue
            if int(row.get("questionsAsked", 0)) == 0:
                # All-fallback "ghost" game (LLM was unreachable for every turn).
                continue
            yield row


def shard_stats_from_partial(run_dir: str) -> dict | None:
    """Reconstruct the same shape we'd get from summary.json, from games.jsonl."""
    rows = list(iter_completed_games(run_dir))
    if not rows:
        return None
    n = len(rows)
    f1 = sum(float(r.get("targetingF1", 0.0)) for r in rows) / n
    wins = sum(1 for r in rows if r.get("won"))
    avg_shots = sum(int(r.get("shotsFired", 0)) for r in rows) / n
    avg_q = sum(int(r.get("questionsAsked", 0)) for r in rows) / n
    return {
        "games": n,
        "avgF1": f1,
        "wins": wins,
        "avgShots": avg_shots,
        "avgQuestions": avg_q,
        "_partial": True,
    }


def main(label: str) -> int:
    pattern = f"results/runs/*{label}-shard*"
    runs = sorted(glob.glob(pattern))
    if not runs:
        print(f"[aggregate] no shards found at {pattern}", file=sys.stderr)
        return 1

    total_games = 0
    total_f1 = 0.0
    total_wins = 0
    total_shots = 0.0
    total_questions = 0.0
    rows = []

    for run_dir in runs:
        s = load_summary(run_dir)
        partial = False
        if s is None:
            s = shard_stats_from_partial(run_dir)
            partial = True if s is not None else False
            if s is None:
                rows.append((run_dir, 0, 0.0, 0, 0.0, 0.0, "MISSING"))
                continue

        n = int(s.get("games", 0))
        avg_f1 = float(s.get("avgF1", 0.0))
        wins = int(s.get("wins", 0))
        avg_shots = float(s.get("avgShots", 0.0))
        avg_q = float(s.get("avgQuestions", 0.0))
        tag = "partial" if partial else "ok"
        rows.append((run_dir, n, avg_f1, wins, avg_shots, avg_q, tag))

        total_games += n
        total_f1 += avg_f1 * n
        total_wins += wins
        total_shots += avg_shots * n
        total_questions += avg_q * n

    print("=== Per-shard ===")
    for run_dir, n, avg_f1, wins, shots, q, tag in rows:
        wr = (wins / n * 100) if n else 0.0
        name = os.path.basename(run_dir)
        if tag == "MISSING":
            print(f"  {name}: MISSING (no summary.json, no games.jsonl)")
        else:
            print(
                f"  {name}: [{tag}] n={n} avgF1={avg_f1:.3f} wins={wins} "
                f"winRate={wr:.1f}% avgShots={shots:.1f} avgQ={q:.1f}"
            )

    if not total_games:
        print("[aggregate] no completed games found", file=sys.stderr)
        return 2

    combined_f1 = total_f1 / total_games
    combined_shots = total_shots / total_games
    combined_q = total_questions / total_games
    combined_wr = total_wins * 100 / total_games

    print()
    print("=== Combined Summary ===")
    print(f"Games: {total_games}  (target 54 = 18 boards × 3 seeds)")
    print(f"Avg F1: {combined_f1:.3f}")
    print(f"Win Rate: {combined_wr:.1f}% ({total_wins}/{total_games})")
    print(f"Avg Shots: {combined_shots:.2f}")
    print(f"Avg Questions: {combined_q:.2f}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
