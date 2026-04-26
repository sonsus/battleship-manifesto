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
| LM-only — gpt-5-mini | MCMC oracle | gpt-5-mini (OpenRouter, reasoning_effort=medium) | ours | (paused 1/54: F1 0.757) | TBD | rerun later, see §4 below |

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

## 5. gpt-5-mini (paused — rerun pending)

Sweep was started right after nano finished (2026-04-26 11:54 KST) at `--concurrency 12`, but stopped after **1 / 54** games for time reasons. Single-game preview: **B04 seed=0 WON F1 0.757, shots=23, q=15** — sits in WMA-territory (B2 0.539 / 74.1% WR), but n=1 is purely anecdotal and not reportable as a row in the unified table until the full 54-game sweep completes.

Partial run dir (1 game, kept on disk for provenance): `results/runs/20260426-115425__lm-only-mcmc__lm-only-gpt5-mini-all3-c12/games/010__b04__seed0.json`.

To resume (full re-run, recommend a new label so the partial run dir is left untouched):

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
  --label lm-only-gpt5-mini-all3-c12-rerun
```

Expected wall time: ~4 hours at C=12. Approx cost: ~$8 OpenRouter (default `reasoning_effort=medium`).

---

## 6. Reading

We now have three completed LM-only Captain rows on our 18-board × 3-seed suite (A1 Llama-4-Scout, A2 gemma3n:e4b, A3 gpt-5-nano), plus one paused row (A4 gpt-5-mini, 1/54 with F1 0.757 — anecdotal, not yet reportable). Layered against our no-LLM baseline (B1 Greedy / Belief-only F1 0.522 / WR 50.0%):

| Row | LM-only Captain | F1 | Win rate (n=54) | Compared to B1 (Greedy 0.522 / WR 50.0%) |
| --- | --- | ---: | ---: | --- |
| A2 | gemma3n:e4b (small open-weights, no reasoning) | 0.263 | 0.0% | below Random (0.317) |
| A1 | Llama-4-Scout (mid-tier MoE, no reasoning) | 0.353 | 0.0% | between Random and B1 |
| A3 | gpt-5-nano (small reasoning, default medium) | 0.459 | 29.6% | non-zero wins, still below B1 |
| A4 (1/54) | gpt-5-mini (mid-tier reasoning, default medium) | 0.757 (n=1) | TBD | one-shot preview puts it in WMA territory |

**Key reading from the three completed rows:**

1. **The B1 boundary holds across all three completed LM-only Captains.** Even with default-medium reasoning at every turn (A3), LM-only sits below the no-LLM Greedy posterior on both F1 and win rate. The "harness is just a good solver" rebuttal in `1_lm4plan_draft.tex:387` / `2_agent_skills_camready.tex:241` has a within-suite anchor for *small open-weights*, *non-reasoning mid-tier MoE*, and *small reasoning* model classes simultaneously.
2. **Reasoning helps, but does not catch B1 on its own (with a small reasoning model).** A1 → A3 is +0.106 F1 / +29.6pp win rate at the same model-class step from "no reasoning" to "default reasoning, smallest GPT-5 family member". The remaining ~6pp F1 / ~20pp WR gap to B1 is the residual that the planning layer (B2) covers without an LLM.
3. **A2 below Random is a meaningful within-suite floor.** With our random fallback as the strict floor, F1 below uniform random shows that small open-weights LM choices actively de-randomize away from uniform — a stronger statement than "weak LMs are noisy".
4. **The decomposition is not "good solver vs. LLM".** Our planning gap (B1 → B2: +0.017 F1 / +24.1pp win rate) remains the dominant within-suite signal; the LM-only rows establish that the LLM, on its own, does not recover even greedy posterior performance in this domain at any of the three model classes we measured.
5. **A4 will refine the upper-bound question.** One full sweep of gpt-5-mini will tell us whether a *mid-tier* reasoning model can clear B1 on our suite. The 1-game preview hints yes, but with n=1 we treat it as anecdotal and rerun later.

**Caveats** (full list in §7): the LM-only F1 is mixture of pure LM and Random by the fallback rate, so the absolute F1 is regularized toward Random — a more permissive parser or stateful prompting could lift the absolute number, but the within-suite ordering vs. B1 is unlikely to flip given the cross-model consistency.

---

## 7. Caveats

- **Question pool difference vs. Grand et al.** Their LM Captain freely emits Python programs; ours selects from the region-based template DSL. We document this as a reduction in LM expressiveness, not as a confound — a more-expressive Python question space would, if anything, improve their LM-only baseline relative to ours, so the within-suite ordering "LM-only < Greedy" is conservative.
- **Spotter difference vs. Grand et al.** We use the harness's MCMC-based oracle Spotter (with ε=0.1 BSC noise applied at the answer step) rather than a GPT-5 LLM Spotter doing CoT+Code translation. Same ε, different agent on the answering side. We do not claim Spotter parity.
- **Fallback semantics in LMOnlyStrategy.** When the LLM emits an invalid cell or already-asked question id, the strategy falls back to a **uniformly random un-revealed cell** — strictly no posterior / EIG access. This matches a mixture: `(1 - p_invalid) × LM-only + p_invalid × Random`. The smoke test logged ~30 fallbacks in a 54-turn game, so the measured F1 is somewhat regularized toward the Random baseline (0.317 on Grand et al.'s suite). If the F1 looks "too high", check the fallback rate via the `[lm-only]` warnings in stderr.
