#!/usr/bin/env bash
# Renders build-time config from the committed *.template files into the paths the
# build actually reads.
#
# The templates are the only tracked copy of these files, and by construction they
# never contain a live credential - the credential lives in the environment and is
# substituted in here. That means:
#
#   * no CI step has to `sed -i` a secret into a tracked file (which used to make
#     the committed file differ from the built one with no reviewable diff), and
#   * no secret ever appears inside a workflow `run:` script body, only in the
#     `env:` mapping that feeds this script.
#
# The generated targets are listed in .gitignore, so a rendered file cannot be
# committed by accident.
#
# Usage: scripts/generate_build_config.sh <android|web|keystore>
#
# Environment variables read (never echoed):
#   ANDROID_API_KEY              -> android/app/google-services.json
#   WEB_API_KEY                  -> config/firebase_config.json
#   ANDROID_KEYSTORE_PATH        -> android/key.properties   (release only)
#   ANDROID_KEY_STORE_PASSWORD   -> android/key.properties   (release only)
#   ANDROID_KEY_ALIAS            -> android/key.properties   (release only)
#   ANDROID_KEY_PASSWORD         -> android/key.properties   (release only)
#
# Local development: the app needs the two config files too. Render them with a
# throwaway value when you do not have the real credential, e.g.
#   WEB_API_KEY=local-dev scripts/generate_build_config.sh web
set -eu

# Always operate on the repo root so the script works from any directory.
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die() {
  echo "error: $*" >&2
  exit 1
}

# render TEMPLATE TARGET NAME VALUE [NAME VALUE]...
#
# Replaces every literal ${NAME} in TEMPLATE with VALUE and writes the result to
# TARGET with owner-only permissions. Substitution happens inside this shell with
# parameter expansion, so no secret value ever reaches an external command's
# argv (where `ps` could see it).
render() {
  local template="$1" target="$2"
  shift 2

  [ -f "$template" ] || die "template not found: $template"

  local content name value
  content="$(cat "$template")"

  while [ "$#" -gt 0 ]; do
    name="$1"
    value="$2"
    shift 2

    if [ -z "$value" ]; then
      die "$name is unset or empty; cannot render $target (export $name first)"
    fi

    content="${content//\$\{$name\}/$value}"

    # Guard against a typo in the template: a placeholder we meant to fill in
    # must not survive into the generated file.
    if [[ "$content" == *"\${$name}"* ]]; then
      die "placeholder \${$name} survived substitution in $template"
    fi
  done

  mkdir -p "$(dirname "$target")"
  (
    umask 077
    printf '%s\n' "$content" >"$target"
  )
  echo "generated $target"
}

usage() {
  echo "usage: ${BASH_SOURCE[0]} <android|web|keystore>" >&2
  exit 2
}

[ "$#" -eq 1 ] || usage

case "$1" in
  android)
    render android/app/google-services.json.template \
      android/app/google-services.json \
      ANDROID_API_KEY "${ANDROID_API_KEY:-}"
    ;;
  web)
    # index.html no longer carries the key: it is a plain template now (no
    # placeholders), rendered only because the build reads web/index.html and
    # that path is gitignored. The Firebase key goes into a dart-define-from-file
    # JSON instead, so it never appears in the shipped HTML nor in any argv.
    render web/index.html.template web/index.html
    render config/firebase_config.json.template \
      config/firebase_config.json \
      WEB_API_KEY "${WEB_API_KEY:-}"
    ;;
  keystore)
    render android/key.properties.template android/key.properties \
      ANDROID_KEYSTORE_PATH "${ANDROID_KEYSTORE_PATH:-}" \
      ANDROID_KEY_STORE_PASSWORD "${ANDROID_KEY_STORE_PASSWORD:-}" \
      ANDROID_KEY_ALIAS "${ANDROID_KEY_ALIAS:-}" \
      ANDROID_KEY_PASSWORD "${ANDROID_KEY_PASSWORD:-}"
    ;;
  *)
    usage
    ;;
esac
