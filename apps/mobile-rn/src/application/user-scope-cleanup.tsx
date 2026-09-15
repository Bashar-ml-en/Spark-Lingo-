import { type QueryClient } from '@tanstack/react-query';
import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type PropsWithChildren,
} from 'react';

export type UserScopeCleanupReason =
  | 'signed-out'
  | 'session-expired'
  | 'identity-changed'
  | 'account-deleted';

export type UserScopeCleanup = (reason: UserScopeCleanupReason) => void;

/**
 * Central registry for local state that belongs to an authenticated user.
 * Owners must synchronously discard sensitive state in their callback. New
 * drafts, billing UI, telemetry queues, and modal stores may not bypass this
 * boundary.
 */
export class UserScopeCleanupRegistry {
  private readonly callbacks = new Set<UserScopeCleanup>();

  constructor(private readonly clearQueryCache: () => void) {}

  register(callback: UserScopeCleanup): () => void {
    this.callbacks.add(callback);
    return () => this.callbacks.delete(callback);
  }

  clear(reason: UserScopeCleanupReason): void {
    this.clearQueryCache();
    for (const callback of this.callbacks) {
      try {
        callback(reason);
      } catch {
        // One defective optional state owner must not leave another owner's
        // user data behind. Owners are responsible for their own observability.
      }
    }
  }
}

type UserScopeCleanupContextValue = {
  registerUserScopeCleanup: (callback: UserScopeCleanup) => () => void;
  clearUserScope: (reason: UserScopeCleanupReason) => void;
};

const UserScopeCleanupContext = createContext<UserScopeCleanupContextValue | undefined>(
  undefined,
);

export function UserScopeCleanupProvider({
  queryClient,
  children,
}: PropsWithChildren<{ queryClient: QueryClient }>) {
  const [registry] = useState(() => new UserScopeCleanupRegistry(() => queryClient.clear()));
  const registerUserScopeCleanup = useCallback(
    (callback: UserScopeCleanup) => registry.register(callback),
    [registry],
  );
  const clearUserScope = useCallback(
    (reason: UserScopeCleanupReason) => registry.clear(reason),
    [registry],
  );
  const value = useMemo(
    () => ({ registerUserScopeCleanup, clearUserScope }),
    [clearUserScope, registerUserScopeCleanup],
  );

  return (
    <UserScopeCleanupContext.Provider value={value}>
      {children}
    </UserScopeCleanupContext.Provider>
  );
}

export function useUserScopeCleanup(): UserScopeCleanupContextValue {
  const value = useContext(UserScopeCleanupContext);
  if (!value) {
    throw new Error('useUserScopeCleanup must be used inside UserScopeCleanupProvider.');
  }
  return value;
}
