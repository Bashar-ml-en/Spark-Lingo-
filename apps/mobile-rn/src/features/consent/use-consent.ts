import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { useAuthSession } from '../../application/auth-session';
import { useRuntimeConfig, useSupabaseClient } from '../../application/app-providers';
import {
  hasCurrentConsent,
  recordCurrentConsent,
  withdrawCurrentConsent,
} from './consent-service';
import { legalNoticeFor, type ConsentPurpose } from './legal-notices';

export type ConsentStatus =
  | 'signed-out'
  | 'unavailable'
  | 'loading'
  | 'granted'
  | 'denied'
  | 'error';

export function useConsent(purpose: ConsentPurpose) {
  const client = useSupabaseClient();
  const config = useRuntimeConfig();
  const { session } = useAuthSession();
  const queryClient = useQueryClient();
  const notice = legalNoticeFor(config, purpose);
  const userId = session?.user.id;
  const queryKey = ['consent', userId, purpose, notice?.version] as const;
  const query = useQuery({
    queryKey,
    enabled: Boolean(userId && notice),
    queryFn: () => hasCurrentConsent(client, purpose, notice),
  });
  const invalidate = async () => queryClient.invalidateQueries({ queryKey });
  const accept = useMutation({
    mutationFn: () => recordCurrentConsent(client, purpose, notice),
    onSuccess: invalidate,
  });
  const withdraw = useMutation({
    mutationFn: () => withdrawCurrentConsent(client, purpose, notice),
    onSuccess: invalidate,
  });

  const status: ConsentStatus = !userId
    ? 'signed-out'
    : !notice
      ? 'unavailable'
      : query.isPending
        ? 'loading'
        : query.isError
          ? 'error'
          : query.data === true
            ? 'granted'
            : 'denied';

  return {
    notice,
    status,
    canProcess: status === 'granted',
    error: query.error ?? accept.error ?? withdraw.error,
    accept: accept.mutateAsync,
    withdraw: withdraw.mutateAsync,
    isMutating: accept.isPending || withdraw.isPending,
  };
}
