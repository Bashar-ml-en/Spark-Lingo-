#!/bin/bash
set -e

echo "==> [Spark Lingo Vercel Shim] Intercepted flutter command: $*"

# If invoked with 'build web', delegate directly to our full build_vercel.sh pipeline
if [ "$1" = "build" ] && [ "$2" = "web" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  bash "$SCRIPT_DIR/build_vercel.sh"
  exit 0
fi

# Otherwise ensure Flutter is downloaded and execute arguments
if [ ! -d "/tmp/flutter" ]; then
  echo "==> [Spark Lingo Vercel Shim] Downloading Flutter SDK (stable)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter
fi

export PATH="/tmp/flutter/bin:$PATH"
exec /tmp/flutter/bin/flutter "$@"
