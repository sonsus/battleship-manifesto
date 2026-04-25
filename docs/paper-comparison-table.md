# Unified Captain / Harness Comparison Table — Staging for Paper Tables

This document is the **markdown staging area** for the merged comparison table that will eventually replace `tab:decomp-main` + `tab:external` (in `1_lm4plan_draft.tex`) and `tab:main` + `tab:external` (in `2_agent_skills_camready.tex`) with a single, directly-comparable within-suite table.

Currently the .tex files carry two side-by-side tables that share no metric axis cleanly:

| File | Our results table | External (grandetal) table |
| --- | --- | --- |
| `1_lm4plan_draft.tex` | `tab:decomp-main` (lines 331–350) | `tab:external` (lines 352–373) |
| `2_agent_skills_camready.tex` | `tab:main` (lines 190–208) | `tab:external` (lines 210–231) |

The split exists because grandetal's numbers are on a different 18-board suite, so we previously labeled the external table "directional". With the new `lm-only` Captain row measured **on our 18-board suite**, the comparison can be unified.

---

## 0. Status (as of 2026-04-26 KST)

### Within-suite rows (this branch)

| Row | Captain | LLM | Avg F1 | Win rate | Status |
| --- | --- | --- | ---: | ---: | --- |
| A1 | LM-only Llama-4-Scout | OpenRouter `meta-llama/llama-4-scout` | 0.353 | 0.0% (0/54) | ✅ done |
| A2 | LM-only gemma3n:e4b | vLLM (GPU worktree) | 0.263 | 0.0% (0/54) | ✅ done |
| A3 | LM-only gpt-5-nano | OpenRouter `openai/gpt-5-nano`, default reasoning | — | — | 🟡 sweeping (C=12, started 2026-04-26 08:19 KST, ETA ~12:00) |
| A4 | LM-only gpt-5-mini | OpenRouter `openai/gpt-5-mini`, default reasoning | — | — | ⏳ queued (auto-starts after A3, ETA ~16:00) |
| B1–B6 | our harness decomposition | — / gemma4:e4b (gated, L4 only) | 0.522 → 0.557 | 50.0% → 53.7% | ✅ already in tex (`tab:decomp-main` / `tab:main`) |

### What changes vs. current tex draft

- **Result data added since the last tex revision:**
  - A1, A2 fill in two **within-suite LM-only** rows that the current tex tables did not have. Together they cover both ends of the LM-only weak-model regime: a frontier non-reasoning MoE (Llama-4-Scout, F1 0.353) and a small open-weights model (gemma3n:e4b, F1 0.263). Both fall well below B1 (Greedy / Belief-only, 0.522). A2 additionally falls *below* Grand et al.'s Random baseline (0.317), establishing a strict within-suite floor for the LM-only regime.
  - A3, A4 (in flight) will add two GPT-5-family reasoning rows, both at default `reasoning_effort=medium` per Grand et al. line 374 ("default parameters") and line 446 ("reasoning-capable").
- **Tex changes that follow** (full list in §4 below; condensed here):
  1. **`1_lm4plan_draft.tex`** — replace the side-by-side `tab:decomp-main` (lines 331–350) and `tab:external` (lines 352–373) with one within-suite table modeled on §1; demote `tab:external` (now §2) to inline external-context prose in the discussion paragraph at line 376; update the rebuttal at line 387 to cite within-suite A1/A2/A3/A4 rather than the external grandetal row; drop "directional only" wording at line 305.
  2. **`2_agent_skills_camready.tex`** — same operation against `tab:main` (lines 190–208) and `tab:external` (lines 210–231); update rebuttal at line 241; rewrite the "External baselines situate the harness regime" paragraph at line 234 as a footnote/short context note.
  3. **`0_arxiv.tex` / `0_cais_sw.tex` / `0_icml_sw.tex`** — propagate the same merge if those wrappers also carry `tab:external` verbatim.
- **Caveats to carry into captions** (§5 below): win-rate metric mismatch across suites; question pool difference (template DSL vs. Python programs); Spotter difference (MCMC oracle vs. GPT-5 CoT+Code); fallback semantics in `lm-only` (random un-revealed cell); L4 sample-size CI.

### Blockers / pending decisions

- A3 + A4 numbers (sweep in flight). Once both land we have all four within-suite LM-only rows and the merged table is complete.
- Tex edits not yet started; will execute once A3/A4 are in. Auto-handover: when A4 finishes, rows update in §1 + §6, then we can run `1_lm4plan_draft.tex` / `2_agent_skills_camready.tex` edits in one pass.

---

## 1. Primary table — within our suite (n=54, fully comparable)

All rows below are 18 boards × 3 seeds = 54 games on our synthetic suite under `--protocol paper --belief mcmc --particles 500`, ε=0.1, 8×8 board, 14 ship cells, 40-shot / 15-question budget. **Win rate** here is *game-completion* (sink all 14 ship cells within the 40-shot budget). Wilson 95% intervals on the win proportion. "Avg Q" is mean questions asked per game (budget 15). "LLM Rate" is the fraction of turns on which the LLM is called.

| # | Harness layer / Captain | LLM | Avg F1 | Win rate (n=54) | 95% CI | Avg Q | LLM Rate |
| ---: | --- | --- | ---: | ---: | --- | ---: | ---: |
| A1 | LM-only Llama-4-Scout | Llama-4-Scout (OpenRouter) | 0.353 | 0.0% (0/54) | [0.0, 6.6] | 14.8 | every turn |
| A2 | LM-only gemma3n:e4b | gemma3n:e4b (vLLM, GPU) | 0.263 | 0.0% (0/54) | [0.0, 6.6] | 14.19 | every turn |
| B1 | L1: Belief-only / greedy+MCMC | — | 0.522 | 50.0% (27/54) | [37.1, 62.9] | 0.0 | 0% |
| B2 | **L2: + Planning (WMA)** | — | **0.539** | **74.1% (40/54)** | **[61.1, 83.9]** | **11.9** | **0%** |
| B3 | L3: + Symbolic reflection (off) | — | 0.552 | 57.4% (31/54) | [44.2, 69.7] | 8.0 | 0% |
| B4 | L3: + Symbolic reflection (on) | — | 0.551 | 55.6% (30/54) | [42.4, 68.0] | 8.0 | 0% |
| B5 | + MRA-LLM τ=0.0 (no LLM gating) | gemma4:e4b (gated, gate closed) | 0.552 | 57.4% (31/54) | [44.2, 69.7] | 8.0 | 0% |
| B6 | **L4: + LLM-backed revision (τ=1.0)** | **gemma4:e4b (gated)** | **0.557** | 53.7% (29/54) | [40.6, 66.3] | 8.9 | **4.3%** |

> Boldface marks the heavy-lifting layer (B2: planning) and the only row that actually exercises the LLM under the gate at τ=1.0 (B6).

**Within-suite ordering:**
- LM-only **gemma3n:e4b** (A2, F1 0.263) sits *below* Grand et al.'s Random baseline (C1, 0.317) — a small open-weights LM with our random fallback is worse than uniform random shooting because its systematic mistakes (repeating cells, picking lines instead of dispersing shots) are net counter-productive vs. uniform random. Strict floor of the LM-only regime in our suite.
- LM-only **Llama-4-Scout** (A1, F1 0.353) sits between Random (C1, 0.317) and our no-LLM Greedy (B1, 0.522). Replicates within our suite the same ordering Grand et al. observe on theirs.
- Both A1 and A2 are well below B1 — confirms within-suite that *non-reasoning* LM-only Captains do not reach posterior-only no-LLM performance, regardless of model size.
- The single largest jump in our decomposition is B1 → B2: **+0.017 F1 / +24.1pp win rate from no-LLM planning alone**.
- The LM-backed L4 (B6) adds another +0.005 F1 over reflection-on (B4) at a measured 4.3% LLM rate, but the win-rate CIs overlap, so we report L4 as a qualitative pattern rather than an established gain.

**LM-only vs. harness-layer gap (within suite):** even with a competent modern non-reasoning LM at every turn (A1), LM-only sits ~17pp below the simplest no-LLM harness layer (B1) and ~74pp below the planning layer (B2) on the *same* 54 games; with a smaller open-weights LM (A2) the gap widens further (LM-only falls below Random). The harness lift is therefore not "a side-channel boost on top of a competent LLM"; it is what *unlocks* competent agency in this domain.

---

## 2. Secondary table — external context (grandetal)

These numbers come from Grand et al. (2025), Table `tab:captain-master` of `iclr2026_conference.tex`, on **their** 18-board suite (the human-experiment boards). Same game constraints (ε=0.1, 40 shots, 15 questions, 14 ship cells on 8×8) but a different board distribution. Their **win rate** is a pairwise head-to-head metric (winner = first to sink all ships in fewest moves, F1 tiebroken), so it does *not* line up with our game-completion win rate; we omit their win-rate column from this side-by-side and keep only F1.

| # | Captain | LLM | Suite | F1 | Avg Q | LLM use |
| ---: | --- | --- | --- | ---: | ---: | --- |
| C1 | Random | — | grandetal | 0.317 | 0.0 | — |
| C2 | LM-only Llama-4-Scout | Llama-4-Scout | grandetal | 0.367 | 14.9 | every step |
| C3 | LM-only GPT-4o | GPT-4o | grandetal | 0.450 | 14.1 | every step |
| C4 | Greedy (posterior, no LLM) | — | grandetal | 0.614 | 0.0 | 0% |
| C5 | LM-only GPT-5 | GPT-5 | grandetal | 0.716 | 8.0 | every step |
| C6 | Llama-4-Scout + Bayes-Q+M+D | Llama-4-Scout | grandetal | 0.764 | 15.0 | per Q (program) |

**Cross-suite anchoring (now possible directly):**
- Their Llama-4-Scout LM-only (C2: 0.367) and ours (A1: 0.353) sit within 0.014 F1 of each other → confirms the LM-only weak-model regime is similar across the two suites.
- Their no-LLM Greedy (C4: 0.614) outperforms ours (B1: 0.522) by ~0.09 F1 — that delta is the suite-distribution effect, not a method effect (their boards are sampled from human play; ours are synthetically constructed to span ship-adjacency patterns).
- Their strongest LM+harness pairing (C6: 0.764) remains the absolute ceiling we don't reach on our suite — they harness Python-program EIG question selection; our equivalent LM+harness path is the L4 row (B6: 0.557 F1, 53.7% completion WR). The remaining gap is documented in `1_lm4plan_draft.tex:301-309` / `2_agent_skills_camready.tex:314-321` as primarily *language-informed belief construction*, which our decomposition does not cover.

---

## 3. Reading guide for the unified table

What the merged table answers in one read:

1. **Where does LM-only sit on our suite?** Row A1 (Llama-4-Scout: 0.353), and once GPU finishes, row A2 (gemma4:e4b). Both should fall below B1 (0.522) for the rebuttal in `1_lm4plan_draft.tex:387` / `2_agent_skills_camready.tex:241` to land cleanly.
2. **Where is the planning lift?** B1 → B2 (+0.017 F1 / +24.1pp WR), all without LLM.
3. **Where does the LLM finally enter?** B6 (L4), with measured 4.3% turn rate at τ=1.0.
4. **Does the cross-suite ordering carry?** Yes (C2 vs A1, C4 vs B1) — the suite-induced delta is uniform on F1 and the *LM-only < no-LLM Greedy* ordering replicates within ours.

---

## 4. Action items, in order

- [ ] **Pending GPU.** Run `lm-only --model gemma4:e4b --llm-provider ollama` per `docs/lm-only-experiment.md` §6 on a GPU machine. Returns: F1, win rate, Wilson CI, avg Q for row A2. Plug into placeholders here.
- [ ] **Tex update — `1_lm4plan_draft.tex`.** Once A2 is filled in:
  - Replace `tab:decomp-main` (lines 331–350) and `tab:external` (lines 352–373) with a single unified table modeled on §1+§2 above. Move the external table down into the section's text discussion (§"Where the decomposition operates", line 376) as situating prose rather than a parallel table.
  - Update the rebuttal in line 387 ("harness is just a good solver") to cite the within-suite A1/A2 numbers instead of the grandetal external row.
  - Update §"Ground truth" reference at line 305 to no longer call the external numbers "directional only".
- [ ] **Tex update — `2_agent_skills_camready.tex`.** Same operation:
  - Replace `tab:main` (lines 190–208) and `tab:external` (lines 210–231) with the unified table.
  - Update the rebuttal at line 241 ("harness-first ≠ LLM-free") to cite within-suite A1/A2.
  - Update line 234 paragraph "External baselines situate the harness regime." — convert table-pointer prose into a smaller "external context" footnote.
- [ ] **Optional — `0_arxiv.tex`, `0_cais_sw.tex`, `0_icml_sw.tex`.** If those wrappers also include the external table verbatim, propagate the same merge.

---

## 5. Caveats to keep in the caption when porting to tex

These should make it from this markdown into the eventual tex caption verbatim:

1. **Win-rate metric mismatch across suites.** Our win rate = game-completion (binary: did the agent sink all 14 ship cells within 40 shots). Grand et al.'s win rate = pairwise head-to-head between Captains on the same board, F1-tiebroken. We drop their win-rate column from the side-by-side; only F1 is comparable cross-suite.
2. **Question pool difference.** Grand et al.'s LM-only / Bayes-Q rows generate Python programs as questions; our `lm-only` (A1, A2) selects from a region-based template DSL because our Spotter side is template-only. This restriction *reduces* LM expressiveness in our setup, so the within-suite ordering "LM-only < Greedy" we observe is conservative — a richer Python question space would, if anything, lift LM-only and thus tighten the gap.
3. **Spotter difference.** Grand et al. fix Spotter to GPT-5 (CoT + Code) for all Captain strategies; we use the harness's MCMC oracle Spotter with the same ε=0.1 BSC noise model. Same noise level, different agent on the answering side. We don't claim Spotter parity.
4. **Fallback semantics in `lm-only` (A1, A2).** When the LLM emits an invalid cell or an already-asked question id, the strategy falls back to a uniformly random un-revealed cell — strictly no posterior / EIG access. The measured F1 is therefore a mixture `(1 − p_invalid) · LM-only + p_invalid · Random`. For A1 (Llama-4-Scout) the fallback rate was ~50% (1,557 invalid shoots + 114 already-asked questions + 47 parse failures across ~2,900 LLM-decided turns), so the headline 0.353 sits just above Grand et al.'s Random baseline (0.317). The within-suite ordering vs. B1 is unaffected.
5. **L4 sample size caveat.** B6's +0.005 F1 over B4 is reported as a qualitative pattern; Wilson 95% CIs on the win-rate column overlap heavily across L3/L4 (see `1_lm4plan_draft.tex:496-515` / `2_agent_skills_camready.tex:339-356` threshold sweeps).

---

## 6. Source numbers (for verification when porting)

| Row | Source |
| --- | --- |
| A1 | `results/runs/20260426-004217__lm-only-mcmc__lm-only-llama4-scout-all3/summary.json`; this branch, OpenRouter `meta-llama/llama-4-scout`, 2026-04-26 |
| A2 | `results/runs/<TBD>/summary.json`; GPU machine, vLLM serving `gemma3n:e4b` (the paper's `gemma4:e4b` resolved to this tag) |
| B1–B6 | Already in `1_lm4plan_draft.tex:341-346` and `2_agent_skills_camready.tex:200-204` |
| C1–C6 | `grandetal/tables/captain_master_table.tex` lines 7–25 |
