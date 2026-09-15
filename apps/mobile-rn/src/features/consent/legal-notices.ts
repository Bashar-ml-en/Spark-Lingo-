import type { PublicRuntimeConfig } from '../../config/runtime-config';

export type ConsentPurpose = 'analytics' | 'ai_processing' | 'voice_processing';

export type LegalNotice = {
  title: string;
  url: string;
  version: string;
};

const noticeVersionPattern = /^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/;

function parseNotice(
  title: string,
  urlValue: string | undefined,
  versionValue: string | undefined,
): LegalNotice | undefined {
  const urlText = urlValue?.trim();
  const version = versionValue?.trim();
  if (!urlText || !version || !noticeVersionPattern.test(version)) {
    return undefined;
  }

  try {
    const url = new URL(urlText);
    if (url.protocol !== 'https:' || url.username || url.password) {
      return undefined;
    }
    return { title, url: url.toString(), version };
  } catch {
    return undefined;
  }
}

/**
 * Notice availability is intentionally independent of app boot. An invalid or
 * absent notice disables only the governed action; it never becomes consent by
 * default or falls back to an old source value.
 */
export function legalNoticeFor(
  config: PublicRuntimeConfig,
  purpose: ConsentPurpose,
): LegalNotice | undefined {
  const notices = config.legalNotices;
  if (purpose === 'analytics') {
    return parseNotice(
      'Analytics notice',
      notices?.analyticsUrl,
      notices?.analyticsVersion,
    );
  }

  return parseNotice(
    'AI and voice processing notice',
    notices?.aiAndVoiceUrl,
    notices?.aiAndVoiceVersion,
  );
}
