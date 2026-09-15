import { describe, expect, it } from 'vitest';

import { parsePublicRuntimeConfig } from './runtime-config';

const validDevelopmentConfig = {
  environment: 'development',
  appScheme: 'sparklingo-development',
  supabaseUrl: 'http://127.0.0.1:54321',
  supabasePublishableKey: 'sb_publishable_local_testing_key',
};

describe('parsePublicRuntimeConfig', () => {
  it('accepts an explicit loopback development configuration', () => {
    const result = parsePublicRuntimeConfig(validDevelopmentConfig);

    expect(result).toEqual({ ok: true, config: validDevelopmentConfig });
  });

  it('rejects an incomplete configuration instead of constructing a client', () => {
    const result = parsePublicRuntimeConfig({ environment: 'staging' });

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.errors).toContainEqual(expect.stringContaining('supabaseUrl'));
    }
  });

  it('rejects insecure staging transport', () => {
    const result = parsePublicRuntimeConfig({
      ...validDevelopmentConfig,
      environment: 'staging',
      supabaseUrl: 'http://staging.example.test',
    });

    expect(result).toEqual({
      ok: false,
      errors: ['Staging and production Supabase URLs must use HTTPS.'],
    });
  });

  it('rejects a service credential placed in public configuration', () => {
    const result = parsePublicRuntimeConfig({
      ...validDevelopmentConfig,
      supabasePublishableKey: 'service_role_must_never_be_here',
    });

    expect(result).toEqual({
      ok: false,
      errors: ['Only a Supabase publishable key may be supplied to the mobile client.'],
    });
  });

  it('requires a lowercase native deep-link scheme', () => {
    const result = parsePublicRuntimeConfig({
      ...validDevelopmentConfig,
      appScheme: 'Spark Lingo',
    });

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.errors).toContainEqual(expect.stringContaining('appScheme'));
    }
  });
});
