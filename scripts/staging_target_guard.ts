/**
 * Staging-target guard shared by the non-network preflight and the live smoke
 * test. It deliberately accepts no credentials and makes no network request.
 *
 * A reviewed source change is required whenever the production project
 * identity changes. A Supabase project reference is public metadata, not a
 * credential; do not replace this guard with a secret or a service-role key.
 */

export type EnvironmentReader = (name: string) => string | undefined;

export interface StagingTarget {
  readonly projectRef: string;
  readonly url: URL;
}

const PROJECT_REF_PATTERN = /^[a-z0-9]{20}$/;
const CHANGE_REFERENCE_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:/#-]{2,127}$/;

// This is a deny-list, not a source of configuration. Keep it synchronized
// with the separately protected GitHub Environment variable through a
// reviewed change. The current known production ref must never be accepted as
// a staging target even if a workflow variable is misconfigured.
const REVIEWED_PRODUCTION_PROJECT_REFS = new Set<string>([
  "stlzixqtvtfyrcbjappr",
]);

function requiredEnvironment(name: string, readEnvironment: EnvironmentReader): string {
  const value = readEnvironment(name)?.trim();
  if (!value) {
    throw new Error(`Missing required staging-only variable: ${name}`);
  }
  return value;
}

function validProjectRef(value: string): boolean {
  return PROJECT_REF_PATTERN.test(value);
}

function parseCanonicalSupabaseUrl(value: string, projectRef: string, name: string): URL {
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new Error(`${name} is not a valid URL.`);
  }

  if (
    url.protocol !== "https:" ||
    url.hostname !== `${projectRef}.supabase.co` ||
    url.port !== "" ||
    url.username !== "" ||
    url.password !== "" ||
    url.pathname !== "/" ||
    url.search !== "" ||
    url.hash !== ""
  ) {
    throw new Error(`${name} is not the canonical HTTPS URL for its configured project reference.`);
  }
  return url;
}

/**
 * Validates the target without exposing values in error messages or output.
 * All of these variables must originate from the protected GitHub `staging`
 * Environment, except the two manual workflow inputs used as a human check.
 */
export function validateStagingTarget(
  readEnvironment: EnvironmentReader = (name) => Deno.env.get(name),
): StagingTarget {
  if (requiredEnvironment("SPARK_LINGO_TEST_ENV", readEnvironment) !== "staging") {
    throw new Error("Refusing to run outside the staging environment.");
  }
  if (requiredEnvironment("STAGING_ENVIRONMENT_GUARD", readEnvironment) !== "configured-staging-only") {
    throw new Error("The protected staging Environment guard is absent or invalid.");
  }
  if (requiredEnvironment("SOURCE_REF_TYPE", readEnvironment) !== "tag") {
    throw new Error("Staging smoke tests require an immutable source tag.");
  }
  if (requiredEnvironment("SOURCE_REF_PROTECTED", readEnvironment) !== "true") {
    throw new Error("Staging smoke tests require a protected source tag.");
  }

  const sourceRefName = requiredEnvironment("SOURCE_REF_NAME", readEnvironment);
  if (sourceRefName.length > 128 || /[\r\n]/.test(sourceRefName)) {
    throw new Error("The source tag name is invalid.");
  }

  const changeReference = requiredEnvironment("STAGING_CHANGE_REFERENCE", readEnvironment);
  if (!CHANGE_REFERENCE_PATTERN.test(changeReference)) {
    throw new Error("The staging change reference is invalid.");
  }

  const projectRef = requiredEnvironment("SUPABASE_TEST_PROJECT_REF", readEnvironment);
  if (!validProjectRef(projectRef)) {
    throw new Error("SUPABASE_TEST_PROJECT_REF is not a Supabase project reference.");
  }
  const target = parseCanonicalSupabaseUrl(
    requiredEnvironment("SUPABASE_TEST_URL", readEnvironment),
    projectRef,
    "SUPABASE_TEST_URL",
  );

  const productionProjectRef = requiredEnvironment(
    "SUPABASE_PRODUCTION_PROJECT_REF",
    readEnvironment,
  );
  if (!validProjectRef(productionProjectRef)) {
    throw new Error("SUPABASE_PRODUCTION_PROJECT_REF is not a Supabase project reference.");
  }
  parseCanonicalSupabaseUrl(
    requiredEnvironment("SUPABASE_PRODUCTION_URL", readEnvironment),
    productionProjectRef,
    "SUPABASE_PRODUCTION_URL",
  );

  if (!REVIEWED_PRODUCTION_PROJECT_REFS.has(productionProjectRef)) {
    throw new Error("The configured production project is not on the reviewed deny-list.");
  }
  if (
    projectRef === productionProjectRef ||
    REVIEWED_PRODUCTION_PROJECT_REFS.has(projectRef)
  ) {
    throw new Error("Refusing to run against a known production Supabase project.");
  }

  if (
    requiredEnvironment("SMOKE_TARGET_CONFIRMATION", readEnvironment) !== `staging:${projectRef}`
  ) {
    throw new Error("The staging target confirmation does not match the protected staging project.");
  }

  return { projectRef, url: target };
}
