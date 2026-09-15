import { describe, expect, it } from 'vitest';

import { legalNoticeFor } from './legal-notices';

const config = {
  environment: 'staging' as const,
  appScheme: 'sparklingo-staging',
  supabaseUrl: 'https://example.supabase.co',
  supabasePublishableKey: 'sb_publishable_staging_test_key',
  legalNotices: {
    analyticsUrl: 'https://legal.example.test/analytics',
    analyticsVersion: '2026.09',
    aiAndVoiceUrl: 'https://legal.example.test/ai-and-voice',
    aiAndVoiceVersion: '2026.10',
  },
};

describe('legalNoticeFor', () => {
  it('maps AI and voice purposes to the approved shared notice', () => {
    expect(legalNoticeFor(config, 'ai_processing')).toMatchObject({
      title: 'AI and voice processing notice',
      version: '2026.10',
    });
    expect(legalNoticeFor(config, 'voice_processing')).toMatchObject({
      version: '2026.10',
    });
  });

  it('fails closed when a notice is missing, insecure, or versioned incorrectly', () => {
    expect(legalNoticeFor({ ...config, legalNotices: undefined }, 'analytics')).toBeUndefined();
    expect(
      legalNoticeFor(
        {
          ...config,
          legalNotices: { ...config.legalNotices, analyticsUrl: 'http://legal.example.test' },
        },
        'analytics',
      ),
    ).toBeUndefined();
    expect(
      legalNoticeFor(
        {
          ...config,
          legalNotices: { ...config.legalNotices, analyticsVersion: 'not a version' },
        },
        'analytics',
      ),
    ).toBeUndefined();
  });
});
