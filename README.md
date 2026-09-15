| [Linux][lin-link] | [Codecov][cov-link] |
| :---------------: | :-----------------: |
| ![lin-badge]      | ![cov-badge]        |

[lin-badge]: https://github.com/realoptions/demo-api-app-flutter/workflows/test/badge.svg
[lin-link]:  https://github.com/realoptions/demo-api-app-flutter/actions
[cov-badge]: https://codecov.io/gh/realoptions/demo-api-app-flutter/branch/master/graph/badge.svg
[cov-link]:  https://codecov.io/gh/realoptions/demo-api-app-flutter

# RealOptions mobile app

This is the mobile app for consuming [Finside's](https://finside.org) APIs.  


# How to install on phone

# Releasing

Only the web app ships, and it ships from a hand-cut tag. Bump `version:` in
`pubspec.yaml`, commit that, then:

```sh
git tag v1.6.12 && git push origin v1.6.12
```

The `release` workflow checks the tag against `pubspec.yaml`, runs the tests,
builds `flutter build web --build-name=<version>` and publishes it to GitHub
Pages (`https://demo.finside.org`). Nothing deploys from a branch push, and
Google Play is not deployed at all. Full details:
[docs/release-flow.md](docs/release-flow.md).

# CI

`test.yaml` gates pull requests and pushes to `master` (format, analyze, tests,
coverage). The old blog-era setup notes are below.

See https://appditto.com/blog/automate-your-flutter-workflow

```sh
cd $HOME
FLUTTER_VERSION=3.47.4
git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VERSION} --depth 1 
```
