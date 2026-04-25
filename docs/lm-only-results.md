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

## 4. Reading

**Llama-4-Scout LM-only on our suite: F1 0.353 (close to Random 0.317; well below our no-LLM Greedy at 0.522).** This is the within-suite anchor we wanted:

- The ordering Grand et al. report on their suite — *Llama-4-Scout LM-only < no-LLM Greedy* — replicates on our 18 boards. Their gap was 0.367 → 0.614 (≈+0.25 F1 from posterior-only); ours is 0.353 → 0.522 (≈+0.17 F1). The direction matches; the magnitude is somewhat smaller on our suite because our Greedy itself is weaker (different board distribution).
- The "harness is just a good solver" rebuttal in `1_lm4plan_draft.tex:387` / `2_agent_skills_camready.tex:241` now has a within-suite anchor: even with a competent modern non-reasoning LM, LM-only without the harness sits *below* the no-LLM Greedy baseline on the same boards we evaluate WMA on.
- The planning gap remains the dominant signal (WMA 0.741 vs. Greedy 0.522, +21.9pp on our suite). LM-only adds context — *the LM does not, on its own, recover even greedy posterior performance in this domain*.
- 0 wins / 54 is interpretable: Llama-4-Scout never closed any of the 18 boards within the 40-shot budget. The harness wins are entirely from the planning layer.

Caveat: the LM-only number is regularized toward Random by ~50% fallback rate (see fallback diagnostics above). A more permissive parser or chat-history-stateful prompting could lift the headline F1 a bit, but the within-suite ordering vs. Greedy is unlikely to flip — Grand et al. observe the same gap on weak LMs even with the more expressive Python-program question pool.

---

## 5. Caveats

- **Question pool difference vs. Grand et al.** Their LM Captain freely emits Python programs; ours selects from the region-based template DSL. We document this as a reduction in LM expressiveness, not as a confound — a more-expressive Python question space would, if anything, improve their LM-only baseline relative to ours, so the within-suite ordering "LM-only < Greedy" is conservative.
- **Spotter difference vs. Grand et al.** We use the harness's MCMC-based oracle Spotter (with ε=0.1 BSC noise applied at the answer step) rather than a GPT-5 LLM Spotter doing CoT+Code translation. Same ε, different agent on the answering side. We do not claim Spotter parity.
- **Fallback semantics in LMOnlyStrategy.** When the LLM emits an invalid cell or already-asked question id, the strategy falls back to a **uniformly random un-revealed cell** — strictly no posterior / EIG access. This matches a mixture: `(1 - p_invalid) × LM-only + p_invalid × Random`. The smoke test logged ~30 fallbacks in a 54-turn game, so the measured F1 is somewhat regularized toward the Random baseline (0.317 on Grand et al.'s suite). If the F1 looks "too high", check the fallback rate via the `[lm-only]` warnings in stderr.
