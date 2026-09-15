#!/usr/bin/env bash
# Serves the mocked pricing API on http://127.0.0.1:8000/mock
# Run scripts/fetch_yaml.sh first to download the spec and the server binary.
set -eu

MOCK_DIR="./test/mocks"
"$MOCK_DIR/apisprout" --add-server http://127.0.0.1:8000/mock "$MOCK_DIR/openapi.yaml"
