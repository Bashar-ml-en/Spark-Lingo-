import Constants from 'expo-constants';
import { Platform } from 'react-native';

import {
  parsePublicRuntimeConfig,
  type RuntimeConfigResult,
} from './runtime-config';

/**
 * RN web has not passed the parity/security decision in the migration plan.
 * Refuse to initialize an authenticated client there instead of falling back
 * to browser token storage during this mobile-first transition.
 */
export function loadExpoRuntimeConfig(): RuntimeConfigResult {
  if (Platform.OS === 'web') {
    return {
      ok: false,
      errors: ['React Native web is not approved for authenticated use yet.'],
    };
  }

  const extra = Constants.expoConfig?.extra;
  return parsePublicRuntimeConfig({
    environment: extra?.appEnvironment,
    supabaseUrl: extra?.supabaseUrl,
    supabasePublishableKey: extra?.supabasePublishableKey,
  });
}
