/**
 * Unit tests for provider resolution (providers.ts).
 *
 * Run locally:
 *   deno test --allow-env supabase/functions/sparky-ai/providers_test.ts
 *
 * These tests exercise the fail-closed configuration contract: every missing
 * or malformed provider setting must throw 503 configuration_error, and the
 * historical OpenAI behaviour must be preserved exactly when AI_PROVIDER is
 * unset.
 */

import { assertEquals, assertRejects } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { HttpError } from "./errors.ts";
import { resolveProviderForAction } from "./providers.ts";

const ALL_KEYS = [
  "AI_PROVIDER",
  "AI_PROVIDER_BASE_URL",
  "AI_PROVIDER_API_KEY",
  "AI_PROVIDER_CHAT_MODEL",
  "AI_PROVIDER_TRANSCRIPTION_MODEL",
  "AI_STT_PROVIDER",
  "AI_STT_BASE_URL",
  "AI_STT_API_KEY",
  "AI_STT_MODEL",
  "OPENAI_API_KEY",
  "OPENAI_CHAT_MODEL",
  "OPENAI_TRANSCRIPTION_MODEL",
  "DASHSCOPE_API_KEY",
  "DASHSCOPE_CHAT_MODEL",
  "DASHSCOPE_TRANSCRIPTION_MODEL",
];

function clearEnv(): void {
  for (const key of ALL_KEYS) Deno.env.delete(key);
}

async function expectConfigurationError(fn: () => unknown): Promise<void> {
  await assertRejects(
    async () => {
      fn();
    },
    HttpError,
    "AI service is temporarily unavailable.",
  );
}

Deno.test("unset AI_PROVIDER keeps historical OpenAI behaviour for chat", () => {
  clearEnv();
  Deno.env.set("OPENAI_API_KEY", "test-openai-key");
  Deno.env.set("OPENAI_CHAT_MODEL", "test-chat-model");
  const config = resolveProviderForAction("chat");
  assertEquals(config.kind, "openai");
  assertEquals(config.baseUrl, "https://api.openai.com/v1");
  assertEquals(config.apiKey, "test-openai-key");
  assertEquals(config.model, "test-chat-model");
  clearEnv();
});

Deno.test("unset AI_PROVIDER keeps historical OpenAI behaviour for transcribe", () => {
  clearEnv();
  Deno.env.set("OPENAI_API_KEY", "test-openai-key");
  Deno.env.set("OPENAI_TRANSCRIPTION_MODEL", "test-stt-model");
  const config = resolveProviderForAction("transcribe");
  assertEquals(config.kind, "openai");
  assertEquals(config.baseUrl, "https://api.openai.com/v1");
  assertEquals(config.model, "test-stt-model");
  clearEnv();
});

Deno.test("missing OpenAI key fails closed", async () => {
  clearEnv();
  Deno.env.set("OPENAI_CHAT_MODEL", "test-chat-model");
  await expectConfigurationError(() => resolveProviderForAction("chat"));
  clearEnv();
});

Deno.test("missing OpenAI model fails closed", async () => {
  clearEnv();
  Deno.env.set("OPENAI_API_KEY", "test-openai-key");
  await expectConfigurationError(() => resolveProviderForAction("chat"));
  clearEnv();
});

Deno.test("dashscope provider resolves international endpoint and own key/model", () => {
  clearEnv();
  Deno.env.set("AI_PROVIDER", "dashscope");
  Deno.env.set("DASHSCOPE_API_KEY", "test-dashscope-key");
  Deno.env.set("DASHSCOPE_CHAT_MODEL", "qwen-test");
  const config = resolveProviderForAction("chat");
  assertEquals(config.kind, "dashscope");
  assertEquals(config.baseUrl, "https://dashscope-intl.aliyuncs.com/compatible-mode/v1");
  assertEquals(config.apiKey, "test-dashscope-key");
  assertEquals(config.model, "qwen-test");
  clearEnv();
});

Deno.test("dashscope base URL override is honoured", () => {
  clearEnv();
  Deno.env.set("AI_PROVIDER", "dashscope");
  Deno.env.set("AI_PROVIDER_BASE_URL", "https://dashscope.aliyuncs.com/compatible-mode/v1");
  Deno.env.set("DASHSCOPE_API_KEY", "test-dashscope-key");
  Deno.env.set("DASHSCOPE_CHAT_MODEL", "qwen-test");
  const config = resolveProviderForAction("chat");
  assertEquals(config.baseUrl, "https://dashscope.aliyuncs.com/compatible-mode/v1");
  clearEnv();
});

Deno.test("openai_compatible requires explicit base URL", async () => {
  clearEnv();
  Deno.env.set("AI_PROVIDER", "openai_compatible");
  Deno.env.set("AI_PROVIDER_API_KEY", "test-key");
  Deno.env.set("AI_PROVIDER_CHAT_MODEL", "local-model");
  await expectConfigurationError(() => resolveProviderForAction("chat"));
  clearEnv();
});

Deno.test("openai_compatible resolves self-hosted vLLM-style endpoint", () => {
  clearEnv();
  Deno.env.set("AI_PROVIDER", "openai_compatible");
  Deno.env.set("AI_PROVIDER_BASE_URL", "https://vllm.internal.example/v1");
  Deno.env.set("AI_PROVIDER_API_KEY", "test-key");
  Deno.env.set("AI_PROVIDER_CHAT_MODEL", "local-model");
  const config = resolveProviderForAction("chat");
  assertEquals(config.kind, "openai_compatible");
  assertEquals(config.baseUrl, "https://vllm.internal.example/v1");
  assertEquals(config.model, "local-model");
  clearEnv();
});

Deno.test("cleartext http to a remote host fails closed", async () => {
  clearEnv();
  Deno.env.set("AI_PROVIDER", "openai_compatible");
  Deno.env.set("AI_PROVIDER_BASE_URL", "http://remote.example/v1");
  Deno.env.set("AI_PROVIDER_API_KEY", "test-key");
  Deno.env.set("AI_PROVIDER_CHAT_MODEL", "local-model");
  await expectConfigurationError(() => resolveProviderForAction("chat"));
  clearEnv();
});

Deno.test("cleartext http on loopback is allowed for local self-hosted servers", () => {
  clearEnv();
  Deno.env.set("AI_PROVIDER", "openai_compatible");
  Deno.env.set("AI_PROVIDER_BASE_URL", "http://127.0.0.1:8000/v1");
  Deno.env.set("AI_PROVIDER_API_KEY", "test-key");
  Deno.env.set("AI_PROVIDER_CHAT_MODEL", "local-model");
  const config = resolveProviderForAction("chat");
  assertEquals(config.baseUrl, "http://127.0.0.1:8000/v1");
  clearEnv();
});

Deno.test("unknown provider name fails closed", async () => {
  clearEnv();
  Deno.env.set("AI_PROVIDER", "not-a-provider");
  await expectConfigurationError(() => resolveProviderForAction("chat"));
  clearEnv();
});

Deno.test("trailing slashes are stripped from configured base URLs", () => {
  clearEnv();
  Deno.env.set("AI_PROVIDER", "openai_compatible");
  Deno.env.set("AI_PROVIDER_BASE_URL", "https://vllm.internal.example/v1///");
  Deno.env.set("AI_PROVIDER_API_KEY", "test-key");
  Deno.env.set("AI_PROVIDER_CHAT_MODEL", "local-model");
  const config = resolveProviderForAction("chat");
  assertEquals(config.baseUrl, "https://vllm.internal.example/v1");
  clearEnv();
});

Deno.test("AI_STT_PROVIDER override routes only transcribe", () => {
  clearEnv();
  Deno.env.set("OPENAI_API_KEY", "test-openai-key");
  Deno.env.set("OPENAI_CHAT_MODEL", "test-chat-model");
  Deno.env.set("AI_STT_PROVIDER", "openai_compatible");
  Deno.env.set("AI_STT_BASE_URL", "https://speaches.internal.example/v1");
  Deno.env.set("AI_STT_MODEL", "Systran/faster-whisper-large-v3");

  const stt = resolveProviderForAction("transcribe");
  assertEquals(stt.kind, "openai_compatible");
  assertEquals(stt.baseUrl, "https://speaches.internal.example/v1");
  assertEquals(stt.model, "Systran/faster-whisper-large-v3");
  assertEquals(stt.apiKey, ""); // optional for self-hosted STT

  // chat must remain on the primary provider
  const chat = resolveProviderForAction("chat");
  assertEquals(chat.kind, "openai");
  assertEquals(chat.baseUrl, "https://api.openai.com/v1");
  clearEnv();
});

Deno.test("AI_STT_PROVIDER without base URL fails closed", async () => {
  clearEnv();
  Deno.env.set("OPENAI_API_KEY", "test-openai-key");
  Deno.env.set("AI_STT_PROVIDER", "openai_compatible");
  Deno.env.set("AI_STT_MODEL", "Systran/faster-whisper-large-v3");
  await expectConfigurationError(() => resolveProviderForAction("transcribe"));
  clearEnv();
});

Deno.test("unknown AI_STT_PROVIDER value fails closed", async () => {
  clearEnv();
  Deno.env.set("OPENAI_API_KEY", "test-openai-key");
  Deno.env.set("AI_STT_PROVIDER", "something-else");
  await expectConfigurationError(() => resolveProviderForAction("transcribe"));
  clearEnv();
});
