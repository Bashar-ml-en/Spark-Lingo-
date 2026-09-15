import type { SupabaseClient } from '@supabase/supabase-js';
import { describe, expect, it, vi } from 'vitest';

import {
  LearningSessionError,
  recordCardReview,
  recordLessonExerciseResponse,
} from './lesson-session-service';

function clientWithRpcResult(data: unknown, error: unknown = null): SupabaseClient {
  return {
    rpc: vi.fn().mockResolvedValue({ data, error }),
  } as unknown as SupabaseClient;
}

describe('lesson session server contract', () => {
  it('uses the server result for exercise correctness and completion', async () => {
    const client = clientWithRpcResult([
      {
        is_correct: true,
        lesson_complete: false,
        completed_required_exercises: 1,
        total_required_exercises: 2,
      },
    ]);

    await expect(
      recordLessonExerciseResponse(client, {
        lessonId: 'say-hello',
        exerciseId: 'recognise-hello',
        languageCode: 'en',
        contentVersion: '1.0.0',
        response: 'Hello',
      }),
    ).resolves.toEqual({
      isCorrect: true,
      lessonComplete: false,
      completedRequiredExercises: 1,
      totalRequiredExercises: 2,
    });
  });

  it('does not turn a failed server call into completed practice', async () => {
    const client = clientWithRpcResult(null, { message: 'permission denied' });

    await expect(
      recordLessonExerciseResponse(client, {
        lessonId: 'say-hello',
        exerciseId: 'recognise-hello',
        languageCode: 'en',
        contentVersion: '1.0.0',
        response: 'Hello',
      }),
    ).rejects.toBeInstanceOf(LearningSessionError);
  });

  it('rejects a malformed review schedule instead of inventing one locally', async () => {
    const client = clientWithRpcResult([{ next_review_at: 'not-a-date' }]);

    await expect(
      recordCardReview(client, {
        cardId: 'hello-card',
        languageCode: 'en',
        rating: 'good',
      }),
    ).rejects.toBeInstanceOf(LearningSessionError);
  });
});
