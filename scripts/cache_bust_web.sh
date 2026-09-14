#!/usr/bin/env bash
# Content-address the built web bundle so a redeploy cannot leave a browser on
# the previous release.
#
# Why this is needed at all:
#
# `flutter build web` emits fixed filenames - index.html, flutter_bootstrap.js,
# main.dart.js - with no hash in the name. Flutter does version the service worker
# URL it registers (`flutter_service_worker.js?v=<version>`), and the modern
# generated worker unregisters itself and reloads clients, which clears any stale
# worker a previous deploy left behind. But the two links that actually decide
# which code runs are unversioned:
#
#   index.html            -> flutter_bootstrap.js
#   flutter_bootstrap.js -> main.dart.js
#
# GitHub Pages answers those with `Cache-Control: max-age=600`, so after a push
# a visitor can keep getting the old bootstrap, and through it the old app, for
# as long as the cache holds. Appending a content hash as a query string makes
# each deploy a different URL, which is a guaranteed cache miss while still
# letting the CDN cache each individual version forever.
#
# The hash is of file *contents*, so an unchanged file keeps the same URL across
# deploys and stays warm; only what actually changed is refetched.
#
# Usage: scripts/cache_bust_web.sh [build/web]
#
set -euo pipefail

OUT="${1:-build/web}"
BOOTSTRAP="$OUT/flutter_bootstrap.js"
INDEX="$OUT/index.html"

die() {
  echo "cache_bust_web: $*" >&2
  exit 1
}

[ -d "$OUT" ] || die "no build output at $OUT (run 'flutter build web' first)"
[ -f "$BOOTSTRAP" ] || die "$BOOTSTRAP is missing; is this a web build?"
[ -f "$INDEX" ] || die "$INDEX is missing; is this a web build?"

hash_of() {
  # Short content hash. sha256sum is coreutils; fall back to shasum for macOS.
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -c1-12
  else
    shasum -a 256 "$1" | cut -c1-12
  fi
}

# --- index.html -> flutter_bootstrap.js?v=<hash> -------------------------------
# The optional (\?v=...) group means re-running this script rewrites the existing
# tag instead of failing to match, so the script is safe to apply twice.
BOOTSTRAP_HASH="$(hash_of "$BOOTSTRAP")"
perl -0pi -e "s|flutter_bootstrap\.js(\?v=[0-9a-f]+)?(\" async)|flutter_bootstrap.js?v=${BOOTSTRAP_HASH}\${2}|" "$INDEX"
grep -q "flutter_bootstrap.js?v=${BOOTSTRAP_HASH}" "$INDEX" \
  || die "failed to tag the bootstrap reference in $INDEX"

# --- flutter_bootstrap.js -> main.dart.js?v=<hash> ----------------------------
# Both occurrences of the literal in the generated bootstrap are URL
# constructions (the `entrypointUrl` default and the `mainJsPath ??` fallback),
# so tagging them is safe for both the JS and the wasm-on-demand paths.
if [ -f "$OUT/main.dart.js" ]; then
  MAIN_HASH="$(hash_of "$OUT/main.dart.js")"
  perl -0pi -e "s|\"main\\.dart\\.js(\?v=[0-9a-f]+)?\"|\"main.dart.js?v=${MAIN_HASH}\"|g" "$BOOTSTRAP"
  grep -q "main.dart.js?v=${MAIN_HASH}" "$BOOTSTRAP" \
    || die "failed to tag the entry point in $BOOTSTRAP"
  echo "cache_bust_web: main.dart.js?v=${MAIN_HASH}"
fi

echo "cache_bust_web: flutter_bootstrap.js?v=${BOOTSTRAP_HASH}"
echo "cache_bust_web: done"
