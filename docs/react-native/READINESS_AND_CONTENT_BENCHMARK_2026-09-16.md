# React Native readiness and language-learning content benchmark

**Assessment date:** 2026-09-16
**Scope:** current repository state, including the React Native transition
branch, bundled curriculum, content pipeline, and stated release evidence.
**Decision:** React Native is ready for continued feature-by-feature
development, but **not** for learner-facing parity, a closed beta, or a
world-class language-learning claim. The only safe current positioning remains
the one already approved in the content-and-claims register: an invite-only,
English-interface beginner phrase-practice beta for selected target languages.

This is a capability benchmark, not a claim that any external product is
uniformly better in every area. "World class" here means a transparent
curriculum, credible evidence of learning, reliable multimodal practice,
accessible delivery, and safe product operations.

## Executive readiness view

| Area | Current state | Release interpretation |
| --- | --- | --- |
| React Native identity and privacy | Email/anonymous auth, guarded OAuth callbacks, server-authoritative consent, secure session storage, and account-transition cache clearing are implemented. | Strong foundation; retain it as the required boundary for every later feature. |
| React Native learning experience | No profile/language persistence, curriculum reads, flashcard session, SRS sync, lesson completion, XP/streak, settings/data-rights, AI, voice, billing, or device-parity journeys are ported. | **Not ready for an internal learner cohort.** |
| Bundled phrase corpus | 15 language entries, 150 units, 1,800 lessons, and 21,600 sentence-pair cards are present. | A useful seed corpus, not evidence of a complete course. |
| Content governance | A deterministic review record exists for 7,997 pipeline rows and the licensing intent is documented. The publication register has no completed per-unit/lesson/media records or native-speaker approvals. | No broad content, outcome, audio, or exam claim is authorized. |
| Listening and pronunciation | `assets/audio/` contains only `.gitkeep`; Common Voice ingestion is designed but no language audio coverage is evidenced. | Text/TTS support only; never claim native-speaker audio or validated pronunciation assessment. |
| Production operations | External staging, legal, security rotation, AI, billing, device QA, backup, and store evidence remain blocked or unverified in the release tracker. | **No-go for public release.** |

## Internal-content inventory

The calculation below is from `assets/curriculum/syllabus_master.json` at this
revision, not a marketing estimate.

| Measure | Verified count |
| --- | ---: |
| Target-language entries | 15 |
| Units | 150 |
| Lessons | 1,800 |
| Flashcards | 21,600 |
| Cards per language | 1,440 |
| Cards with a usable `context` field | 0 |
| Duplicate front-text groups | 339 |
| Native audio assets | 0 |

The bundled data has only these fields:

```text
Unit:     id, title, description, lessons
Lesson:   id, title, description, flashcards
Card:     id, front, back, context
```

It has no embedded CEFR/exam level, learning objective, skill, grammar target,
source/attribution record, review state, content version, audio reference,
dialect, register, distractors, acceptable answers, or assessment evidence.
The 339 duplicate front-text groups are not automatically errors—some have
legitimate alternate translations—but they need an editorial choice or clear
dialect/register metadata before a polished course can use them deliberately.

There is also a traceability defect: `LanguageCatalog` says each language has
600 cards, while the live asset contains 1,440. The draft Play listing says
"600 lessons each" and uses an impossible multiplication. That draft must not
be submitted or reused until counts, terminology, scope, and approved claims
are corrected against a versioned manifest.

## Benchmark against credible language-learning practice

The Council of Europe publishes CEFR as structured, skill-specific "can-do"
descriptors rather than a single course label. Leading products publicly
describe CEFR-linked goals, exercises across skills, placement/progress
assessment, and feedback: [CEFR descriptors](https://www.coe.int/en/web/common-european-framework-reference-languages/cefr-descriptors), [Babbel's method](https://www.babbel.com/the-babbel-method), [Busuu course design](https://www.busuu.com/en/it-works/courses), and [Duolingo's published speaking-efficacy methodology](https://blog.duolingo.com/how-well-does-duolingo-teach-speaking-skills/).

| World-class capability | Spark Lingo evidence now | Gap to close |
| --- | --- | --- |
| Explicit level and outcome map | The pipeline has a future CEFR/exam architecture, but the shipped asset has no levels, can-dos, or objectives. | Define a per-language level map; tag each lesson to a reviewed, measurable objective and prerequisite. Do not label a course A1/A2 until reviewed. |
| Skill-balanced instruction | Flashcard sentence pairs and an SRS engine exist. No reviewed grammar progression, listening inventory, writing rubric, or speaking task library is delivered in RN. | Ship a narrow first course with recognition, recall, guided writing, listening, and goal-based speaking tasks—not more raw cards. |
| Diagnostic placement and adaptive plan | No RN placement, mastery model, or goal planner is implemented. | Add a calibrated diagnostic only after a reviewed item bank; use results to choose starting units and review intensity. |
| Feedback quality | Flutter has server-gated AI/correction architecture; RN has only the consent boundary. No validated pronunciation or assessment feedback is ported. | Port canonical AI feedback after content grounding; define feedback rubrics and evaluate them against human-reviewed samples. |
| Human audio and listening | No audio files are included. | Start with licensed Common Voice coverage for one priority language, record coverage/quality/dialect, and add listening tasks only where coverage is adequate. |
| Assessment and efficacy | Current policy correctly prohibits CEFR, exam, fluency, retention, and score claims. | Pre-register outcome measures, run learner studies, use an independent/validated assessment where appropriate, and publish only supportable results. |
| Localization and accessibility | The learner interface is English-first; RN has no localization/RTL/dynamic-type parity layer yet. | Make UI locale independent from target language; test TalkBack/VoiceOver, large text, contrast, RTL scripts, keyboard, and offline states for every supported launch course. |
| Content operations | Pipeline and a register template exist; per-item approvals and a content rollback manifest do not. | Build a versioned content manifest, reviewer workflow, change log, attribution surface, and rollback path before broad distribution. |

## Sequenced content and React Native plan

### Gate 1 — establish one reviewable launch course

Choose **one target language and one learner-interface locale** for the first
React Native cohort. A sensible internal candidate is Malay-interface learners
studying English, because the asset already contains that bridge direction; the
choice still needs a content owner and reviewer confirmation.

For that course, produce a versioned manifest containing:

1. level/entry assumptions and 20–40 CEFR-style can-do objectives;
2. unit and lesson prerequisite graph;
3. vocabulary, grammar, register, dialect, source, licence, attribution, and
   reviewer fields for every item;
4. exercise specifications with correct answers, accepted variants,
   distractors, hints, and remediation links;
5. native-speaker and learning-designer sign-off plus a content rollback ID.

Do not generate unreviewed lessons merely to increase card volume. Content
creation without native-speaker and learning-design review would reduce trust,
not increase readiness.

### Gate 2 — port the free learning core to React Native

Implement, in this order:

1. profile/language selection and reviewed curriculum repository;
2. unit/lesson list plus text-card learn, recognition, typed recall, and SRS;
3. server-authoritative lesson completion, XP, streak, and daily-goal flows;
4. explicit error/offline/loading states, user-scoped cache ownership, and
   feature analytics only after valid consent;
5. content-attribution and capability pages, including a truthful no-audio
   state where audio is absent.

The existing React Native auth/consent slice is the entry prerequisite, not
the learning product itself.

### Gate 3 — validate course quality before widening language coverage

For the first course, measure activation, first-lesson completion, meaningful
recall after 7/30 days, task success by objective, learner-reported clarity,
crash-free sessions, and support issues. Review a statistically and
qualitatively useful cohort with a learning specialist before adding a second
language.

Add each further language only after its own support matrix exists:

| Language | Direction/interface locale | Reviewed levels | Audio coverage | Script/RTL QA | Native review | Approved for RN cohort |
| --- | --- | --- | --- | --- | --- | --- |
| _One row per language; no blanks treated as approved_ |  |  |  |  |  |  |

### Gate 4 — add AI, voice, billing, and assessment only as governed features

- AI must be grounded in the reviewed objective/vocabulary set and retain the
  existing server consent, quota, kill-switch, and truthful-failure behavior.
- Voice needs explicit consent, temporary-file cleanup, audio-quality coverage,
  and physical-device permission/error testing before it is exposed.
- Billing remains off until entitlement/webhook lifecycle evidence exists.
- Exam readiness/certification remains a separate product decision; it cannot
  be inferred from flashcard completion or AI output.

## Current honest product position

**Allowed now:** a development-stage, text-first phrase-practice experience
with flashcard review and carefully gated experimental AI only where all
external controls are verified.

**Not allowed now:** full-course, CEFR-level, exam-prep, score/readiness,
native-audio, validated-pronunciation, proven-fluency, "world-class", or
large-scale platform claims.

## Exit criteria for a first React Native learner cohort

- One reviewed, versioned course manifest with rights and attribution proof.
- React Native parity for language selection, curriculum retrieval, study,
  SRS, completion/progress, settings/legal/data rights, and account deletion.
- Device tests for Android/iOS covering auth, cache/account switch, large text,
  screen reader, offline/error behavior, and the launch language's script
  direction.
- Dedicated staging evidence for RLS, consent withdrawal, and every enabled
  feature boundary.
- Current legal, security, operations, and release-tracker blockers resolved
  with external evidence; source review alone cannot close them.

Only after those conditions are met should the product invite learners beyond
an internal content-validation cohort.
