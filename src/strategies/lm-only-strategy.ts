/**
 * LM-only Captain (Grand et al. 2025, Table tab:captain-comparison row "LM").
 *
 * Pure language-model policy: no posterior, no EIG, no decision rule.
 * The LLM is asked each turn to either shoot a cell or pick one question
 * from the (un-asked) template pool.
 *
 * Notes vs. Grand et al. baseline:
 * - Their LM Captain freely emits Python programs as questions; ours picks
 *   from the template DSL. The Spotter side of our harness is template-only.
 * - On parse failure / invalid output we fall back to a uniformly random
 *   un-revealed cell. Falling back to a posterior-driven choice would defeat
 *   the "no posterior" condition.
 */
import { TOTAL_CELLS, cellIdToIndex, indexToCellId } from "../domain/types.js";
import type { LLMClient } from "../llm/client.js";
import {
  getTemplateQuestions,
  type QuestionDescriptor,
} from "../questions/template-questions.js";
import type { Strategy, TurnContext, TurnDecision } from "./strategy.js";

const SYSTEM_PROMPT = `You are the Captain in a Collaborative Battleship game on an 8x8 grid.

Hidden ships occupy 14 cells across 3 ships of lengths 2, 3, and 4. Your goal is to hit every ship cell in as few shots as possible. Each turn you may either:
  (a) SHOOT a single cell — answer is hit/miss, possibly noisy.
  (b) ASK one yes/no question (region-based) from the available list — answer is yes/no, possibly noisy.

Budgets: at most 40 shots and at most 15 questions per game. Each question may be asked at most once.

Reply with EXACTLY one line, in one of these forms (case-insensitive, no extra commentary):
  shoot <CELL>            e.g. shoot E5
  question <QUESTION_ID>  e.g. question row:C
`;

interface ParsedAction {
  kind: "shoot" | "question";
  arg: string;
}

export class LMOnlyStrategy implements Strategy {
  name = "lm-only";

  constructor(
    private readonly llm: LLMClient,
    private readonly maxQuestionsListed: number = 96,
  ) {}

  async decideTurn(ctx: TurnContext): Promise<TurnDecision> {
    const revealed = ctx.gameState.getRevealedCellIndices();
    const questionsRemaining = (ctx.bridge.data.questionsRemaining as number) ?? 0;
    const turnNumber = (ctx.bridge.data.turnNumber as number) ?? 0;
    const shotsRemaining = (ctx.bridge.data.shotsRemaining as number) ?? 0;
    const hitCount = (ctx.bridge.data.hitCount as number) ?? 0;
    const missCount = (ctx.bridge.data.missCount as number) ?? 0;

    const availableQuestions: QuestionDescriptor[] = [];
    if (questionsRemaining > 0) {
      for (const question of getTemplateQuestions()) {
        if (ctx.askedQuestions.has(question.id)) continue;
        if (ctx.askedQuestions.has(question.text)) continue;
        availableQuestions.push(question);
        if (availableQuestions.length >= this.maxQuestionsListed) break;
      }
    }

    const userPrompt = this.buildUserPrompt({
      board: ctx.gameState.toAscii(),
      questionLog: this.formatQuestionLog(ctx),
      turnNumber,
      shotsRemaining,
      questionsRemaining,
      hitCount,
      missCount,
      questions: availableQuestions,
    });

    let response: string;
    try {
      response = await this.llm.chat([
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: userPrompt },
      ]);
    } catch (error) {
      console.warn(`[lm-only] LLM call failed at turn ${turnNumber}:`, error);
      return this.fallbackShoot(ctx, revealed);
    }

    const parsed = parseResponse(response);
    if (!parsed) {
      console.warn(`[lm-only] Could not parse LLM response: ${truncate(response)}`);
      return this.fallbackShoot(ctx, revealed);
    }

    if (parsed.kind === "shoot") {
      const cellId = parsed.arg.toUpperCase();
      const idx = cellIdToIndex(cellId);
      if (idx < 0 || idx >= TOTAL_CELLS || revealed.has(idx)) {
        console.warn(`[lm-only] Invalid shoot target "${parsed.arg}" at turn ${turnNumber}`);
        return this.fallbackShoot(ctx, revealed);
      }
      return { action: "shoot", cellId };
    }

    if (questionsRemaining <= 0) {
      console.warn(`[lm-only] LLM asked a question with budget 0 at turn ${turnNumber}`);
      return this.fallbackShoot(ctx, revealed);
    }

    const candidate = availableQuestions.find((q) => q.id === parsed.arg)
      ?? availableQuestions.find((q) => q.id.toLowerCase() === parsed.arg.toLowerCase())
      ?? availableQuestions.find((q) => q.text.toLowerCase() === parsed.arg.toLowerCase());

    if (!candidate) {
      const reason = ctx.askedQuestions.has(parsed.arg) ? "already-asked" : "unknown";
      console.warn(`[lm-only] LLM picked ${reason} question id "${parsed.arg}"`);
      return this.fallbackShoot(ctx, revealed);
    }

    ctx.askedQuestions.add(candidate.id);
    return {
      action: "question",
      questionId: candidate.id,
      questionText: candidate.text,
      questionSource: "template",
      evaluate: candidate.evaluate,
    };
  }

  private fallbackShoot(ctx: TurnContext, revealed: Set<number>): TurnDecision {
    const candidates: number[] = [];
    for (let i = 0; i < TOTAL_CELLS; i++) {
      if (!revealed.has(i)) candidates.push(i);
    }
    if (candidates.length === 0) {
      return { action: "shoot", cellId: indexToCellId(0) };
    }
    const picked = candidates[ctx.rng.nextInt(candidates.length)] ?? candidates[0];
    return { action: "shoot", cellId: indexToCellId(picked) };
  }

  private formatQuestionLog(ctx: TurnContext): string {
    const entries: string[] = [];
    for (const question of ctx.gameState.questions.values()) {
      if (typeof question.answer !== "boolean") continue;
      entries.push(`  - "${question.text}" → ${question.answer ? "yes" : "no"}`);
    }
    return entries.join("\n");
  }

  private buildUserPrompt(args: {
    board: string;
    questionLog: string;
    turnNumber: number;
    shotsRemaining: number;
    questionsRemaining: number;
    hitCount: number;
    missCount: number;
    questions: QuestionDescriptor[];
  }): string {
    const segments: string[] = [];
    segments.push(`Board (Captain's view; X=hit, O=miss, -=unknown):\n${args.board}`);

    segments.push(
      `Turn: ${args.turnNumber} | Shots remaining: ${args.shotsRemaining} | Questions remaining: ${args.questionsRemaining} | Hits: ${args.hitCount} / 14 ship cells | Misses: ${args.missCount}`,
    );

    if (args.questionLog) {
      segments.push(`Past Q&A (with possible noise ε=0.1):\n${args.questionLog}`);
    }

    if (args.questionsRemaining > 0 && args.questions.length > 0) {
      const lines = args.questions.map((q) => `  ${q.id} — ${q.text}`).join("\n");
      segments.push(`Available questions (each may be asked at most once):\n${lines}`);
    } else {
      segments.push("Question budget exhausted — you must shoot.");
    }

    segments.push(
      "Reply with exactly one line: `shoot <CELL>` or `question <QUESTION_ID>`. No other text.",
    );

    return segments.join("\n\n");
  }
}

function parseResponse(response: string): ParsedAction | null {
  const trimmed = response.trim();
  if (!trimmed) return null;

  for (const rawLine of trimmed.split(/\r?\n/)) {
    const line = stripBackticks(rawLine).trim();
    if (!line) continue;

    const shootMatch = line.match(/\bshoot\s+([A-Ha-h]\s*\d)\b/);
    if (shootMatch) {
      return { kind: "shoot", arg: shootMatch[1].replace(/\s+/g, "") };
    }

    const questionMatch = line.match(/\bquestion\s+([A-Za-z0-9:_\-]+)\b/);
    if (questionMatch) {
      return { kind: "question", arg: questionMatch[1] };
    }
  }

  return null;
}

function stripBackticks(line: string): string {
  return line.replace(/^[`*\s]+/, "").replace(/[`*\s]+$/, "");
}

function truncate(text: string, max: number = 160): string {
  const single = text.replace(/\s+/g, " ").trim();
  return single.length <= max ? single : `${single.slice(0, max)}…`;
}
