#!/usr/bin/env bash
#
# Verify that a workflow_dispatch run is executing the exact protected release
# tag selected by its operator. This is source integrity validation only: it
# accepts no Supabase credentials and makes no network request.

set -euo pipefail

fail() {
  printf '%s\n' 'Protected release-tag verification failed.' >&2
  exit 1
}

[[ "${SOURCE_REF_TYPE-}" == 'tag' ]] || fail
[[ "${SOURCE_REF_PROTECTED-}" == 'true' ]] || fail
[[ -n "${SOURCE_REF_NAME-}" && -n "${GITHUB_SHA-}" ]] || fail
[[ "${SOURCE_REF_NAME}" =~ ^v[0-9][A-Za-z0-9._-]{0,124}$ ]] || fail
git check-ref-format --allow-onelevel "refs/tags/${SOURCE_REF_NAME}" >/dev/null || fail

tag_commit="$(git rev-list -n 1 "refs/tags/${SOURCE_REF_NAME}")"
[[ "$tag_commit" == "$GITHUB_SHA" ]] || fail

printf '%s\n' 'Protected release-tag verification passed.'
