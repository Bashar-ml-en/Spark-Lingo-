import * as SecureStore from 'expo-secure-store';

const storageNamespace = 'spark-lingo.auth.v1';

function namespacedKey(key: string): string {
  return `${storageNamespace}.${encodeURIComponent(key)}`;
}

/**
 * A minimal async storage adapter for Supabase Auth. Session material remains
 * in the operating system's protected store; no browser/local preference
 * storage fallback is permitted for the mobile client.
 */
export class SecureSessionStorage {
  async getItem(key: string): Promise<string | null> {
    return SecureStore.getItemAsync(namespacedKey(key), {
      keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
    });
  }

  async setItem(key: string, value: string): Promise<void> {
    await SecureStore.setItemAsync(namespacedKey(key), value, {
      keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
    });
  }

  async removeItem(key: string): Promise<void> {
    await SecureStore.deleteItemAsync(namespacedKey(key), {
      keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
    });
  }
}
