# Reviewed course-release implementation

This implementation provides the technical path for a small, safe React
Native learning slice. It does **not** mark any course as launch-ready.

## What is implemented

- A strict, test-covered content contract in
  `apps/mobile-rn/src/features/learning/content-contract.ts`.
- An internal draft pilot package in
  `content/courses/ms-en-foundations-pilot/0.1.0-draft.1.json`. It has pending
  rights and reviewer states and is therefore intentionally unpublishable.
- Migration `019_versioned_course_releases.sql`: immutable versioned releases,
  reviewed exercises, attempt records without raw-response retention,
  server-side exercise verification, and server-side SRS scheduling.
- React Native catalogue, course, and lesson screens. They query only current
  server-published releases, validate responses, and preserve honest loading,
  unavailable, and failure states.

## Evidence still required before a learner can see content

1. Content owners must produce a real reviewed package—not convert the pilot
   status fields to `approved` without evidence.
2. Apply migration 019 to a disposable or dedicated staging project first.
   Inspect the generated schema and run anonymous, user-isolation, version,
   exercise-completion, and SRS RPC smoke tests against that project.
3. Import a signed package into `draft` release rows. Record its actual
   SHA-256 and approval references. Do not create a `published` row from the
   example manifest.
4. Run iOS and Android device validation using the actual staging release,
   including offline/error handling and account switching.
5. Attach dated results to the release tracker, then have the named release
   owner decide whether to invite an internal validation cohort.

## Local verification

From `apps/mobile-rn`, run:

```text
npm run validate:content
npm test
npm run typecheck
npm run export:web
```

The first command validates the internal content fixture and rejects a draft
that is merely relabelled as published. The latter commands cannot prove that
a Supabase migration has been applied or that human review has happened.
