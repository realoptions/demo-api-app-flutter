# Mocks

Dart mocks used by the test suite, plus the local API mock server.

## Dart mocks

- `api_repository_mock.dart` — `MockApiRepository`, a test double for the
  `AuthRepository` interface used by the widget, page and bloc tests. It signs in
  through `google_sign_in_mocks` and returns canned credentials, so tests need no
  real Firebase or Google/OAuth round-trip. Import it with a relative path, e.g.
  from `test/pages/foo_test.dart`:

  ```dart
  import '../mocks/api_repository_mock.dart';
  ```

## Local API mock server

`scripts/fetch_yaml.sh` downloads the pricing API spec and the `apisprout`
server into this directory; `scripts/run_dev_server.sh` serves it at
`http://127.0.0.1:8000/mock`. Run them from the repository root:

```sh
bash scripts/fetch_yaml.sh
bash scripts/run_dev_server.sh
```

The downloaded artifacts (`openapi.yaml`, `apisprout`, `*.xz`) are gitignored —
only this README and the Dart mocks are tracked.
