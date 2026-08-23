# Content review record — Tatoeba dataset seed (2026-08-23)

Evidence for CONT-001 (agent-doable portion: automated content QA).
Native-speaker sign-offs remain HUMAN-ONLY and are not covered here.

## Corpus under review

`spark_lingo_pipeline/output/{ms,es,ar,zh}_from_en.json` — 7,997 flashcard
rows generated from Tatoeba weekly dataset exports by
`content_pipeline/download_exports.py` +
`content_pipeline/build_dataset_seed.py`.

## Deterministic review rules (code-decidable, no LLM judgement)

| Rule | Check |
| --- | --- |
| R1 | No duplicate (front, back) pairs within a language |
| R2 | front != back (no identity translations) |
| R3 | No control characters or U+FFFD replacement characters |
| R4 | No corpus meta-artifacts (Tatoeba self-references, URLs, usernames) |
| R5 | Script sanity: ms/es Latin, ar Arabic-script, zh CJK |
| R6 | No empty/whitespace-only fields |
| R7 | Length within flashcards CHECK bounds (1-4000 chars) |

## Findings and disposition

- Pre-clean: 8,000 rows, 17 rows matched the meta-artifact rule.
- 3 rows REMOVED (Bahasa Melayu): self-referential Tatoeba slogans
  ("Tatoeba: where sentences are always sentences..."), not learner
  content.
- 14 rows KEPT: sentences containing the proper name "Muiriel" (Tatoeba's
  canonical test sentence). These are natural, grammatical sentences
  ("Today is June 18th and it is Muiriel's birthday!") and valid practice
  material; the name is a normal vocabulary item.
- Post-clean re-review: **0 remaining hard issues across all 7,997 rows.**

## Licensing

All sentence rows: CC-BY 2.0, attribution string committed per row:
"Sentences © Tatoeba.org contributors (CC-BY 2.0)" — satisfies the
Tatoeba licence requirement to surface attribution (plan: app Credits
screen). No NC-licensed audio is ingested (see pipeline README).

## Remaining HUMAN-ONLY gates (unchanged)

- Native-speaker sign-off per language before `is_reviewed=true` and any
  marketing claim about course content (CONTENT_AND_CLAIMS_REGISTER.md).
- Common Voice (CC0) audio attachment per language tarball.
