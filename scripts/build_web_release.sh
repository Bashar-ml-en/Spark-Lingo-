#!/usr/bin/env bash
# Release web build with the correct hosted config. Reads the publishable
# key from Temp at runtime (never embedded in this script or the repo).
set -euo pipefail
cd "$(dirname "$0")/.."

KEY_FILE="${LOCALAPPDATA:-$HOME/AppData/Local}/Temp/sb_pubkey.txt"
REF=dioisitgohusggmwowft

read -r PUBKEY < "$KEY_FILE"

/c/flutter/bin/flutter build web --release \
  --dart-define=SPARK_LINGO_ENV=production \
  --dart-define=SUPABASE_DEPLOYMENT=hosted \
  --dart-define=SUPABASE_URL=https://$REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$PUBKEY" \
  --dart-define=SUPABASE_PROJECT_REF=$REF \
  --dart-define=SPARK_LINGO_PRODUCTION_PROJECT_REF=$REF

# Verify the key actually landed in the artifact before deploying.
if grep -qF "$PUBKEY" build/web/main.dart.js; then
  echo "BUILD-VERIFY: publishable key present"
else
  echo "BUILD-VERIFY: FAIL — key missing from main.dart.js" >&2
  exit 1
fi
grep -qF "https://$REF.supabase.co" build/web/main.dart.js && echo "BUILD-VERIFY: URL present"
grep -q "ENABLE_TEST_CONSENT" build/web/main.dart.js && { echo "BUILD-VERIFY: FAIL — test consent flag present" >&2; exit 1; } || echo "BUILD-VERIFY: no ENABLE_TEST_CONSENT"
sha256sum build/web/main.dart.js
