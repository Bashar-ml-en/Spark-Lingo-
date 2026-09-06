# SPARKLINGO MASTER PROMPT — World-Class UI/UX Redesign + Learning Engine + Exam Module

> Copy everything below the line into a fresh agent session and run it against the repo at C:\Users\User\spark-lingo.
> Last updated: 2026-08-26. Research sources verified and extracted on this date.

---

## ROLE

You are a principal product engineer and design-systems lead with deep experience shipping consumer
language-learning apps (Duolingo/Busuu/Anki class). You work at elite engineering standard: every claim
is verified with tools before it is stated, every refactor is tested, and every deliverable is proven
by real command output — never described hypothetically.

## OBJECTIVE (one sentence)

Refactor SparkLingo's UI/UX into a world-class, interactive, retention-optimized design; rebuild the
practice engine around evidence-based second-language acquisition science; and rebuild the exam module
so its structure faithfully mirrors the real official exams each language has — with zero fabrication,
zero assumptions, zero vague output.

## ANTI-HALLUCINATION CONTRACT (non-negotiable)

1. **Evidence before claim.** Run the tool, read the file, or fetch the source before stating anything
   exists or works. Label every inventory item DONE / EXISTS / MISSING / STUB with file:line proof.
2. **No invented facts.** If a fact (exam format, scoring band, pedagogy effect size) cannot be sourced,
   say "UNVERIFIED — research task" and add it to the Research Queue. Do not implement on UNVERIFIED facts.
3. **No silent scope drift.** If a step must deviate from this prompt, state the deviation, the reason,
   and the trade-off before continuing.
4. **Honest failure.** A blocker is reported as a blocker with the exact error text — never papered over
   with plausible-sounding output.
5. **Verify writes.** After any external write (Supabase, deploy), read the state back and quote it.

## VERIFIED CONTEXT (grounded 2026-08-26 — re-verify before building on it)

### Repo state
- Flutter app at C:\Users\User\spark-lingo; HEAD 04d4886; clean tree; flutter analyze clean; 47/47 tests.
- Live deployment: https://spark-lingo.vercel.app (test-deploy to Vercel before any store build).
- Supabase prod ref: dioisitgohusggmwowft; staging: stlzixqtvtfyrcbjappr. Google OAuth live on both.
- Stack: Flutter + flutter_riverpod + go_router + supabase_flutter. Flutter SDK at C:\flutter
  (NOT on PATH — run: export PATH="/c/flutter/bin:$PATH"). Machine: Windows, no GPU, 16GB RAM.

### Key files (audited)
- lib/features/home/home_screen.dart — 2,911 lines, monolith. MUST be decomposed.
- lib/features/exam_prep/mock_exam_screen.dart — STUB: `_submitExam()` simulates submission,
  answer collection is commented out (lines ~51-78). Timer exists; no answer state, no scoring.
- lib/features/exam_prep/exam_readiness_dashboard.dart — hardcoded `progress: 0.65`
  "simplistic progress calculation for visual effect" (~line 52). Must become computed.
- lib/core/services/spaced_repetition_service.dart — SM-2 implemented (EXISTS, correct floor 1.3).
- lib/shared/models/exam.dart — ExamDefinition / MockExam / MockExamSection / UserExamReadiness exist.
- lib/core/services/tts_service.dart, ai_service.dart (Sparky, Gemini via openai_compatible edge fn),
  database_service.dart, consent_service.dart — EXISTS and live.
- Curriculum: 21,600 vocab cards, 15 languages, Tatoeba-sourced (CC-BY), Malay-first bridge for English.

### Research findings (extracted from live sources on 2026-08-26)
**Retention/gamification — Duolingo (sources: trophy.so case study; blakecrosley.com design analysis):**
- XP is the *common currency*: every activity (lesson, league round, challenge) emits XP, which
  simultaneously feeds streaks, league ranking, and achievements. The coupling — not the features —
  is the system.
- Streaks exploit loss aversion: a 180-day user is motivated by not losing 180, not gaining 181.
  Streak freezes measurably extend streaks (Trophy data: 17.19 avg days with freezes for users past day 7).
- Leagues use promotion/demotion; achievements were redesigned with tiered difficulty; friend streaks
  added later. Every mechanic is instrumented and iterated on retention data.
- Design principles: retention beats acquisition; failure must feel safe (gentle animations, never red
  error screens); a character/mascot is a relationship vector enabling emotional stakes; progress must
  be layered and always advancing on multiple axes; lessons are 3-5 min because the barrier is starting.
- Core loop = Hook model: trigger (streak anxiety / notification) → near-zero-friction action →
  immediate reward (XP before the lesson screen closes) → investment (streak/league position).

**Pedagogy — evidence-based techniques (source: gianfrancoconti.com, top-10 research-backed list;
Roediger & Karpicke 2006; Pavlik & Anderson 2005; Bjork & Bjork 1992):**
1. Spaced retrieval practice — recall at expanding intervals under effortful conditions (already
   partially built: SM-2). Retrieval beats re-reading for long-term retention.
2. Input flood with focus on form — high volume of comprehensible input with targeted attention
   nudges to specific forms.
3. Pushed output — force production (write/speak) beyond comfort zone.
4. Task repetition — repeat the same task type with variation.
5. Interaction with feedback — exchange + corrective feedback loop (Sparky AI is the vehicle).
6. Interleaving — mix related items/topics within a session rather than blocked practice.
7. Desirable difficulties — timed responses, delayed recall, generation before being shown the answer.
8. Krashen's comprehensible input combined with SRS accelerates acquisition (curiositybug.com summary).

**Exam reality (sources: examenglish.com CEFR comparison; ltl-school.com HSK guide; topiklab.com TOPIK guide):**
- CEFR A1-C2 is the universal framework; official "can-do" descriptors per level exist.
- Real exams differ per language: HSK (Mandarin, Hanban; HSK 3.0 moving to 9 levels in 2026),
  JLPT (Japanese, N5-N1), TOPIK I/II (Korean; TOPIK II tests Listening, Writing, Reading),
  DELF/DALF (French), IELTS/TOEFL (English; IELTS 6.5-7.5 ≈ C1), MUET (Malaysian English).
- Each has distinct section structure, timing, and scoring bands — mocks must mirror section types
  and timing, not generic quizzes.

## WORKSTREAM A — DESIGN SYSTEM + UI/UX REFACTOR

**A1. Decompose home_screen.dart** (2,911 lines) into: home shell (navigation + state), lesson-path
widget, card/practice widgets, sidebar widget (phase_sidebar exists), per-feature controllers.
No screen file > 500 lines after refactor. Preserve behavior 1:1 before redesigning (tests first).

**A2. Design system (lib/core/design/):** color tokens, type scale (8pt grid), spacing tokens,
radius/shadow tokens, motion durations/curves, component library: PrimaryButton (with the
"3D bottom border" pressed affordance Duolingo-style is fine, but pick ONE premium direction and
document it), ProgressBar, Card, Chip, StreakFlame, XP badge, empty states, skeleton loaders.
Light + dark. Accessibility: WCAG AA contrast, 48dp touch targets, full keyboard/semantics labels.

**A3. Practice screen interaction model:**
- Lesson progress bar at top (continuous, always advancing).
- Immediate feedback on every answer: success = gentle animation + XP count-up *before* leaving the
  screen; failure = supportive, never red-error-shaming (safe-failure principle).
- One-question-per-screen, large tap targets, bottom-sheet answer tray.
- Session length target 3-5 min; micro-commitments everywhere (start cost ≈ zero).
- Sparky AI chat: streaming bubbles, speaking indicator, correction highlights.

**A4. Retention layer (all wired to the single XP currency):**
- Streaks + streak freeze inventory item (user earns freezes; freeze is consumed automatically).
- Daily goal ring on home. XP ledger table in Supabase (xp_events: user_id, source, amount, ts).
- Leagues: BRONZE→DIAMOND weekly cohorts (start with Bronze only + promotion; instrument before
  expanding). Achievements: tiered (1/2/3 stars), tied to real computed stats.
- Loss-aversion messaging: "Your 12-day streak needs 1 lesson today."

**A5. Onboarding:** 3-screen max flow (goal → level guess → first lesson in <90 seconds).

## WORKSTREAM B — PRACTICE / LEARNING ENGINE REFACTOR

**B1. Upgrade SRS:** keep SM-2 as baseline but add FSRS-style option or at minimum:
- Intra-day relearning queue (failed cards return same session, not next day only).
- New-card daily limit + review queue prioritization (due > learning > new).
- Persist per-card stats to Supabase (card_reviews table) for analytics.

**B2. Exercise generator (the core):** build exercise types that map 1:1 to the pedagogy list:
- Retrieval: flashcard recall, L2→L1 and L1→L2 translation, cloze deletion, anagram/word-build.
- Input flood: mini-reading/listening passages drawn from the 21,600-card corpus with focus-on-form
  highlights.
- Pushed output: type-the-answer (no multiple choice) after N exposures; dictation via TTS audio.
- Interleaving: session builder mixes topics once mastery > threshold.
- Interaction: Sparky conversation tasks with corrective feedback captured back into SRS
  (errors mentioned by Sparky become due cards sooner).
- All exercise content MUST derive from existing curriculum data (Tatoeba cards) — no fabricated
  example sentences. If a language lacks data for an exercise type, mark it MISSING, don't invent.

**B3. Adaptive difficulty:** track rolling accuracy per skill; difficulty auto-adjusts;
desirable-difficulty timers only after item is learned (never on first exposure).

**B4. Session stats → motivation loop:** post-lesson screen shows XP earned, accuracy,
items mastered, streak status — the reward moment before exit.

## WORKSTREAM C — EXAM MODULE REFACTOR

**C1. Exam registry (Supabase `exams` table + Dart models):** for each of the 15 languages,
register the REAL official exam(s): display name, issuing body, framework/levels, skills tested,
section structure, timing per section, scoring band, official source URL. Populate by researching
each official body (RESEARCH TASKS below — do not guess formats):
- Mandarin: HSK (note HSK 3.0 9-level transition), JLPT for Japanese N5-N1, TOPIK I/II Korean,
  DELF/DALF French, DELE Spanish, Goethe German, IELTS/TOEFL/MUET English, etc.
- Store schema: exam → levels → sections (skill, order, time_minutes, item_types[], max_score).

**C2. Mock exam engine (replace the stub):**
- Answer state machine per section; per-section countdown matching real exam timing.
- Item types: reading MCQ, cloze, listening (TTS-generated audio for now, flag real audio as
  MISSING), writing (AI-scored via Sparky edge function with rubric prompt), listening comprehension.
- Real submission: save attempt (answers JSON, timing, section scores) to `mock_exam_attempts`.
- Scoring: objective sections scored deterministically; written/speaking sections scored by Sparky
  with the ai_score_disclaimer always shown (exists in codebase).
- Score → CEFR band mapping displayed on readiness dashboard (REPLACE the hardcoded 0.65 with
  computed readiness = weighted attempts history + skill accuracy).

**C3. Readiness dashboard:** current estimated level, target level + date, per-skill radar from real
attempt data, next-best action recommendation (weakest skill → targeted practice deep link).

## WORKSTREAM D — SPARKY AI TUTOR UPGRADE (audited 2026-08-26)

Sparky stack: lib/core/services/ai_service.dart (client, 349 lines) +
supabase/functions/sparky-ai/ (index.ts 974 lines + providers.ts + error_patterns.ts), live on
dioisitgohusggmwowft with Gemini 3.6-flash via openai_compatible. Already strong: JWT-verified
server-authoritative gateway, fail-closed config, quota lifecycle with compensation, prompt-injection
defense, consent ledger, adaptive error-pattern loop (score → error_patterns ledger → next chat
system prompt focus). DO NOT weaken these invariants while upgrading.

**D1 (P0 feel). Streaming + voice-out:**
- Edge function: add SSE streaming to the `chat` action (`stream: true` upstream, chunked
  `text/event-stream` out) behind a client opt-in so the existing JSON envelope stays untouched.
- Flutter: token-by-token bubble rendering, typing indicator, cancel button; speak Sparky's final
  reply via the existing tts_service with a speaker toggle (voice-out default on).

**D2 (P1 power). Modes + level-adaptive tutoring:**
- Conversation modes passed as a server-validated enum (never free text): free_chat, roleplay
  (server-side scenario list per language), correction_focus, grammar_drill. Each maps to a
  server-built system prompt variant; client never composes prompts.
- CEFR-level adaptation: user's current estimated level (from user_profiles / exam readiness)
  injected server-side into the system prompt ("use A2 vocabulary, short sentences").
- Rubric registry: move the 3 hardcoded rubrics into a Supabase table (rubrics: id, exam_id,
  criteria JSON, band descriptors with official source URL). Seed from docs/exam_formats.md
  research (Workstream C Phase 0) — UNVERIFIED rubrics stay out of the registry.

**D3 (P1 loop). Error-pattern coverage:** extend the error-pattern persistence to corrections
Sparky emits during chat (structured correction block in the streamed response, parsed
server-side), not only score actions.

**D4 (P2 reliability). Fallback + memory:**
- Provider fallback chain in providers.ts: primary → fallback kind, one retry on 5xx/timeout
  before returning 503 (only pre-submission or when the first provider never received the
  request; never double-consume quota). Infra ships now; the fallback KEY is a human action —
  until the operator sets it, the chain degrades to single-provider.
- Session persistence: ai_chat_sessions + ai_chat_messages tables (RLS to owner), server-side
  rolling summary field; client loads last N messages + summary on open.
- Alerting: a monitor cron over the operational events (failure-rate threshold) — wire after
  Phase 4.

**Out of scope (flagged UNVERIFIED):** phoneme-level pronunciation scoring — Gemini cannot do it;
needs a dedicated speech-scoring API. Never fake it with text-based guessing.

## EXECUTION PROTOCOL

1. **Phase 0 — Research Queue (do first):** verify each exam's official section structure/timing from
   the issuing body's site; produce docs/exam_formats.md with source URLs per exam. UNVERIFIED items
   are excluded from mocks until sourced.
2. **Phase 1 — Design system + home decomposition** (behavior-preserving; tests must stay 47/47+).
3. **Phase 2 — Practice engine + exercise generator + SRS upgrades.**
4. **Phase 3 — Exam engine + registry + dashboard.**
5. **Phase 4 — Retention layer (XP/streak/league) wired through everything.**
6. **Every phase ends with:** flutter analyze (0 issues), flutter test (all green), build web,
   deploy to Vercel test, verify the deployed URL serves the change (curl + visual), commit with
   conventional message, fetch+rebase origin/main before push (never force-push).
7. **Report format per phase:** what changed (files), DONE/MISSING labels, test output, deployed URL,
   open Research Queue items.

## DEFINITION OF WORLD-CLASS (the bar)

- A first-time user reaches their first completed lesson in <90 seconds.
- Every tap gives feedback within 100ms perceived; every session ends with a reward moment.
- Practice is provably retrieval/spacing/interleaving-based (mapping table in docs/pedagogy.md).
- Every mock exam section cites the official exam structure it mirrors (docs/exam_formats.md).
- Zero TODO-stub submissions; zero hardcoded fake progress values.
- WCAG AA + 60fps on mid-range Android (profile the animations).

## RESEARCH QUEUE (UNVERIFIED as of 2026-08-26 — resolve before implementing C1)

- [ ] HSK 3.0 final level/section structure from chinese.china.org.cn or Hanban official site.
- [ ] JLPT official section structure + timing per N level (jlpt.jp).
- [ ] TOPIK II section order/timing/item counts (topik.go.kr).
- [ ] DELF/DALF format per level (france-education-international.fr).
- [ ] DELE, Goethe-Zertifikat, MUET formats per level.
- [ ] Common Voice CC0 audio availability per language for real listening items (email pending: CONT-002).
