#!/usr/bin/env bash
# Downloads the API spec and the apisprout mock server into test/mocks/.
# Artifacts are gitignored (*.xz, apisprout, openapi.yaml) - only the Dart mock
# and the README are tracked here.
set -eu

MOCK_DIR="./test/mocks"
mkdir -p "$MOCK_DIR"

wget -O "$MOCK_DIR/openapi.yaml" \
  https://raw.githubusercontent.com/realoptions/option_price_faas/master/docs/openapi_merged.yml

wget -O "$MOCK_DIR/apisprout.tar.xz" \
  https://github.com/danielgtaylor/apisprout/releases/download/v1.3.0/apisprout-v1.3.0-linux.tar.xz

tar xf "$MOCK_DIR/apisprout.tar.xz" -C "$MOCK_DIR"
rm "$MOCK_DIR/apisprout.tar.xz"
