# LM-only Captain Baseline — Results

Within-suite LM-only Captain results on our 18-board synthetic suite. Replaces the "directional" cite of Grand et al. (2025) Llama-4-Scout LM-only F1 0.367 with an apples-to-apples within-suite anchor.

> **Setup parity vs. Grand et al.:** same Llama-4-Scout model (via OpenRouter), same 8×8 board / 14 ship cells / 40 shots / 15 questions / ε=0.1 noise. Differences: our 18-board synthetic suite (vs. theirs), our template-DSL question pool (vs. theirs uses Python programs the LM emits freely), and our Spotter is the harness's MCMC-based oracle rather than a GPT-5 LLM Spotter. The strategy itself (LMOnlyStrategy) takes no posterior / EIG / decision-rule advantage — the LLM directly chooses one of {shoot CELL, question QID} each turn.

---

## 1. Headline numbers

| Captain | Spotter | LLM | Suite | F1 | Win rate | Notes |
| --- | --- | --- | --- | ---: | ---: | --- |
| Random | — | — | grandetal | 0.317 | — | Grand et al. external |
| Greedy (no LLM) | GPT-5 | — | grandetal | 0.614 | — | Grand et al. external |
| **LM-only — Llama-4-Scout** | **GPT-5** | **Llama-4-Scout** | **grandetal** | **0.367** | — | **Grand et al. external** |
| LM-only — GPT-4o | GPT-5 | GPT-4o | grandetal | 0.450 | — | Grand et al. external |
| LM-only — GPT-5 | GPT-5 | GPT-5 | grandetal | 0.716 | — | Grand et al. external |
| Greedy (no LLM) | MCMC oracle | — | **ours** | **0.522** | **50.0%** | from `1_lm4plan_draft.tex:355-376` |
| WMA (no LLM, planning) | MCMC oracle | — | **ours** | **0.741** | **74.1%** | from same |
| **LM-only — Llama-4-Scout** | **MCMC oracle** | **Llama-4-Scout (OpenRouter)** | **ours** | **0.353** | **0.0%** (0/54) | **this experiment** |
| **LM-only — gemma3n:e4b** | **MCMC oracle** | **gemma3n:e4b (vLLM, GPU)** | **ours** | **0.263** | **0.0%** (0/54) | **this experiment (separate worktree)** |
| **LM-only — gpt-5-nano** | **MCMC oracle** | **gpt-5-nano (OpenRouter, reasoning_effort=medium)** | **ours** | **0.459** | **29.6%** (16/54) | **this experiment** |
| **LM-only — gpt-5-mini** | **MCMC oracle** | **gpt-5-mini (OpenRouter, reasoning_effort=medium)** | **ours** | **0.565** | **77.8%** (42/54) | **this experiment (51 clean + 9 patch after OpenRouter 402)** |

`<...>` placeholders are filled in once the corresponding sweep completes.

---

## 2. Llama-4-Scout (OpenRouter, this laptop)

- Run id: `20260426-004217__lm-only-mcmc__lm-only-llama4-scout-all3`
- Run dir: `results/runs/20260426-004217__lm-only-mcmc__lm-only-llama4-scout-all3/`
- Date (UTC+9): 2026-04-26
- Wall time: 1689 s (~28 min, all 54 games sequentially)
- Games: 54 / 54 (18 boards × 3 seeds)
- Avg F1: **0.353** (raw 0.3525)
- Win rate: **0.0%** (0 / 54)
- Avg shots: 40.0 / 40 (every game ran out of shots)
- Avg questions: 14.8 / 15
- Avg hits: 9.5 / 14 ship cells (best single game: 12; worst: 6)
- LLM model: `meta-llama/llama-4-scout` via OpenRouter (`OPENAI_BASE_URL=https://openrouter.ai/api/v1`)

Fallback diagnostics (from stderr, 54 games × ≤ 55 turns ≈ 2,800 LLM calls upper bound):

| Cause | Count | Comment |
| --- | ---: | --- |
| Invalid shoot target (cell already revealed or out of range) | 1,557 | majority of fallbacks; LM repeatedly proposes already-revealed cells |
| Already-asked / unknown question id | 114 | LM picks a question id that was already used or hallucinates ids |
| LLM response could not be parsed | 47 | LM emits free-form prose instead of `shoot CELL` / `question QID` |

Each fallback degrades into a uniformly random un-revealed cell (no posterior). Roughly half of the strategy's chosen actions across the run were fallback-driven, so the measured F1 is a mixture of pure LM and Random; on Grand et al.'s Random baseline F1 = 0.317, our 0.353 sits just above it. This is consistent with their reading that Llama-4-Scout LM-only "marginally exceeds random baselines" (their abstract).

Per-board averages (best→worst F1, n=3 seeds each):

| Board | F1 | Wins | Avg shots | Avg q |
| --- | ---: | ---: | ---: | ---: |
| B07 | 0.432 | 0/3 | 40.0 | 14.3 |
| B11 | 0.395 | 0/3 | 40.0 | 15.0 |
| B13 | 0.383 | 0/3 | 40.0 | 15.0 |
| B02 | 0.370 | 0/3 | 40.0 | 15.0 |
| B12 | 0.370 | 0/3 | 40.0 | 15.0 |
| B04 | 0.358 | 0/3 | 40.0 | 14.0 |
| B14 | 0.358 | 0/3 | 40.0 | 15.0 |
| B01 | 0.358 | 0/3 | 40.0 | 15.0 |
| B09 | 0.358 | 0/3 | 40.0 | 15.0 |
| B15 | 0.358 | 0/3 | 40.0 | 15.0 |
| B10 | 0.346 | 0/3 | 40.0 | 15.0 |
| B17 | 0.346 | 0/3 | 40.0 | 15.0 |
| B05 | 0.333 | 0/3 | 40.0 | 14.3 |
| B06 | 0.333 | 0/3 | 40.0 | 15.0 |
| B18 | 0.333 | 0/3 | 40.0 | 15.0 |
| B08 | 0.321 | 0/3 | 40.0 | 15.0 |
| B16 | 0.309 | 0/3 | 40.0 | 15.0 |
| B03 | 0.284 | 0/3 | 40.0 | 13.7 |

### Reproduce

```bash
git clone -b lm-only-baseline https://github.com/sonsus/battleship-manifesto.git
cd battleship-manifesto && pnpm install

set -a; source path/to/.env; set +a
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

---

## 3. gemma3n:e4b (vLLM, GPU machine)

Run on a separate GPU-machine worktree per `docs/lm-only-experiment.md`. The paper's `gemma4:e4b` Ollama tag resolved to **`gemma3n:e4b` served via vLLM** (the operator's chosen serving stack).

- Games: 54 / 54 (18 boards × 3 seeds)
- Avg F1: **0.263**
- Win rate: **0.0%** (0 / 54), Wilson 95% CI [0.0, 6.6]
- Avg questions: 14.19 / 15
- LLM model: `gemma3n:e4b` via vLLM
- LLM Rate: every turn (LM-only)

> Below Grand et al.'s Random baseline (0.317 on their suite). With our uniformly-random-unrevealed-cell fallback as the strict floor, F1 falling *below* uniform random means gemma3n:e4b's systematic LM-side errors — repeating cells, clustering shots in narrow lines, hallucinating coordinates — actively de-randomize away from the Random expectation. Strict within-suite floor of the LM-only regime: even with our forgiving fallback semantics, a small open-weights model running every turn underperforms no-coordination uniform random.

> Per-board / per-seed table and full diagnostics for this row live in the GPU-machine worktree's run dir, not in this branch.

---

## 4. gpt-5-nano (OpenRouter, this laptop, reasoning_effort=medium)

- Run id: `20260426-081945__lm-only-mcmc__lm-only-gpt5-nano-all3-c12`
- Run dir: `results/runs/20260426-081945__lm-only-mcmc__lm-only-gpt5-nano-all3-c12/`
- Date (UTC+9): 2026-04-26
- Wall time: 3h35m (start 08:19:45 KST → finish 11:54:24 KST), `--concurrency 12`
- Games: 54 / 54 (18 boards × 3 seeds)
- Avg F1: **0.459** (raw 0.4593)
- Win rate: **29.6%** (16 / 54), Wilson 95% CI [19.1, 42.8]
- Avg shots: 38.4 / 40 (16 games closed before exhausting the shot budget)
- Avg questions: 12.4 / 15
- Avg hits: 11.91 / 14 ship cells (best single game: 14 hits in 23 shots; worst: 7)
- LLM model: `openai/gpt-5-nano` via OpenRouter, **default `reasoning_effort=medium`** (matches Grand et al.'s "we query all models via the OpenRouter API with default parameters")

Fallback diagnostics across the nano sweep + the 1 partial gpt-5-mini game (combined logs):

| Cause | Count | Comment |
| --- | ---: | --- |
| Invalid shoot target | 162 | LM occasionally picks an already-revealed cell |
| Already-asked / unknown question id | 38 | LM picks a question id already used or hallucinates |
| LLM call / parse failure (transient) | 13 | OpenRouter occasional truncated / malformed JSON |

Roughly **~8% fallback rate** across ~2,743 LLM-decided turns — a major drop from Llama-4-Scout's ~50% (A1). Reasoning mostly resolves the "spatial reasoning on 8×8 ASCII" problem.

Per-board averages (best→worst F1, n=3 seeds each):

| Board | F1 | Wins | Avg shots | Avg q |
| --- | ---: | ---: | ---: | ---: |
| B06 | 0.558 | 2/3 | 33.7 | 13.0 |
| B10 | 0.541 | 2/3 | 35.7 | 13.7 |
| B12 | 0.508 | 1/3 | 36.7 | 14.0 |
| B03 | 0.507 | 2/3 | 38.7 | 11.3 |
| B05 | 0.504 | 1/3 | 37.0 | 11.7 |
| B17 | 0.495 | 1/3 | 37.7 | 10.7 |
| B08 | 0.488 | 2/3 | 39.3 | 15.0 |
| B11 | 0.485 | 1/3 | 39.7 | 12.0 |
| B13 | 0.481 | 1/3 | 40.0 | 11.0 |
| B04 | 0.478 | 1/3 | 38.0 | 13.0 |
| B02 | 0.463 | 1/3 | 39.3 | 11.3 |
| B09 | 0.432 | 0/3 | 40.0 | 13.0 |
| B01 | 0.420 | 0/3 | 40.0 | 11.7 |
| B16 | 0.413 | 1/3 | 35.7 | 12.7 |
| B18 | 0.407 | 0/3 | 40.0 | 13.0 |
| B07 | 0.383 | 0/3 | 40.0 | 15.0 |
| B15 | 0.358 | 0/3 | 40.0 | 13.0 |
| B14 | 0.346 | 0/3 | 40.0 | 9.0 |

> Below B1 (Greedy / Belief-only, F1 0.522 / WR 50.0%) on both metrics. Wilson 95% on win rate is [19.1, 42.8]% vs. B1's [37.1, 62.9]% — CIs touch but A3 center is below B1 center. Adding default-medium reasoning to a *small* model lifts F1 by +0.106 over A1 (no-reasoning Llama-4-Scout) and converts 0 wins to 16 wins, but does not reach the no-LLM posterior baseline.

### Reproduce

```bash
git clone -b lm-only-baseline https://github.com/sonsus/battleship-manifesto.git
cd battleship-manifesto && pnpm install

set -a; source path/to/.env; set +a
export OPENAI_API_KEY="$OPENROUTER_API_KEY"
export OPENAI_BASE_URL=https://openrouter.ai/api/v1

pnpm run exp:run -- \
  --strategy lm-only \
  --llm-provider openai \
  --model openai/gpt-5-nano \
  --boards all --seeds 3 \
  --protocol paper --belief mcmc --particles 500 \
  --concurrency 12 \
  --label lm-only-gpt5-nano-all3-c12
```

---

## 5. gpt-5-mini (OpenRouter, default reasoning_effort=medium) — composite of two runs

The headline mini number is a deterministic merge of two runs:

1. **Rerun** (`20260426-182605__lm-only-mcmc__lm-only-gpt5-mini-all3-c12-rerun`, started 18:26 KST, finished 19:50 KST, --concurrency 12). 54 games launched; the last ~3 boards (B16, B17, B18) hit OpenRouter 402 Payment Required mid-game when the prepaid balance was exhausted. Those boards' avg-questions collapsed (B18: q=3.3, B17: q=8.3, B16: q=13.7 vs. normal q=12–15) — symptom that the LLM was responding with HTTP 402 and the strategy fell back to uniform random shooting. The 51 games on B01..B15 are clean.
2. **Patch** (`20260426-214138__lm-only-mcmc__lm-only-gpt5-mini-patch-b16-b18`, started 21:41 KST, finished ~22:00 KST, --concurrency 9). Re-ran exactly B16, B17, B18 × 3 seeds = 9 games after the user topped up the OpenRouter balance.

Composite recipe (in `lm-only-results.md` as the source of truth): take the 51 games from the rerun where `boardId not in {B16, B17, B18}`, append the 9 games from the patch run, total = 54.

- Combined games: 54 / 54 (18 boards × 3 seeds)
- Avg F1: **0.565** (raw 0.5648)
- Win rate: **77.8%** (42 / 54), Wilson 95% CI [65.1, 86.8]
- Avg shots: 34.5 / 40
- Avg questions: 14.17 / 15
- Avg hits: 13.46 / 14 ship cells
- LLM model: `openai/gpt-5-mini` via OpenRouter, **default `reasoning_effort=medium`**
- Wall time: rerun 1h 24m + patch ~20m = ~1h 44m total at C=12 / C=9
- 1 transient JSON parse failure across the combined run; otherwise no fallback dominance.

Per-board averages (best→worst F1, n=3 seeds each, composite):

| Board | F1 | Wins | Avg shots | Avg q |
| --- | ---: | ---: | ---: | ---: |
| B08 | 0.684 | 3/3 | 27.0 | 15.0 |
| B05 | 0.633 | 3/3 | 30.3 | 13.7 |
| B04 | 0.625 | 3/3 | 31.0 | 13.7 |
| B02 | 0.617 | 3/3 | 31.7 | 12.3 |
| B13 | 0.614 | 3/3 | 31.7 | 14.0 |
| B17 | 0.611 | 3/3 | 32.7 | 14.7 |
| B01 | 0.609 | 3/3 | 32.0 | 14.7 |
| B10 | 0.605 | 2/3 | 30.7 | 12.3 |
| B09 | 0.580 | 3/3 | 35.0 | 15.0 |
| B18 | 0.560 | 2/3 | 35.0 | 14.7 |
| B03 | 0.551 | 2/3 | 34.0 | 12.3 |
| B07 | 0.543 | 3/3 | 37.7 | 14.7 |
| B11 | 0.532 | 3/3 | 38.7 | 15.0 |
| B12 | 0.530 | 2/3 | 37.7 | 14.3 |
| B15 | 0.491 | 1/3 | 38.0 | 14.7 |
| B16 | 0.488 | 1/3 | 39.3 | 14.7 |
| B14 | 0.451 | 1/3 | 39.3 | 14.3 |
| B06 | 0.442 | 1/3 | 39.0 | 15.0 |

> **Crosses B1 (Greedy 0.522) and reaches B2 (WMA 0.539 / WR 74.1%).** Wilson 95% CIs on WR overlap with B2's [61.1, 83.9]; A4's center is +3.7pp above B2's. Within our sample size we read A4 ≈ B2.

### Reproduce (rerun)

```bash
set -a; source path/to/.env; set +a
export OPENAI_API_KEY="$OPENROUTER_API_KEY"
export OPENAI_BASE_URL=https://openrouter.ai/api/v1

pnpm run exp:run -- \
  --strategy lm-only \
  --llm-provider openai \
  --model openai/gpt-5-mini \
  --boards all --seeds 3 \
  --protocol paper --belief mcmc --particles 500 \
  --concurrency 12 \
  --label lm-only-gpt5-mini-all3-c12
```

Approx cost: ~$8 OpenRouter (ensure ≥$10 balance before starting; the original sweep ran out at ~85% completion).

---

## 6. Reading

Four completed LM-only Captain rows on our 18-board × 3-seed suite, layered against our no-LLM baselines (B1 Greedy F1 0.522 / WR 50.0%, B2 WMA F1 0.539 / WR 74.1%):

| Row | LM-only Captain | F1 | Win rate (n=54) | vs. B1 (Greedy) | vs. B2 (WMA) |
| --- | --- | ---: | ---: | --- | --- |
| A2 | gemma3n:e4b (small, no reasoning) | 0.263 | 0.0% | below Random (0.317) | far below |
| A1 | Llama-4-Scout (109B MoE, no reasoning) | 0.353 | 0.0% | between Random and B1 | far below |
| A3 | gpt-5-nano (small reasoning) | 0.459 | 29.6% | below B1 | below |
| **A4** | **gpt-5-mini (mid reasoning)** | **0.565** | **77.8%** | **above** | **≈ B2 (CIs overlap)** |

**Key readings:**

1. **Non-reasoning LM-only at any model size we measured does not reach B1.** A1 (Llama-4-Scout, 109B MoE active 17B) and A2 (gemma3n:e4b, ~4B effective) both sit at WR 0%, F1 well below B1. Model size is not the missing ingredient — *reasoning at inference time is*.
2. **A2 below Random is a meaningful within-suite floor.** With our random fallback as the strict floor, F1 below uniform random shows that small open-weights LM choices actively de-randomize away from uniform — a stronger statement than "weak LMs are noisy".
3. **Reasoning at small scale (A3) closes most of the B1 gap but does not cross it.** A1 → A3 (no reasoning → small reasoning) lifts F1 +0.106 and WR +29.6pp. The remaining ~6pp F1 / ~20pp WR gap to B1 is the residual the planning layer (B2) covers without an LLM.
4. **Reasoning at mid scale (A4) crosses B1 and reaches B2.** A3 → A4 (small → mid reasoning) lifts F1 +0.106 again, WR +48.2pp. A4 sits at the same WR neighborhood as B2 (74.1%), with overlapping Wilson CIs. **The harness's heavy-lifting layer (planning) is reachable two ways within our suite: (i) by adding planning structure with zero LLM calls (B2), or (ii) by spending an LLM call every turn at mid-reasoning class (A4).**
5. **The decomposition's question changes shape, not validity.** "Harness is just a good solver" was the rebuttal we wanted to close *within-suite*. With A1, A2, A3 below B1, the "non-reasoning LM-only ≪ no-LLM harness" claim is closed. With A4 ≈ B2, the more nuanced claim becomes: *the same competence is recoverable two ways, and our decomposition isolates the no-LLM path*. The LLM-residual at L4 (B6) is then a separate question — measured *inside* the harness regime, not against an LM-only contender — and that residual stays small (4.3% LLM rate, +0.005 F1 over B4).

**Caveats** (full list in §7): the LM-only F1 is regularized by the fallback rate (mixture with Random); A1 has ~50% fallback, A3 has ~8%, A4 has near-zero fallback (1 transient parse fail across 54 games + ~2,800 turns). A4's number is therefore the "cleanest" LM-only data point.

---

## 7. Caveats

- **Question pool difference vs. Grand et al.** Their LM Captain freely emits Python programs; ours selects from the region-based template DSL. We document this as a reduction in LM expressiveness, not as a confound — a more-expressive Python question space would, if anything, improve their LM-only baseline relative to ours, so the within-suite ordering "LM-only < Greedy" is conservative.
- **Spotter difference vs. Grand et al.** We use the harness's MCMC-based oracle Spotter (with ε=0.1 BSC noise applied at the answer step) rather than a GPT-5 LLM Spotter doing CoT+Code translation. Same ε, different agent on the answering side. We do not claim Spotter parity.
- **Fallback semantics in LMOnlyStrategy.** When the LLM emits an invalid cell or already-asked question id, the strategy falls back to a **uniformly random un-revealed cell** — strictly no posterior / EIG access. This matches a mixture: `(1 - p_invalid) × LM-only + p_invalid × Random`. The smoke test logged ~30 fallbacks in a 54-turn game, so the measured F1 is somewhat regularized toward the Random baseline (0.317 on Grand et al.'s suite). If the F1 looks "too high", check the fallback rate via the `[lm-only]` warnings in stderr.
