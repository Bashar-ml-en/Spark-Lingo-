import { describe, expect, it } from 'vitest';

import {
  ConsentActionError,
  hasCurrentConsent,
  recordCurrentConsent,
  withdrawCurrentConsent,
} from './consent-service';

const notice = {
  title: 'AI and voice processing notice',
  url: 'https://legal.example.test/ai-and-voice',
  version: '2026.10',
};

function clientWith(data: unknown, error: unknown = null) {
  return {
    rpc: async () => ({ data, error }),
  } as never;
}

describe('consent service', () => {
  it('accepts only an explicit server confirmation', async () => {
    await expect(hasCurrentConsent(clientWith([{ has_consent: true }]), 'ai_processing', notice)).resolves.toBe(true);
    await expect(hasCurrentConsent(clientWith([{ has_consent: 'true' }]), 'ai_processing', notice)).resolves.toBe(false);
    await expect(hasCurrentConsent(clientWith(null), 'ai_processing', notice)).resolves.toBe(false);
  });

  it('does not query when a current approved notice is unavailable', async () => {
    await expect(hasCurrentConsent(clientWith([{ has_consent: true }]), 'analytics', undefined)).resolves.toBe(false);
    await expect(recordCurrentConsent(clientWith({ accepted_at: 'now' }), 'analytics', undefined)).rejects.toBeInstanceOf(ConsentActionError);
  });

  it('requires the exact RPC response shapes for acceptance and withdrawal', async () => {
    await expect(recordCurrentConsent(clientWith({ accepted_at: '2026-09-15T00:00:00Z' }), 'ai_processing', notice)).resolves.toBeUndefined();
    await expect(recordCurrentConsent(clientWith({}), 'ai_processing', notice)).rejects.toBeInstanceOf(ConsentActionError);
    await expect(withdrawCurrentConsent(clientWith(true), 'voice_processing', notice)).resolves.toBeUndefined();
    await expect(withdrawCurrentConsent(clientWith({ withdrawn: true }), 'voice_processing', notice)).rejects.toBeInstanceOf(ConsentActionError);
  });
});
