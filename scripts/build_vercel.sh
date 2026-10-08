#!/bin/bash
set -e

echo "=== Spark Lingo Vercel Build Pipeline ==="

# 1. Ensure Flutter SDK is available
if ! command -v flutter &> /dev/null; then
  echo "==> Flutter not detected in PATH. Cloning Flutter stable into /tmp/flutter..."
  if [ ! -d "/tmp/flutter" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter
  fi
  export PATH="$PATH:/tmp/flutter/bin"
fi

echo "==> Active Flutter Version:"
flutter --version

# 2. Determine configuration parameters (fall back safely if not defined in Vercel environment)
SPARK_ENV="${SPARK_LINGO_ENV:-development}"
SUB_DEP="${SUPABASE_DEPLOYMENT:-local}"
SUB_URL="${SUPABASE_URL:-http://localhost:54321}"
SUB_KEY="${SUPABASE_ANON_KEY:-sb_publishable_dev_dummy_key_1234567890}"
SUB_REF="${SUPABASE_PROJECT_REF:-dev00000000000000000}"
SUB_PROD_REF="${SUPABASE_PRODUCTION_PROJECT_REF:-prod0000000000000000}"

echo "==> Compiling Flutter Web with Stitch LingoCraft Obsidian design..."
flutter build web --release \
  --dart-define=SPARK_LINGO_ENV="$SPARK_ENV" \
  --dart-define=SUPABASE_DEPLOYMENT="$SUB_DEP" \
  --dart-define=SUPABASE_URL="$SUB_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUB_KEY" \
  --dart-define=SUPABASE_PROJECT_REF="$SUB_REF" \
  --dart-define=SUPABASE_PRODUCTION_PROJECT_REF="$SUB_PROD_REF" \
  --dart-define=TERMS_OF_SERVICE_URL="https://spark-lingo.vercel.app/legal/terms.html" \
  --dart-define=PRIVACY_POLICY_URL="https://spark-lingo.vercel.app/legal/privacy.html" \
  --dart-define=AI_AND_VOICE_NOTICE_URL="https://spark-lingo.vercel.app/legal/ai-and-voice-notice.html" \
  --dart-define=ANALYTICS_NOTICE_URL="https://spark-lingo.vercel.app/legal/analytics-notice.html" \
  --dart-define=ACCOUNT_DELETION_URL="https://spark-lingo.vercel.app/legal/account-deletion.html" \
  --dart-define=DATA_EXPORT_URL="https://spark-lingo.vercel.app/legal/data-export.html" \
  --dart-define=SUBSCRIPTION_MANAGEMENT_URL="https://spark-lingo.vercel.app/legal/subscription-management.html"

# 3. Copy static compliance and preview assets
echo "==> Embedding static compliance documents..."
mkdir -p build/web/legal
cp -r legal/* build/web/legal/ 2>/dev/null || true

if [ -f "web/preview.html" ]; then
  echo "==> Embedding standalone Stitch interactive preview..."
  cp web/preview.html build/web/preview.html
fi

echo "=== Vercel build complete! Output ready in build/web ==="
