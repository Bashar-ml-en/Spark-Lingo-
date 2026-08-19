import {
  type EnvironmentReader,
  validateStagingTarget,
} from "./staging_target_guard.ts";

const productionProjectRef = "stlzixqtvtfyrcbjappr";
const stagingProjectRef = "abcdefghijklmnopqrst";

function baseEnvironment(): Record<string, string> {
  return {
    SPARK_LINGO_TEST_ENV: "staging",
    STAGING_ENVIRONMENT_GUARD: "configured-staging-only",
    SOURCE_REF_TYPE: "tag",
    SOURCE_REF_PROTECTED: "true",
    SOURCE_REF_NAME: "rc-staging-guard-test",
    STAGING_CHANGE_REFERENCE: "CHG-123",
    SUPABASE_TEST_PROJECT_REF: stagingProjectRef,
    SUPABASE_TEST_URL: `https://${stagingProjectRef}.supabase.co`,
    SUPABASE_PRODUCTION_PROJECT_REF: productionProjectRef,
    SUPABASE_PRODUCTION_URL: `https://${productionProjectRef}.supabase.co`,
    SMOKE_TARGET_CONFIRMATION: `staging:${stagingProjectRef}`,
  };
}

function reader(values: Record<string, string>): EnvironmentReader {
  return (name) => values[name];
}

function expectFailure(callback: () => unknown, message: string): void {
  try {
    callback();
  } catch {
    return;
  }
  throw new Error(message);
}

Deno.test("accepts a distinct canonical staging target", () => {
  const target = validateStagingTarget(reader(baseEnvironment()));
  if (
    target.projectRef !== stagingProjectRef ||
    target.url.hostname !== `${stagingProjectRef}.supabase.co`
  ) {
    throw new Error("The valid staging target was not returned.");
  }
});

Deno.test("rejects an unprotected source tag", () => {
  const values = baseEnvironment();
  values.SOURCE_REF_PROTECTED = "false";
  expectFailure(
    () => validateStagingTarget(reader(values)),
    "An unprotected source tag was accepted.",
  );
});

Deno.test("rejects the reviewed production project as a staging target", () => {
  const values = baseEnvironment();
  values.SUPABASE_TEST_PROJECT_REF = productionProjectRef;
  values.SUPABASE_TEST_URL = `https://${productionProjectRef}.supabase.co`;
  values.SMOKE_TARGET_CONFIRMATION = `staging:${productionProjectRef}`;
  expectFailure(
    () => validateStagingTarget(reader(values)),
    "The known production project was accepted as staging.",
  );
});

Deno.test("rejects a confirmation that does not bind to the staging target", () => {
  const values = baseEnvironment();
  values.SMOKE_TARGET_CONFIRMATION = "staging:wrong-project-reference";
  expectFailure(
    () => validateStagingTarget(reader(values)),
    "A mismatched staging confirmation was accepted.",
  );
});

Deno.test("rejects a non-canonical staging URL", () => {
  const values = baseEnvironment();
  values.SUPABASE_TEST_URL = `https://${stagingProjectRef}.supabase.co/extra-path`;
  expectFailure(
    () => validateStagingTarget(reader(values)),
    "A non-canonical staging URL was accepted.",
  );
});
