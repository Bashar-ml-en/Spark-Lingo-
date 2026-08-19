# Spark Lingo content and public-claims register

This register prevents marketing or store copy from exceeding the evidence.
Update it before every content or store-listing release.

## Current allowed positioning

> Invite-only, English-interface beginner phrase-practice beta for selected
> target languages, with flashcard review and experimental AI conversation.

## Claims that remain prohibited until approved evidence exists

| Claim | Current status | Required evidence/owner |
| --- | --- | --- |
| Full language course or CEFR A1 coverage | Prohibited | Course map, learning objectives, learning-design review, native-speaker QA, learner validation; Content lead |
| Proven learning outcomes, retention, or fluency | Prohibited | Predefined study/evaluation and statistically valid result; Product research lead |
| Exam prep, placement, readiness, official score, IELTS/TOEFL/certification | Prohibited | Licensed/validated exam content, scoring validation, legal approval; Assessment lead |
| Native/human/professional accent audio | Prohibited | Rights ledger, audio coverage report, native-speaker QA; Audio/content lead |
| Pronunciation scoring accuracy | Prohibited | Evaluation dataset, acceptance threshold, independent validation; AI/assessment lead |
| Eight selectable languages or globally localized UI | Prohibited | Language inventory, localized UI test matrix, support coverage; Localization lead |
| Unlimited or server-protected premium AI | Prohibited | Server entitlement enforcement and lifecycle tests; Billing/backend |
| Child-safe or globally privacy-compliant | Prohibited | Legal age/consent assessment and audited controls; Legal/DPO |
| 100K/1M/10M scale readiness | Prohibited | Capacity model, load/cost/DR evidence; SRE/architecture |

## Publication record template

One row is required for each published unit/lesson/media asset.

| Content ID | Language/locale | Objective/level | Author | Native reviewer | Learning reviewer | Source/licence | Attribution required | Version | QA date | Audio capability | Approval evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| _Add reviewed content only_ |  |  |  |  |  |  |  |  |  |  |  |

## Release process

1. Content owner submits the completed record and supporting rights/review
   evidence.
2. Legal approves source/licence and required attribution.
3. Learning/content reviewers approve language, pedagogical objective, and
   cultural/dialect suitability.
4. Engineering publishes a versioned manifest and records its version against
   learner attempts where relevant.
5. Product updates user-facing copy only after the evidence owner approves the
   specific claim.
6. A content rollback restores the previous manifest without requiring a mobile
   store release.
