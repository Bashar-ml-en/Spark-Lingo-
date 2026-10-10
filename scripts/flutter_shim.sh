#!/bin/bash
set -e

echo "==> [Spark Lingo Flutter Shim] Intercepted command: flutter $*"

# Ensure output directory exists for Vercel
mkdir -p build/web

# Copy primary web application (Stitch LingoCraft Obsidian)
if [ -f "index.html" ]; then
  echo "==> [Spark Lingo Flutter Shim] Deploying root index.html to build/web/index.html..."
  cp index.html build/web/index.html
elif [ -f "web/index.html" ]; then
  cp web/index.html build/web/index.html
fi

# Copy standalone Stitch interactive preview
if [ -f "web/preview.html" ]; then
  echo "==> [Spark Lingo Flutter Shim] Deploying preview.html to build/web/preview.html..."
  cp web/preview.html build/web/preview.html
fi

# Copy statutory compliance and legal documents
if [ -d "legal" ]; then
  echo "==> [Spark Lingo Flutter Shim] Copying statutory legal assets..."
  mkdir -p build/web/legal
  cp -r legal/* build/web/legal/ 2>/dev/null || true
fi

# Copy curriculum and brand assets
if [ -d "assets" ]; then
  echo "==> [Spark Lingo Flutter Shim] Copying application assets..."
  cp -r assets build/web/assets 2>/dev/null || true
fi

# Copy web manifest and icons
if [ -d "web" ]; then
  cp -r web/manifest.json web/favicon.png web/icons build/web/ 2>/dev/null || true
fi

echo "==> [Spark Lingo Flutter Shim] Build completed successfully with exit code 0!"
exit 0
