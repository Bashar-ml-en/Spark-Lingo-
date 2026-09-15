import { z } from 'zod';

const environmentSchema = z.enum(['development', 'staging', 'production']);
const deepLinkSchemeSchema = z
  .string()
  .trim()
  .regex(/^[a-z][a-z0-9+.-]*$/, 'must be a valid lowercase URL scheme');

const baseRuntimeConfigSchema = z.object({
  environment: environmentSchema,
  appScheme: deepLinkSchemeSchema,
  supabaseUrl: z.string().trim().url(),
  supabasePublishableKey: z.string().trim().min(16).max(4096),
  oauth: z
    .object({
      googleEnabled: z.boolean().optional(),
      appleEnabled: z.boolean().optional(),
    })
    .optional(),
  legalNotices: z
    .object({
      analyticsUrl: z.string().optional(),
      analyticsVersion: z.string().optional(),
      aiAndVoiceUrl: z.string().optional(),
      aiAndVoiceVersion: z.string().optional(),
    })
    .optional(),
});

export type PublicRuntimeConfig = z.infer<typeof baseRuntimeConfigSchema>;

export type RuntimeConfigResult =
  | { ok: true; config: PublicRuntimeConfig }
  | { ok: false; errors: readonly string[] };

function configurationFailure(errors: readonly string[]): RuntimeConfigResult {
  return { ok: false, errors };
}

function validateUrlPolicy(config: PublicRuntimeConfig): readonly string[] {
  const url = new URL(config.supabaseUrl);
  const errors: string[] = [];

  if (url.username || url.password) {
    errors.push('Supabase URL must not contain user credentials.');
  }

  if (config.environment !== 'development' && url.protocol !== 'https:') {
    errors.push('Staging and production Supabase URLs must use HTTPS.');
  }

  if (config.environment === 'development' && url.protocol === 'http:') {
    const isLoopback = url.hostname === '127.0.0.1' || url.hostname === 'localhost';
    if (!isLoopback) {
      errors.push('Development HTTP URLs must be loopback-only.');
    }
  }

  return errors;
}

function validateKeyPolicy(config: PublicRuntimeConfig): readonly string[] {
  const prohibitedMarkers = ['service_role', 'service-role', 'sb_secret_'];
  const lowerCaseKey = config.supabasePublishableKey.toLowerCase();

  return prohibitedMarkers.some((marker) => lowerCaseKey.includes(marker))
    ? ['Only a Supabase publishable key may be supplied to the mobile client.']
    : [];
}

/**
 * Parses only public build configuration. This module intentionally has no
 * Expo or React Native import so its fail-closed policy is unit-testable.
 */
export function parsePublicRuntimeConfig(input: unknown): RuntimeConfigResult {
  const parsed = baseRuntimeConfigSchema.safeParse(input);
  if (!parsed.success) {
    return configurationFailure(
      parsed.error.issues.map((issue) => {
        const field = issue.path.join('.') || 'configuration';
        return `${field}: ${issue.message}`;
      }),
    );
  }

  const policyErrors = [
    ...validateUrlPolicy(parsed.data),
    ...validateKeyPolicy(parsed.data),
  ];

  return policyErrors.length > 0
    ? configurationFailure(policyErrors)
    : { ok: true, config: parsed.data };
}
