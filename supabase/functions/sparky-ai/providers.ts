/**
 * Provider resolution for the sparky-ai Edge Function.
 *
 * Spark Lingo talks to AI providers exclusively through OpenAI-compatible
 * wire APIs (POST /chat/completions, POST /audio/transcriptions). This
 * module decides WHICH endpoint, key, and pinned model each action uses,
 * based only on Edge Function environment variables. The mobile/web client
 * can never influence the choice.
 *
 * Security invariants (must never weaken):
 * - Fail closed: any missing or malformed configuration value yields
 *   503 configuration_error before a provider is contacted.
 * - Secrets live only in Edge Function environment; nothing here is ever
 *   returned to callers, logged, or embedded in client builds.
 * - Cleartext HTTP endpoints are rejected unless the host is a loopback
 *   address, so a misconfigured base URL cannot exfiltrate a bearer key
 *   to a remote host in the clear.
 * - Model names are pinned by configuration per the approved-model rule in
 *   docs/release/EXTERNAL_CONFIGURATION_MATRIX.md. This module deliberately
 *   supplies no default model names for non-OpenAI providers.
 *
 * Supported provider kinds (`AI_PROVIDER`):
 * - unset or "openai": OpenAI at https://api.openai.com/v1 using
 *   OPENAI_API_KEY / OPENAI_CHAT_MODEL / OPENAI_TRANSCRIPTION_MODEL
 *   (byte-for-byte the historical behaviour).
 * - "dashscope": Alibaba Cloud DashScope OpenAI-compatible mode (used by
 *   Qwen models) at https://dashscope-intl.aliyuncs.com/compatible-mode/v1
 *   using DASHSCOPE_API_KEY / DASHSCOPE_CHAT_MODEL /
 *   DASHSCOPE_TRANSCRIPTION_MODEL. The base URL may be overridden with
 *   AI_PROVIDER_BASE_URL (for example the China-region endpoint).
 * - "openai_compatible": any OpenAI-compatible chat+STT server (self-hosted
 *   vLLM, Ollama with an OpenAI surface, Speaches/faster-whisper-server)
 *   using AI_PROVIDER_BASE_URL / AI_PROVIDER_API_KEY /
 *   AI_PROVIDER_CHAT_MODEL / AI_PROVIDER_TRANSCRIPTION_MODEL.
 *
 * Optional STT override: `AI_STT_PROVIDER=openai_compatible` routes only
 * the transcribe action to a dedicated server (for example a self-hosted
 * faster-whisper/Speaches instance) configured with AI_STT_BASE_URL,
 * AI_STT_MODEL, and optionally AI_STT_API_KEY. Chat is unaffected.
 */

import { HttpError } from "./errors.ts";

export type ProviderAction = "chat" | "transcribe";

export type ProviderConfig = {
  /** Stable kind name for diagnostics that never carries secret material. */
  kind: "openai" | "dashscope" | "openai_compatible";
  /** OpenAI-compatible API root without a trailing slash. */
  baseUrl: string;
  /** Bearer credential for the provider. Never logged or returned. */
  apiKey: string;
  /** Pinned model name for the requested action. */
  model: string;
};

const OPENAI_BASE_URL = "https://api.openai.com/v1";
const DASHSCOPE_INTL_BASE_URL =
  "https://dashscope-intl.aliyuncs.com/compatible-mode/v1";

/**
 * Reads a required Edge Function environment value. A missing or blank
 * value is a configuration fault: fail closed with a public-safe message.
 */
export function configuredValue(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new HttpError(
      503,
      "configuration_error",
      "AI service is temporarily unavailable.",
    );
  }
  return value;
}

function optionalValue(name: string): string {
  return Deno.env.get(name)?.trim() ?? "";
}

function configurationError(): HttpError {
  return new HttpError(
    503,
    "configuration_error",
    "AI service is temporarily unavailable.",
  );
}

/**
 * Validates a provider base URL. Only http/https schemes are accepted, and
 * cleartext http is restricted to loopback hosts so a misconfiguration can
 * never send a bearer key unencrypted to a remote server.
 */
function assertSafeBaseUrl(rawUrl: string): string {
  const baseUrl = rawUrl.trim().replace(/\/+$/, "");
  let parsed: URL;
  try {
    parsed = new URL(baseUrl);
  } catch {
    throw configurationError();
  }
  if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
    throw configurationError();
  }
  if (parsed.protocol === "http:") {
    const host = parsed.hostname;
    const loopback = host === "localhost" ||
      host === "127.0.0.1" ||
      host === "[::1]" ||
      host === "::1";
    if (!loopback) {
      throw configurationError();
    }
  }
  return baseUrl;
}

function resolveKind(): "openai" | "dashscope" | "openai_compatible" {
  const raw = optionalValue("AI_PROVIDER").toLowerCase();
  if (raw === "" || raw === "openai") return "openai";
  if (raw === "dashscope") return "dashscope";
  if (raw === "openai_compatible") return "openai_compatible";
  // An unknown provider name fails closed rather than falling back to a
  // default endpoint that may not be approved or budgeted.
  throw configurationError();
}

function envName(kind: ProviderConfig["kind"], field: "key" | "chat" | "stt"): string {
  if (kind === "openai") {
    if (field === "key") return "OPENAI_API_KEY";
    if (field === "chat") return "OPENAI_CHAT_MODEL";
    return "OPENAI_TRANSCRIPTION_MODEL";
  }
  if (kind === "dashscope") {
    if (field === "key") return "DASHSCOPE_API_KEY";
    if (field === "chat") return "DASHSCOPE_CHAT_MODEL";
    return "DASHSCOPE_TRANSCRIPTION_MODEL";
  }
  if (field === "key") return "AI_PROVIDER_API_KEY";
  if (field === "chat") return "AI_PROVIDER_CHAT_MODEL";
  return "AI_PROVIDER_TRANSCRIPTION_MODEL";
}

function resolveBaseUrl(kind: ProviderConfig["kind"]): string {
  if (kind === "openai") return OPENAI_BASE_URL;
  const configured = optionalValue("AI_PROVIDER_BASE_URL");
  if (configured) return assertSafeBaseUrl(configured);
  if (kind === "dashscope") return DASHSCOPE_INTL_BASE_URL;
  // openai_compatible has no default endpoint: the operator must name the
  // approved server explicitly.
  throw configurationError();
}

/**
 * Resolves the provider serving the chat completions endpoint and, unless
 * an STT override is configured, the transcription endpoint too.
 */
export function resolveProviderForAction(
  action: ProviderAction,
): ProviderConfig {
  if (action === "transcribe") {
    const sttProvider = optionalValue("AI_STT_PROVIDER").toLowerCase();
    if (sttProvider === "openai_compatible") {
      const baseUrl = assertSafeBaseUrl(configuredValue("AI_STT_BASE_URL"));
      const model = configuredValue("AI_STT_MODEL");
      // Self-hosted transcription servers often run without bearer auth;
      // the key is therefore optional here and only attached when present.
      const apiKey = optionalValue("AI_STT_API_KEY");
      return { kind: "openai_compatible", baseUrl, apiKey, model };
    }
    if (sttProvider !== "") {
      throw configurationError();
    }
  }

  const kind = resolveKind();
  const baseUrl = resolveBaseUrl(kind);
  const apiKey = configuredValue(envName(kind, "key"));
  const model = configuredValue(envName(kind, action === "transcribe" ? "stt" : "chat"));
  return { kind, baseUrl, apiKey, model };
}

/**
 * Builds request headers for a provider call. A blank key (allowed only for
 * the optional self-hosted STT override) omits the Authorization header
 * instead of sending a malformed bearer token.
 */
export function providerHeaders(config: ProviderConfig): Record<string, string> {
  const headers: Record<string, string> = {};
  if (config.apiKey) {
    headers["Authorization"] = `Bearer ${config.apiKey}`;
  }
  return headers;
}
