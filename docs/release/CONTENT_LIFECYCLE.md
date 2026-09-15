# Spark Lingo content lifecycle

This is the actual release contract. It replaces legacy descriptions of a
complete CEFR/exam curriculum, native audio coverage, and AI-generated
validated courses. Those capabilities are not currently established by the
repository.

## Current evidence boundary

- `assets/curriculum/syllabus_master.json` is a raw phrase corpus, not a
  published language course.
- `assets/audio/` contains no learner-ready audio assets.
- No course may be described as CEFR-aligned, comprehensive, exam preparation,
  reviewed, or outcome-proven until its specific evidence exists.
- The React Native app loads no bundled curriculum fallback. It reads only a
  current server-side published course release.

## Authoring and publication flow

1. An author creates a versioned JSON package under `content/courses/`. Draft
   packages are internal-only and do not become app content.
2. Engineering runs `npm run validate:content` in `apps/mobile-rn`. The Zod
   contract rejects missing objectives, exercises, accepted answers, source
   fields, invalid prerequisites, duplicate IDs, and incomplete published
   evidence.
3. A learning designer, native-language reviewer, and rights owner record
   real approval references for every lesson and exercise. Placeholders,
   shared names, or status labels are not approval evidence.
4. In a dedicated staging project, an operator creates a `draft`
   `course_releases` row, maps only reviewed units, and imports the reviewed
   `lesson_exercises` data from that manifest. This import must record the
   manifest SHA-256, path, and source/approval references.
5. The staging release is exercised on Android and iOS. It must prove that
   anonymous/cross-user access is denied where required, raw learner responses
   are not retained by practice verification, error states remain visible, and
   a prior release can be restored.
6. The release owner changes the row to `published` only when migration 019's
   database gate accepts the complete approval and rights evidence. The RN
   catalogue exposes only this published release.

## Rollback and revocation

Never edit published lesson material in place. Publish a new immutable content
version, retain its manifest/checksum, and use `rollback_release_id` to record
the prior approved release. For a rights or safety problem, mark the affected
release `revoked` with a timestamp; the client must show its unavailable state
instead of stale content.

## Data and learning integrity

- The server verifies accepted answers from published content and stores only
  correctness/attempt state, not raw practice responses.
- Lesson completion is accepted only after all required exercises in the exact
  published version are server-verified.
- The server calculates SRS intervals, repetition count, ease factor, and due
  time. The client may provide an honest review rating but cannot write those
  fields directly through the RN contract.
- There is no fluency, pronunciation, CEFR-level, exam-score, or readiness
  calculation in this flow.
