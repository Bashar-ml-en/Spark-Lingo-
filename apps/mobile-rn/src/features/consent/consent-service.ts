import type { SupabaseClient } from '@supabase/supabase-js';

import type { ConsentPurpose, LegalNotice } from './legal-notices';

type RpcResult = { data: unknown; error: unknown };
type ConsentRpcClient = {
  rpc: (name: string, args: Record<string, string>) => PromiseLike<RpcResult>;
};

export class ConsentActionError extends Error {
  constructor(readonly userMessage: string) {
    super(userMessage);
    this.name = 'ConsentActionError';
  }
}

function consentRpcClient(client: SupabaseClient): ConsentRpcClient {
  return client as unknown as ConsentRpcClient;
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

function firstRecord(value: unknown): Record<string, unknown> | undefined {
  if (Array.isArray(value)) {
    return asRecord(value[0]);
  }
  return asRecord(value);
}

function rpcFailure(): ConsentActionError {
  // Do not surface raw database or policy details in the UI.
  return new ConsentActionError(
    'We could not verify your permission. This feature remains off until it can be confirmed.',
  );
}

function noticeFailure(): ConsentActionError {
  return new ConsentActionError(
    'The current privacy notice is unavailable, so this permission cannot be changed.',
  );
}

function documentParameters(purpose: ConsentPurpose, notice: LegalNotice) {
  return {
    p_document_key: purpose,
    p_document_version: notice.version,
  };
}

/** Queries server-authoritative consent. Every unexpected response is denied. */
export async function hasCurrentConsent(
  client: SupabaseClient,
  purpose: ConsentPurpose,
  notice: LegalNotice | undefined,
): Promise<boolean> {
  if (!notice) {
    return false;
  }

  const { data, error } = await consentRpcClient(client).rpc(
    'has_current_user_consent',
    documentParameters(purpose, notice),
  );
  if (error) {
    throw rpcFailure();
  }

  const record = firstRecord(data);
  return record?.has_consent === true;
}

/** Records a consent event without accepting a user ID or timestamp from UI code. */
export async function recordCurrentConsent(
  client: SupabaseClient,
  purpose: ConsentPurpose,
  notice: LegalNotice | undefined,
): Promise<void> {
  if (!notice) {
    throw noticeFailure();
  }

  const { data, error } = await consentRpcClient(client).rpc(
    'record_user_consent',
    documentParameters(purpose, notice),
  );
  if (error || typeof firstRecord(data)?.accepted_at !== 'string') {
    throw rpcFailure();
  }
}

/** Withdraws only the named purpose/version through the authenticated RPC. */
export async function withdrawCurrentConsent(
  client: SupabaseClient,
  purpose: ConsentPurpose,
  notice: LegalNotice | undefined,
): Promise<void> {
  if (!notice) {
    throw noticeFailure();
  }

  const { data, error } = await consentRpcClient(client).rpc(
    'withdraw_user_consent',
    documentParameters(purpose, notice),
  );
  if (error || data !== true) {
    throw rpcFailure();
  }
}
