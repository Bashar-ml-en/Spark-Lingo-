import { readFileSync } from 'node:fs';

import { describe, expect, it } from 'vitest';

import {
  ContentManifestValidationError,
  matchesAcceptedAnswer,
  parseCourseManifest,
} from './content-contract';

const fixtureUrl = new URL(
  '../../../../../content/courses/ms-en-foundations-pilot/0.1.0-draft.1.json',
  import.meta.url,
);
const draftManifest = JSON.parse(readFileSync(fixtureUrl, 'utf8')) as unknown;

describe('course content contract', () => {
  it('accepts the internal authoring pilot but keeps it a draft', () => {
    const manifest = parseCourseManifest(draftManifest);

    expect(manifest.publication.state).toBe('draft');
    expect(manifest.capabilities.audioCoverage).toBe('none');
    expect(manifest.units).toHaveLength(1);
  });

  it('rejects a draft that is relabelled published without the full evidence package', () => {
    const relabelled = structuredClone(draftManifest) as {
      publication: { state: string };
    };
    relabelled.publication.state = 'published';

    expect(() => parseCourseManifest(relabelled)).toThrow(ContentManifestValidationError);
    expect(() => parseCourseManifest(relabelled)).toThrow(
      'Published courses require 20–40 measurable objectives.',
    );
  });

  it('rejects duplicate ids and broken objective references', () => {
    const invalid = structuredClone(draftManifest) as {
      units: Array<{ lessons: Array<{ exercises: Array<{ id: string; outcomeRefs: string[] }> }> }>;
    };
    invalid.units[0]!.lessons[0]!.exercises[1]!.id = 'recognise-hello';
    invalid.units[0]!.lessons[0]!.exercises[1]!.outcomeRefs = ['missing-objective'];

    expect(() => parseCourseManifest(invalid)).toThrow('Exercise identifier "recognise-hello" is duplicated.');
    expect(() => parseCourseManifest(invalid)).toThrow('references unknown objective "missing-objective"');
  });

  it('only treats an explicit accepted answer as correct', () => {
    const manifest = parseCourseManifest(draftManifest);
    const exercise = manifest.units[0]!.lessons[0]!.exercises[1]!;

    expect(matchesAcceptedAnswer(exercise, '  HELLO  ')).toBe(true);
    expect(matchesAcceptedAnswer(exercise, 'Good morning')).toBe(false);
  });
});
