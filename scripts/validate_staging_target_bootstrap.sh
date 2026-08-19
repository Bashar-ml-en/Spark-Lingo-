#!/usr/bin/env bash
#
# Bootstrap staging-target guard for CI runners.
#
# This script intentionally has no network capability and accepts no secret
# values. It runs before tooling is downloaded and before a Supabase credential
# is made available to a workflow step. The authoritative Deno guard in
# validate_staging_target.ts runs again immediately before every Supabase CLI
# operation. Keep the two guards aligned through a reviewed change.

set -euo pipefail

fail() {
  # Do not expose configuration values in logs. The caller only needs the
  # pass/fail result; operators can inspect protected Environment settings.
  printf '%s\n' 'Staging target bootstrap preflight failed.' >&2
  exit 1
}

required() {
  local name="$1"
  local value="${!name-}"
  [[ -n "$value" ]] || fail
  printf '%s' "$value"
}

require_exact() {
  local name="$1"
  local expected="$2"
  [[ "$(required "$name")" == "$expected" ]] || fail
}

require_exact 'SPARK_LINGO_TEST_ENV' 'staging'
require_exact 'STAGING_ENVIRONMENT_GUARD' 'configured-staging-only'
require_exact 'SOURCE_REF_TYPE' 'tag'
require_exact 'SOURCE_REF_PROTECTED' 'true'

source_ref_name="$(required 'SOURCE_REF_NAME')"
[[ "${#source_ref_name}" -le 128 ]] || fail
[[ "$source_ref_name" != *$'\r'* && "$source_ref_name" != *$'\n'* ]] || fail

change_reference="$(required 'STAGING_CHANGE_REFERENCE')"
[[ "$change_reference" =~ ^[A-Za-z0-9][A-Za-z0-9._:/#-]{2,127}$ ]] || fail

project_ref="$(required 'SUPABASE_TEST_PROJECT_REF')"
[[ "$project_ref" =~ ^[a-z0-9]{20}$ ]] || fail
require_exact 'SUPABASE_TEST_URL' "https://${project_ref}.supabase.co"

production_project_ref="$(required 'SUPABASE_PRODUCTION_PROJECT_REF')"
[[ "$production_project_ref" =~ ^[a-z0-9]{20}$ ]] || fail
require_exact 'SUPABASE_PRODUCTION_URL' "https://${production_project_ref}.supabase.co"

# This deny-list is deliberately independent of GitHub Environment variables.
# It must be changed only by a reviewed source change when production changes.
case "$production_project_ref" in
  stlzixqtvtfyrcbjappr) ;;
  *) fail ;;
esac

[[ "$project_ref" != "$production_project_ref" ]] || fail
[[ "$project_ref" != 'stlzixqtvtfyrcbjappr' ]] || fail
require_exact 'SMOKE_TARGET_CONFIRMATION' "staging:${project_ref}"

printf '%s\n' 'Staging target bootstrap preflight passed.'
