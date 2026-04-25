# LM-only Captain Baseline — Experiment Runbook

This branch (`lm-only-baseline`) adds a **pure language-model Captain** strategy to the Battleship harness so we can measure an LM-only baseline **on our own 18-board synthetic suite** — making the comparison with Grand et al. (2025) within-suite instead of "directional".

> **Required machine:** GPU machine with Ollama (for `gemma4:e4b`). The default LLM in our paper is locally served via Ollama; running it CPU-only is technically possible but very slow for 54 games × ~25 turns × multi-call prompts. An OpenRouter / OpenAI fallback path is documented at the bottom for CPU-only operators.

---

## 1. Why this experiment

Our papers (`1_lm4plan_draft.tex`, `2_agent_skills_camready.tex`) cite Grand et al.'s LM-only F1 numbers as a **directional** anchor — they live on a different 18-board suite. Re-running an LM-only Captain on **our** 18-board suite removes that caveat:

| Reference point | F1 | Suite |
| --- | ---: | --- |
| Grand et al. — Llama-4-Scout LM-only | 0.367 | their 18-board |
| Grand et al. — GPT-4o LM-only | 0.450 | their 18-board |
| Grand et al. — Greedy (no LLM) | 0.614 | their 18-board |
| **Ours — `greedy` (no LLM)** | **0.522** | **our 18-board** |
| **Ours — `wma` (no LLM, planning)** | **0.741** | **our 18-board** |
| **Ours — `lm-only` (this experiment)** | **?** | **our 18-board** |

The expected qualitative result: LM-only on our suite falls below `greedy` (0.522) for any model weaker than a frontier reasoner. Recovering this within-suite closes the "harness is just a good solver" objection (cf. `1_lm4plan_draft.tex:387` / `2_agent_skills_camready.tex:241`).

---

## 2. What this branch adds

Two file changes only:

- `src/strategies/lm-only-strategy.ts` — new `LMOnlyStrategy` class. Each turn the LLM is sent the current board (ASCII, Captain's view), past Q&A log, remaining budgets, and the list of un-asked template questions. It must reply with one line: `shoot <CELL>` or `question <QUESTION_ID>`. No posterior, no EIG, no decision rule. Parse failures fall back to a uniformly-iterated un-revealed cell (not posterior-driven, to keep the "no posterior" condition).
- `src/strategies/create-strategy.ts` — registers `--strategy lm-only`.

Caveat vs. Grand et al.: their LM Captain freely emits Python programs as questions; ours selects from our region-based template DSL. The Spotter side of our harness is template-only, so we keep this restriction and document it. The relevant qualitative claim (LM-only without posterior / EIG is weak) is preserved.

---

## 3. Setup on the GPU machine

This branch lives on the **`sonsus/battleship-manifesto` fork** of the upstream `eggplantiny/battleship-manifesto`. Clone the fork:

```bash
# 1. Clone exactly this branch from the fork
git clone -b lm-only-baseline https://github.com/sonsus/battleship-manifesto.git
cd battleship-manifesto

# 2. Node + pnpm
#    Use the version pinned in .nvmrc (currently 25.9.0)
nvm use            # or: install Node manually if no nvm
corepack enable    # bundles pnpm
pnpm install
pnpm check         # type-check; should pass clean
```

If `corepack` is unavailable:

```bash
npx pnpm@10.33.0 install
npx pnpm@10.33.0 check
```

---

## 4. Ollama setup (primary path: `gemma4:e4b`)

```bash
# Install Ollama: https://ollama.com/download
# Then in a separate shell:
ollama serve

# Pull the model used in our paper (the exact tag in 2_agent_skills_camready.tex:186)
ollama pull gemma4:e4b
```

> **If `gemma4:e4b` is not available** in the registry on this machine, fall back in this order and **note which tag was actually used in the run label**:
> 1. `gemma3n:e4b` — same effective-4B Gemma-3n family, very likely what the paper meant
> 2. `gemma3:4b` — strict 4B Gemma-3
>
> Whichever tag is used, set the `--model` flag and the `--label` to match (e.g. `--label lm-only-gemma3n-e4b-all3`).

---

## 5. Smoke test (1 board × 1 seed)

```bash
pnpm run exp:run -- \
  --strategy lm-only \
  --llm-provider ollama \
  --model gemma4:e4b \
  --boards B17 --seeds 1 \
  --protocol paper --belief mcmc --particles 500 \
  --label lm-only-smoke
```

Expected:

- run completes in single-digit minutes on a recent GPU
- `WON` or `LOST` line printed at the end with `F1=...`
- Logs written under `results/runs/lm-only-smoke-*/`

Quick inspection:

```bash
pnpm run log:lens -- --view run --run latest
pnpm run log:lens -- --view game --run latest --game B17-seed0
pnpm run log:lens -- --view llm --run latest
```

---

## 6. Full sweep (18 boards × 3 seeds = 54 games)

```bash
pnpm run exp:run -- \
  --strategy lm-only \
  --llm-provider ollama \
  --model gemma4:e4b \
  --boards all --seeds 3 \
  --protocol paper --belief mcmc --particles 500 \
  --label lm-only-gemma4-e4b-all3
```

If the model tag was different (see §4), change both `--model` and `--label` accordingly, e.g.:

```bash
--model gemma3n:e4b --label lm-only-gemma3n-e4b-all3
```

Expected wall-time: dominated by per-turn LLM latency. A single-GPU machine (24 GB VRAM, gemma3n:e4b) typically lands on the order of one to a few hours for the full 54 games. Run in `tmux` / `screen` if needed.

The runner prints a summary at the end:

```
=== Summary ===
Games: 54
Avg F1: 0.xxx
Win Rate: xx.x% (NN/54)
```

---

## 7. Bring results back

Everything we need is under one directory:

```bash
results/runs/lm-only-gemma4-e4b-all3-*/
```

Two ways to send back:

**Option A — push the run logs to the same branch on the fork:**

```bash
git add results/runs/lm-only-gemma4-e4b-all3-*/
git commit -m "lm-only: full sweep results (gemma4:e4b)"
git push origin lm-only-baseline   # origin = sonsus/battleship-manifesto fork
```

**Option B — zip and attach:**

```bash
tar czf lm-only-gemma4-e4b-all3.tar.gz results/runs/lm-only-gemma4-e4b-all3-*/
```

Files that matter:

- `summary.json` — aggregate F1 / win rate / token counts
- `events.jsonl` — full per-turn event log (per AGENTS.md: not for direct human reading; use `log:lens`)
- `games/<board>-seed<n>.json` — per-game records
- `llm-calls.jsonl` (if produced) — per-call prompts and responses, useful for debugging

Also paste the final stdout `=== Summary ===` block when reporting back — that is the single number we most need.

---

## 8. Sanity checks before declaring done

1. `summary.json` `count == 54` (18 boards × 3 seeds).
2. No game ended with > 40 shots (`--protocol paper` enforces this).
3. `pnpm run log:lens -- --view llm --run latest` shows non-zero LLM call count per game.
4. Spot-check one game with `--view game` — turns should alternate `shoot`/`question` and not all-shoot (would suggest LLM is ignoring the question pool).
5. If F1 is suspiciously high (≥ 0.7), spot-check that the strategy is genuinely `lm-only` (not silently falling back to greedy on every parse failure). The strategy emits `[lm-only] ...` warnings to stderr on each fallback — count them.

---

## 9. CPU-only / API fallback (OpenRouter)

If for some reason Ollama / GPU is not available, the same strategy can hit any OpenAI-compatible endpoint, including OpenRouter. This is *not* the primary experiment (the paper uses local gemma), but is useful for a direct comparison to Grand et al.'s **Llama-4-Scout** row.

```bash
# .env at repo root (do NOT commit):
#   OPENROUTER_API_KEY=sk-or-...

set -a; source .env; set +a
export OPENAI_API_KEY="$OPENROUTER_API_KEY"
export OPENAI_BASE_URL=https://openrouter.ai/api/v1

pnpm run exp:run -- \
  --strategy lm-only \
  --llm-provider openai \
  --model meta-llama/llama-4-scout \
  --boards all --seeds 3 \
  --protocol paper --belief mcmc --particles 500 \
  --label lm-only-llama4-scout-all3
```

Notes:

- Use whichever Llama-4-Scout tag OpenRouter currently exposes (e.g. `meta-llama/llama-4-scout`, `meta-llama/llama-4-scout-17b-16e-instruct`). Confirm at https://openrouter.ai/models.
- Cost estimate (very rough): with ~83 template-question lines in each prompt, expect a few hundred K input tokens × multiplier of turns. For Llama-4-Scout on OpenRouter this is typically well under a few dollars for the full 54-game sweep.
- The strategy is deterministic given LLM output, so seeded reproducibility relies on the LLM provider's determinism — note this when reporting.

---

## 10. After results come back

Two follow-ups (handled in a separate PR / branch, not on this experiment branch):

1. Add an `lm-only` row to `tab:decomp-main` / `tab:main` in `1_lm4plan_draft.tex` and `2_agent_skills_camready.tex` with the within-suite F1 and win rate.
2. Tighten the "harness is just a good solver" rebuttal: replace the `0.367` / `0.450` / `0.716` external numbers with a within-suite anchor.
