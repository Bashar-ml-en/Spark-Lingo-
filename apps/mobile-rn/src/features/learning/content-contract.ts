import { z } from 'zod';

const contentId = z
  .string()
  .regex(
    /^[a-z][a-z0-9_-]{2,79}$/,
    'Use a stable lowercase identifier with letters, numbers, hyphens, or underscores.',
  );
const languageCode = z
  .string()
  .regex(/^[a-z]{2,3}(-[A-Z]{2})?$/, 'Use a BCP-47 language or locale code.');
const text = (maximum: number) => z.string().trim().min(1).max(maximum);

const signoffSchema = z
  .object({
    status: z.enum(['pending', 'approved', 'rejected']),
    approvalReference: text(200).optional(),
    signedAt: z.string().datetime({ offset: true }).optional(),
  })
  .strict();

const reviewSchema = z
  .object({
    learningDesigner: signoffSchema,
    nativeLanguageReviewer: signoffSchema,
  })
  .strict();

const sourceSchema = z
  .object({
    provider: text(120),
    sourceReference: text(240),
    licence: text(160),
    attribution: text(500),
    rightsStatus: z.enum(['pending', 'cleared', 'rejected']),
  })
  .strict();

const objectiveSchema = z
  .object({
    id: contentId,
    canDo: text(280),
    skill: z.enum(['listening', 'reading', 'speaking', 'writing', 'interaction']),
    evidence: text(280),
  })
  .strict();

const exerciseSchema = z
  .object({
    id: contentId,
    kind: z.enum(['recognition', 'typed_recall', 'guided_writing']),
    prompt: text(600),
    acceptedAnswers: z.array(text(300)).min(1).max(20),
    distractors: z.array(text(300)).max(8),
    hint: text(400),
    outcomeRefs: z.array(contentId).min(1).max(6),
    remediation: text(500),
    source: sourceSchema,
    flashcardId: contentId.optional(),
  })
  .strict();

const lessonSchema = z
  .object({
    id: contentId,
    title: text(160),
    description: text(500),
    prerequisiteLessonIds: z.array(contentId).max(12),
    review: reviewSchema,
    exercises: z.array(exerciseSchema).min(1).max(30),
  })
  .strict();

const unitSchema = z
  .object({
    id: contentId,
    title: text(160),
    description: text(500),
    prerequisiteUnitIds: z.array(contentId).max(12),
    lessons: z.array(lessonSchema).min(1).max(40),
  })
  .strict();

export const courseManifestSchema = z
  .object({
    schemaVersion: z.literal('1.0'),
    courseKey: contentId,
    contentVersion: z
      .string()
      .regex(/^\d+\.\d+\.\d+(?:-[a-z0-9.]+)?$/, 'Use a semantic content version.'),
    interfaceLocale: languageCode,
    targetLanguageCode: languageCode,
    title: text(160),
    learnerEntryAssumption: text(500),
    purpose: text(500),
    capabilities: z
      .object({
        audioCoverage: z.enum(['none', 'partial', 'complete']),
        aiRequired: z.literal(false),
        voiceRequired: z.literal(false),
      })
      .strict(),
    publication: z
      .object({
        state: z.enum(['draft', 'published', 'revoked']),
        releaseApprovals: reviewSchema,
        rollbackVersion: z.string().trim().min(1).max(80).nullable(),
      })
      .strict(),
    objectives: z.array(objectiveSchema).min(1).max(40),
    units: z.array(unitSchema).min(1).max(30),
  })
  .strict();

export type CourseManifest = z.infer<typeof courseManifestSchema>;
export type CourseExercise = z.infer<typeof exerciseSchema>;

export class ContentManifestValidationError extends Error {
  constructor(readonly issues: readonly string[]) {
    super(`Content manifest is not publishable: ${issues.join(' ')}`);
    this.name = 'ContentManifestValidationError';
  }
}

function isApproved(signoff: z.infer<typeof signoffSchema>): boolean {
  return (
    signoff.status === 'approved' &&
    Boolean(signoff.approvalReference) &&
    Boolean(signoff.signedAt)
  );
}

function requireUniqueIds(
  ids: readonly string[],
  label: string,
  issues: string[],
): void {
  const duplicate = ids.find((id, index) => ids.indexOf(id) !== index);
  if (duplicate) {
    issues.push(`${label} identifier "${duplicate}" is duplicated.`);
  }
}

/**
 * Parses the repository content contract and enforces the editorial rules
 * that JSON Schema alone cannot express. A draft can be used for authoring,
 * but only a complete, signed package can ever be marked published.
 */
export function parseCourseManifest(input: unknown): CourseManifest {
  const parsed = courseManifestSchema.safeParse(input);
  if (!parsed.success) {
    throw new ContentManifestValidationError(
      parsed.error.issues.map((issue) => `${issue.path.join('.') || 'root'}: ${issue.message}`),
    );
  }

  const manifest = parsed.data;
  const issues: string[] = [];
  const objectiveIds = manifest.objectives.map((objective) => objective.id);
  const unitIds = manifest.units.map((unit) => unit.id);
  const lessons = manifest.units.flatMap((unit) => unit.lessons);
  const lessonIds = lessons.map((lesson) => lesson.id);
  const exercises = lessons.flatMap((lesson) => lesson.exercises);

  requireUniqueIds(objectiveIds, 'Objective', issues);
  requireUniqueIds(unitIds, 'Unit', issues);
  requireUniqueIds(lessonIds, 'Lesson', issues);
  requireUniqueIds(
    exercises.map((exercise) => exercise.id),
    'Exercise',
    issues,
  );

  for (const unit of manifest.units) {
    for (const prerequisiteId of unit.prerequisiteUnitIds) {
      if (!unitIds.includes(prerequisiteId) || prerequisiteId === unit.id) {
        issues.push(`Unit "${unit.id}" has an invalid prerequisite "${prerequisiteId}".`);
      }
    }
  }

  for (const lesson of lessons) {
    for (const prerequisiteId of lesson.prerequisiteLessonIds) {
      if (!lessonIds.includes(prerequisiteId) || prerequisiteId === lesson.id) {
        issues.push(`Lesson "${lesson.id}" has an invalid prerequisite "${prerequisiteId}".`);
      }
    }

    for (const exercise of lesson.exercises) {
      if (exercise.kind === 'recognition' && exercise.distractors.length < 2) {
        issues.push(`Recognition exercise "${exercise.id}" needs at least two distractors.`);
      }
      for (const objectiveId of exercise.outcomeRefs) {
        if (!objectiveIds.includes(objectiveId)) {
          issues.push(`Exercise "${exercise.id}" references unknown objective "${objectiveId}".`);
        }
      }
    }
  }

  if (manifest.publication.state === 'published') {
    if (manifest.objectives.length < 20) {
      issues.push('Published courses require 20–40 measurable objectives.');
    }
    if (
      !isApproved(manifest.publication.releaseApprovals.learningDesigner) ||
      !isApproved(manifest.publication.releaseApprovals.nativeLanguageReviewer)
    ) {
      issues.push('Published courses require release approval from both reviewers.');
    }
    for (const lesson of lessons) {
      if (
        !isApproved(lesson.review.learningDesigner) ||
        !isApproved(lesson.review.nativeLanguageReviewer)
      ) {
        issues.push(`Published lesson "${lesson.id}" is missing a complete reviewer sign-off.`);
      }
      for (const exercise of lesson.exercises) {
        if (exercise.source.rightsStatus !== 'cleared') {
          issues.push(`Published exercise "${exercise.id}" has uncleared source rights.`);
        }
      }
    }
  }

  if (issues.length > 0) {
    throw new ContentManifestValidationError(issues);
  }

  return manifest;
}

export function normalizePracticeAnswer(value: string): string {
  return value.trim().toLocaleLowerCase('en-US').replace(/\s+/g, ' ');
}

export function matchesAcceptedAnswer(exercise: CourseExercise, response: string): boolean {
  const normalizedResponse = normalizePracticeAnswer(response);
  return exercise.acceptedAnswers.some(
    (answer) => normalizePracticeAnswer(answer) === normalizedResponse,
  );
}
