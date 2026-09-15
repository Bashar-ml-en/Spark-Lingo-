import type { SupabaseClient } from '@supabase/supabase-js';
import { z } from 'zod';

const contentId = z.string().regex(/^[a-z][a-z0-9_-]{2,79}$/);
const contentVersion = z.string().regex(/^\d+\.\d+\.\d+(?:-[a-z0-9.]+)?$/);
const languageCode = z.string().regex(/^[a-z]{2,3}(-[A-Z]{2})?$/);
const text = (maximum: number) => z.string().trim().min(1).max(maximum);

const courseReleaseSchema = z.object({
  id: z.string().uuid(),
  course_key: contentId,
  content_version: contentVersion,
  target_language_code: languageCode,
  interface_locale: languageCode,
  title: text(160),
  manifest_checksum: z.string().regex(/^[a-f0-9]{64}$/),
  published_at: z.string().datetime({ offset: true }),
});

const flashcardSchema = z.object({
  id: contentId,
  front_text: text(4000),
  back_text: text(4000),
  context_sentence: z.string().nullable(),
  audio_url: z.string().url().nullable(),
  source_attribution: z.string().nullable(),
});

const lessonSchema = z.object({
  id: contentId,
  title: text(160),
  description: z.string().max(500),
  order_index: z.number().int().nonnegative(),
  flashcards: z.array(flashcardSchema),
});

const unitSchema = z.object({
  id: contentId,
  title: text(160),
  description: z.string().max(500),
  source_attribution: z.string().nullable(),
  is_reviewed: z.literal(true),
  lessons: z.array(lessonSchema),
});

const releaseUnitSchema = z.object({
  unit_id: contentId,
  order_index: z.number().int().nonnegative(),
  units: unitSchema,
});

const exerciseSchema = z.object({
  id: contentId,
  lesson_id: contentId,
  flashcard_id: contentId.nullable(),
  order_index: z.number().int().nonnegative(),
  exercise_type: z.enum(['recognition', 'typed_recall', 'guided_writing']),
  prompt: text(600),
  accepted_answers: z.array(text(300)).min(1),
  distractors: z.array(text(300)),
  hint: text(400),
  remediation: text(500),
  outcome_refs: z.array(contentId).min(1),
  is_required: z.boolean(),
});

export type PublishedCourseRelease = {
  id: string;
  courseKey: string;
  contentVersion: string;
  targetLanguageCode: string;
  interfaceLocale: string;
  title: string;
  manifestChecksum: string;
  publishedAt: string;
};

export type CurriculumExercise = {
  id: string;
  lessonId: string;
  flashcardId: string | null;
  orderIndex: number;
  kind: 'recognition' | 'typed_recall' | 'guided_writing';
  prompt: string;
  acceptedAnswers: string[];
  distractors: string[];
  hint: string;
  remediation: string;
  outcomeRefs: string[];
  isRequired: boolean;
};

export type CurriculumLesson = {
  id: string;
  title: string;
  description: string;
  orderIndex: number;
  flashcards: Array<{
    id: string;
    front: string;
    back: string;
    context: string | null;
    audioUrl: string | null;
    sourceAttribution: string | null;
  }>;
  exercises: CurriculumExercise[];
};

export type PublishedCourse = {
  release: PublishedCourseRelease;
  units: Array<{
    id: string;
    title: string;
    description: string;
    sourceAttribution: string | null;
    orderIndex: number;
    lessons: CurriculumLesson[];
  }>;
};

export type CurriculumRepositoryErrorKind =
  | 'not-found'
  | 'transport'
  | 'invalid-response'
  | 'version-mismatch';

export class CurriculumRepositoryError extends Error {
  constructor(readonly kind: CurriculumRepositoryErrorKind, message: string) {
    super(message);
    this.name = 'CurriculumRepositoryError';
  }
}

function parseOrThrow<T>(
  schema: z.ZodType<T>,
  value: unknown,
  userMessage: string,
): T {
  const parsed = schema.safeParse(value);
  if (!parsed.success) {
    throw new CurriculumRepositoryError('invalid-response', userMessage);
  }
  return parsed.data;
}

function toCourseRelease(row: z.infer<typeof courseReleaseSchema>): PublishedCourseRelease {
  return {
    id: row.id,
    courseKey: row.course_key,
    contentVersion: row.content_version,
    targetLanguageCode: row.target_language_code,
    interfaceLocale: row.interface_locale,
    title: row.title,
    manifestChecksum: row.manifest_checksum,
    publishedAt: row.published_at,
  };
}

export function publishedCoursesQueryKey(userId: string): readonly [string, string] {
  return ['published-courses', userId] as const;
}

export function publishedCourseQueryKey(
  userId: string,
  courseKey: string,
  contentVersion: string | undefined,
): readonly [string, string, string, string] {
  return ['published-course', userId, courseKey, contentVersion ?? 'current'] as const;
}

export async function listPublishedCourses(
  client: SupabaseClient,
): Promise<PublishedCourseRelease[]> {
  const response = await client
    .from('course_releases')
    .select(
      'id, course_key, content_version, target_language_code, interface_locale, title, manifest_checksum, published_at',
    )
    .eq('publication_state', 'published')
    .is('revoked_at', null)
    .order('target_language_code', { ascending: true });

  if (response.error) {
    throw new CurriculumRepositoryError(
      'transport',
      'Reviewed courses could not be loaded. Check your connection and try again.',
    );
  }

  return parseOrThrow(
    z.array(courseReleaseSchema),
    response.data,
    'Course information from the server was incomplete. Try again later.',
  ).map(toCourseRelease);
}

export async function loadPublishedCourse(
  client: SupabaseClient,
  courseKey: string,
  expectedContentVersion?: string,
): Promise<PublishedCourse> {
  const releaseResponse = await client
    .from('course_releases')
    .select(
      'id, course_key, content_version, target_language_code, interface_locale, title, manifest_checksum, published_at',
    )
    .eq('course_key', courseKey)
    .eq('publication_state', 'published')
    .is('revoked_at', null)
    .maybeSingle();

  if (releaseResponse.error) {
    throw new CurriculumRepositoryError(
      'transport',
      'This course could not be loaded. Check your connection and try again.',
    );
  }
  if (!releaseResponse.data) {
    throw new CurriculumRepositoryError(
      'not-found',
      'This course is not currently available. Return to course selection and refresh.',
    );
  }

  const release = toCourseRelease(
    parseOrThrow(
      courseReleaseSchema,
      releaseResponse.data,
      'Course release information from the server was incomplete. Try again later.',
    ),
  );
  if (expectedContentVersion && expectedContentVersion !== release.contentVersion) {
    throw new CurriculumRepositoryError(
      'version-mismatch',
      'This course was updated. Return to course selection to load the current version.',
    );
  }

  const [unitResponse, exerciseResponse] = await Promise.all([
    client
      .from('course_release_units')
      .select(
        'unit_id, order_index, units!inner(id, title, description, source_attribution, is_reviewed, lessons!inner(id, title, description, order_index, flashcards(id, front_text, back_text, context_sentence, audio_url, source_attribution)))',
      )
      .eq('course_release_id', release.id)
      .order('order_index', { ascending: true }),
    client
      .from('lesson_exercises')
      .select(
        'id, lesson_id, flashcard_id, order_index, exercise_type, prompt, accepted_answers, distractors, hint, remediation, outcome_refs, is_required',
      )
      .eq('course_release_id', release.id)
      .order('order_index', { ascending: true }),
  ]);

  if (unitResponse.error || exerciseResponse.error) {
    throw new CurriculumRepositoryError(
      'transport',
      'Course exercises could not be loaded. No lesson progress was changed.',
    );
  }

  const unitRows = parseOrThrow(
    z.array(releaseUnitSchema),
    unitResponse.data,
    'Course units from the server were incomplete. Try again later.',
  );
  const exercises = parseOrThrow(
    z.array(exerciseSchema),
    exerciseResponse.data,
    'Course exercises from the server were incomplete. Try again later.',
  );
  if (unitRows.length === 0 || exercises.length === 0) {
    throw new CurriculumRepositoryError(
      'invalid-response',
      'This published course has no complete lesson material. No progress was changed.',
    );
  }

  const exercisesByLesson = new Map<string, CurriculumExercise[]>();
  for (const exercise of exercises) {
    const list = exercisesByLesson.get(exercise.lesson_id) ?? [];
    list.push({
      id: exercise.id,
      lessonId: exercise.lesson_id,
      flashcardId: exercise.flashcard_id,
      orderIndex: exercise.order_index,
      kind: exercise.exercise_type,
      prompt: exercise.prompt,
      acceptedAnswers: exercise.accepted_answers,
      distractors: exercise.distractors,
      hint: exercise.hint,
      remediation: exercise.remediation,
      outcomeRefs: exercise.outcome_refs,
      isRequired: exercise.is_required,
    });
    exercisesByLesson.set(exercise.lesson_id, list);
  }

  const units = unitRows.map((row) => ({
      id: row.units.id,
      title: row.units.title,
      description: row.units.description,
      sourceAttribution: row.units.source_attribution,
      orderIndex: row.order_index,
      lessons: row.units.lessons
        .sort((left, right) => left.order_index - right.order_index)
        .map((lesson) => ({
          id: lesson.id,
          title: lesson.title,
          description: lesson.description,
          orderIndex: lesson.order_index,
          flashcards: lesson.flashcards.map((card) => ({
            id: card.id,
            front: card.front_text,
            back: card.back_text,
            context: card.context_sentence,
            audioUrl: card.audio_url,
            sourceAttribution: card.source_attribution,
          })),
          exercises: (exercisesByLesson.get(lesson.id) ?? []).sort(
            (left, right) => left.orderIndex - right.orderIndex,
          ),
        })),
    }));
  if (units.some((unit) => unit.lessons.some((lesson) => lesson.exercises.length === 0))) {
    throw new CurriculumRepositoryError(
      'invalid-response',
      'This published course has a lesson without verified practice material. No progress was changed.',
    );
  }

  return {
    release,
    units,
  };
}
