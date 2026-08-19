# Spark Lingo — Antigravity Build Kit

This is the full package to take Spark Lingo from its current prototype
state to a store-ready, multi-language, exam-certification app — built
to be fed directly into Google Antigravity (or any agentic coding
workspace) as a sequence of staged prompts.

## How to use this with Antigravity

1. Open your Spark Lingo repo as the workspace.
2. Go through `prompts/` **in numeric order**, one at a time. Paste each
   file's content as a single prompt/task. Let Antigravity finish and
   verify each stage (build passes, tests pass, screen renders) before
   moving to the next — don't chain all 10 prompts in one shot, or the
   agent loses the thread on earlier decisions and you'll get
   inconsistent theming/naming across stages.
3. `design/` holds the actual data (design tokens, flow spec) that
   prompts 02–04 reference — Antigravity should read these files
   directly rather than you re-typing the values into the prompt.
4. `store_submission/` and `growth/` aren't code prompts — they're
   checklists and copywriting you (or Antigravity, for drafting text)
   work through once the app is feature-complete.

## What's in here

```
spark_lingo_buildkit/
├── README.md                          ← you are here
├── PROJECT_STRUCTURE.md               ← full target lib/ + assets/ tree
├── prompts/
│   ├── 01_project_scaffold.md
│   ├── 02_design_system_and_theming.md
│   ├── 03_onboarding_and_language_selection.md
│   ├── 04_per_language_home_experience.md
│   ├── 05_srs_and_curriculum_engine.md
│   ├── 06_ai_tutor_sparky.md
│   ├── 07_exam_certification_module.md
│   ├── 08_monetization_and_paywall.md
│   ├── 09_qa_accessibility_and_polish.md
│   └── 10_store_submission_build.md
├── design/
│   ├── language_design_tokens.json    ← per-language color/font/flag/motif
│   └── onboarding_flow_spec.md        ← flag-grid → localized-home UX spec
├── growth/
│   ├── aso_keyword_strategy.md
│   └── virality_growth_loops.md
└── store_submission/
    ├── google_play_checklist.md
    ├── apple_app_store_checklist.md
    └── privacy_policy_template.md
```

## Sequencing logic (why this order)

1–2 establish structure and the visual system first, because everything
after depends on both. 3–4 build the registration → language selection →
localized-home flow you specifically asked for. 5–7 are your three core
feature pillars (SRS content, AI tutor, exam module — the last one built
on top of the exam-prep pipeline from the previous package). 8 is
monetization, deliberately after the product is real, not before. 9 is
the unglamorous pass (accessibility, RTL languages, error states) that
store reviewers actually check. 10 is the literal submission build.

## A grounded note before you start

"Going viral" isn't a feature you build — it's a byproduct of (a) a
genuinely differentiated product, (b) organic sharing mechanics built
into the product itself, and (c) sustained ASO/content work after
launch. `growth/` gives you the real, non-hypey version of that: keyword
strategy and loop mechanics you build once and that compound, rather
than a "growth hack." Store review teams (both Apple and Google)
increasingly reject apps that use manipulative growth patterns (fake
urgency, dark-pattern paywalls, deceptive notifications) — the
checklists flag where that line is.
