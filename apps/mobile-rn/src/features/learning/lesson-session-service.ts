import type { SupabaseClient } from '@supabase/supabase-js';
import { z } from 'zod';

const exerciseResponseSchema = z.object({
  is_correct: z.boolean(),
  lesson_complete: z.boolean(),
  completed_required_exercises: z.number().int().nonnegative(),
  total_required_exercises: z.number().int().positive(),
});

const lessonCompletionSchema = z.object({
  attempts: z.number().int().positive(),
});

const reviewResultSchema = z.object({
  next_review_at: z.string().datetime({ offset: true }),
  interval_days: z.number().int().nonnegative(),
  repetitions: z.number().int().nonnegative(),
  efactor: z.number(),
});

export type ReviewRating = 'again' | 'hard' | 'good' | 'easy';

export class LearningSessionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'LearningSessionError';
  }
}

function oneRpcRow<T>(schema: z.ZodType<T>, data: unknown, failureMessage: string): T {
  const row = Array.isArray(data) ? data[0] : data;
  const parsed = schema.safeParse(row);
  if (!parsed.success) {
    throw new LearningSessionError(failureMessage);
  }
  return parsed.data;
}

export async function recordLessonExerciseResponse(
  client: SupabaseClient,
  input: {
    lessonId: string;
    exerciseId: string;
    languageCode: string;
    contentVersion: string;
    response: string;
  },
): Promise<{
  isCorrect: boolean;
  lessonComplete: boolean;
  completedRequiredExercises: number;
  totalRequiredExercises: number;
}> {
  const result = await client.rpc('record_lesson_exercise_response', {
    p_lesson_id: input.lessonId,
    p_exercise_id: input.exerciseId,
    p_language_code: input.languageCode,
    p_content_version: input.contentVersion,
    p_response: input.response,
  });
  if (result.error) {
    throw new LearningSessionError(
      'Your response could not be verified. No lesson completion was recorded.',
    );
  }

  const row = oneRpcRow(
    exerciseResponseSchema,
    result.data,
    'The practice result was incomplete. No lesson completion was recorded.',
  );
  return {
    isCorrect: row.is_correct,
    lessonComplete: row.lesson_complete,
    completedRequiredExercises: row.completed_required_exercises,
    totalRequiredExercises: row.total_required_exercises,
  };
}

export async function completePublishedLesson(
  client: SupabaseClient,
  input: { lessonId: string; languageCode: string; contentVersion: string },
): Promise<number> {
  const result = await client.rpc('complete_published_lesson', {
    p_lesson_id: input.lessonId,
    p_language_code: input.languageCode,
    p_content_version: input.contentVersion,
  });
  if (result.error) {
    throw new LearningSessionError(
      'This lesson is not ready to complete yet. Finish each required exercise and try again.',
    );
  }
  return oneRpcRow(
    lessonCompletionSchema,
    result.data,
    'The server did not confirm lesson completion. No progress was changed.',
  ).attempts;
}

export async function recordCardReview(
  client: SupabaseClient,
  input: { cardId: string; languageCode: string; rating: ReviewRating },
): Promise<{
  nextReviewAt: string;
  intervalDays: number;
  repetitions: number;
  efactor: number;
}> {
  const result = await client.rpc('record_card_review', {
    p_card_id: input.cardId,
    p_language_code: input.languageCode,
    p_rating: input.rating,
  });
  if (result.error) {
    throw new LearningSessionError(
      'Your review could not be saved. The card remains due until the server confirms a schedule.',
    );
  }
  const row = oneRpcRow(
    reviewResultSchema,
    result.data,
    'The server did not return a review schedule. The card remains due.',
  );
  return {
    nextReviewAt: row.next_review_at,
    intervalDays: row.interval_days,
    repetitions: row.repetitions,
    efactor: row.efactor,
  };
}
