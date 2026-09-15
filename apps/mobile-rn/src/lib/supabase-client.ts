import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { AppState, Platform } from 'react-native';
import 'react-native-url-polyfill/auto';

import type { PublicRuntimeConfig } from '../config/runtime-config';
import { SecureSessionStorage } from './secure-session-storage';

export function createSupabaseClient(
  config: PublicRuntimeConfig,
): SupabaseClient {
  if (Platform.OS === 'web') {
    throw new Error('Authenticated React Native web is not approved.');
  }

  return createClient(config.supabaseUrl, config.supabasePublishableKey, {
    auth: {
      storage: new SecureSessionStorage(),
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  });
}

/** Starts and stops token refresh with the native app lifecycle. */
export function attachForegroundTokenRefresh(client: SupabaseClient): () => void {
  const subscription = AppState.addEventListener('change', (state) => {
    if (state === 'active') {
      client.auth.startAutoRefresh();
    } else {
      client.auth.stopAutoRefresh();
    }
  });

  return () => subscription.remove();
}
