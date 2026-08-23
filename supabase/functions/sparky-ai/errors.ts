/**
 * Shared error type for the sparky-ai Edge Function.
 *
 * Lives in its own module so the provider adapters (providers.ts) can throw
 * it without importing the request handler (index.ts), which would create a
 * circular dependency.
 *
 * `publicMessage` is deliberately short and allow-listed per code path; raw
 * provider or database error text is never forwarded to clients or logs.
 */
export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    readonly publicMessage: string,
    readonly extraHeaders: Record<string, string> = {},
  ) {
    super(publicMessage);
  }
}
