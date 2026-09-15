import type { SupabaseClient } from '@supabase/supabase-js';
import { describe, expect, it, vi } from 'vitest';

import {
  CurriculumRepositoryError,
  loadPublishedCourse,
  publishedCourseQueryKey,
} from './curriculum-repository';

type SupabaseResponse = { data: unknown; error: unknown };

function queryFor(response: SupabaseResponse) {
  const query = {
    select: vi.fn(),
    eq: vi.fn(),
    is: vi.fn(),
    order: vi.fn(),
    maybeSingle: vi.fn(),
  };
  query.select.mockReturnValue(query);
  query.eq.mockReturnValue(query);
  query.is.mockReturnValue(query);
  query.order.mockResolvedValue(response);
  query.maybeSingle.mockResolvedValue(response);
  return query;
}

function clientForCourse(
  release: SupabaseResponse,
  units: SupabaseResponse,
  exercises: SupabaseResponse,
): SupabaseClient {
  return {
    from: vi.fn((table: string) => {
      if (table === 'course_releases') {
        return queryFor(release);
      }
      if (table === 'course_release_units') {
        return queryFor(units);
      }
      if (table === 'lesson_exercises') {
        return queryFor(exercises);
      }
      throw new Error(`Unexpected table ${table}`);
    }),
  } as unknown as SupabaseClient;
}

const release = {
  id: 'be0af7b2-8ee5-46eb-a7f8-77a04daf27f0',
  course_key: 'english-pilot',
  content_version: '1.0.0',
  target_language_code: 'en',
  interface_locale: 'ms-MY',
  title: 'English pilot',
  manifest_checksum: 'c'.repeat(64),
  published_at: '2026-09-16T00:00:00.000Z',
};

describe('published curriculum repository', () => {
  it('includes the user and selected content version in the cache key', () => {
    expect(publishedCourseQueryKey('user-a', 'english-pilot', '1.0.0')).toEqual([
      'published-course',
      'user-a',
      'english-pilot',
      '1.0.0',
    ]);
  });

  it('maps only a complete runtime-validated release', async () => {
    const client = clientForCourse(
      { data: release, error: null },
      {
        data: [
          {
            unit_id: 'greetings-unit',
            order_index: 0,
            units: {
              id: 'greetings-unit',
              title: 'Greetings',
              description: 'Reviewed first unit.',
              source_attribution: 'Source credit',
              is_reviewed: true,
              lessons: [
                {
                  id: 'say-hello',
                  title: 'Say hello',
                  description: 'Practice a greeting.',
                  order_index: 0,
                  flashcards: [
                    {
                      id: 'hello-card',
                      front_text: 'Hello',
                      back_text: 'Hai',
                      context_sentence: null,
                      audio_url: null,
                      source_attribution: 'Source credit',
                    },
                  ],
                },
              ],
            },
          },
        ],
        error: null,
      },
      {
        data: [
          {
            id: 'recognise-hello',
            lesson_id: 'say-hello',
            flashcard_id: 'hello-card',
            order_index: 0,
            exercise_type: 'recognition',
            prompt: 'Choose hello.',
            accepted_answers: ['Hello'],
            distractors: ['Goodbye', 'Please'],
            hint: 'It begins a conversation.',
            remediation: 'Try Hello.',
            outcome_refs: ['greet-someone'],
            is_required: true,
          },
        ],
        error: null,
      },
    );

    await expect(loadPublishedCourse(client, 'english-pilot', '1.0.0')).resolves.toMatchObject({
      release: { contentVersion: '1.0.0' },
      units: [
        {
          id: 'greetings-unit',
          lessons: [
            {
              id: 'say-hello',
              exercises: [{ id: 'recognise-hello', kind: 'recognition' }],
            },
          ],
        },
      ],
    });
  });

  it('rejects a release that does not match the version in the learner route', async () => {
    const client = clientForCourse({ data: release, error: null }, { data: [], error: null }, { data: [], error: null });

    await expect(loadPublishedCourse(client, 'english-pilot', '1.0.1')).rejects.toMatchObject({
      kind: 'version-mismatch',
    } satisfies Partial<CurriculumRepositoryError>);
  });

  it('fails closed when the release checksum is malformed', async () => {
    const client = clientForCourse(
      { data: { ...release, manifest_checksum: 'not-a-checksum' }, error: null },
      { data: [], error: null },
      { data: [], error: null },
    );

    await expect(loadPublishedCourse(client, 'english-pilot')).rejects.toMatchObject({
      kind: 'invalid-response',
    } satisfies Partial<CurriculumRepositoryError>);
  });
});
