# Release flow

The release pipeline is driven entirely by git tags. A push never deploys
anything directly; it produces a tag, and the tag decides what gets shipped.

```
push to a branch
      |
      v
 tagtest (tag.yml)  ---- runs tests + coverage ----+
      |                                          |
      |  branch == master  ->  release-<version>  |  branch != master  ->  beta-<version>
      |                                          |
      v                                          v
 releaseprod (deployprod.yaml)              releasebeta (deploybeta.yaml)
      |                                          |
      +-------------------+----------------------+
                          |
                          v
              deploy-reusable.yml  (the whole pipeline, once)
```

## 1. Tag creation — `tag.yml` (`tagtest`)

Runs on every push to any branch except tags (`tags-ignore: '*.*'`).

1. Runs the test suite with coverage and uploads it to Codecov.
2. Reads the app version out of `pubspec.yaml` into `FLUTTER_VERSION`
   (the name is historic — it is the *app* version, not the SDK version).
3. Picks a prefix from the branch: `release` for `master`, `beta` otherwise.
4. Builds `CUSTOM_TAG` = `<prefix>-<version>`.
5. If that tag does not already exist locally, pushes it via
   `anothrNick/github-tag-action`.

So merging to `master` yields `release-1.2.3`, and a feature-branch push yields
`beta-1.2.3`.

## 2. Deployment entrypoints

`deploybeta.yaml` and `deployprod.yaml` are deliberately tiny. They match their
tag and pass three values to the shared implementation. They contain no build
logic of their own — **all pipeline changes belong in `deploy-reusable.yml`.**

| File | Trigger | `publish-web` | `google-play-track` |
| --- | --- | --- | --- |
| `deploybeta.yaml` | `beta-*` | `false` | `beta` |
| `deployprod.yaml` | `release-*` | `true` | `production` |

Both call the reusable workflow with `secrets: inherit`.

## 3. The shared pipeline — `deploy-reusable.yml`

Inputs: `flutter-version` (default `2.0.0`), `flutter-channel` (default
`stable`), `publish-web` (default `false`), `google-play-track` (default
`production`).

Steps, in order:

1. **Checkout.**
2. **Insert Android API key** — substitutes `ANDROID_API_KEY` into
   `android/app/google-services.json`.
3. **Insert web API key** — *only when `publish-web`* — substitutes
   `WEB_API_KEY` into `web/index.html`.
4. **Setup Flutter** with the pub cache enabled.
5. **Run tests** — `flutter pub get`, `flutter clean`, `flutter test`.
6. **Cache Gradle** keyed on the Android Gradle files plus `pubspec.lock`.
7. **Write JKS / Write json** — decode the base64 signing keystore and service
   account into workspace files.
8. **bundle** — writes `android/key.properties` from the env vars, generates
   launcher icons, builds the AAB, then deletes `key.properties`.
9. **Create web app** — *only when `publish-web`*.
10. **Deploy pages** — *only when `publish-web`* — publishes `build/web` to
    `gh-pages`, which serves the live demo at `https://demo.finside.org`.
11. **Deploy google play store** — uploads the AAB to `google-play-track`.

## Required repository secrets

| Secret | Used for |
| --- | --- |
| `ANDROID_API_KEY` | Android `google-services.json` |
| `WEB_API_KEY` | web `index.html` (production only) |
| `SIGN_KEY_JKS` | base64 signing keystore |
| `SERVICE_ACCOUNT_JSON` | base64 Play service account |
| `ANDROID_KEY_STORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |
| `ACCESS_TOKEN` | PAT for pushing `gh-pages` and creating tags |
| `CODECOV_TOKEN` | coverage upload (in `tag.yml`) |

## Known issues in the current design

Documented here because they are deliberately *not* changed by this
consolidation:

- Steps 2, 3 and 9 mutate **tracked files** to inject secrets. That is the
  subject of `workspace-e24.1`.
- `flutter config --enable-web` and `flutter packages pub run` are deprecated
  invocations kept verbatim; removing them is `workspace-b0p.2`.
- `tag.yml` passes `CODECOV_TOKEN` as a **command-line argument** to a script
  fetched with `curl` (`bash <(curl ...)`). Command-line arguments are visible
  in the process table and in shell traces, so this is a weaker channel than an
  environment variable, and piping a remote script straight into a shell is a
  supply-chain risk. Worth migrating to the pinned `codecov/codecov-action`.
- `tag.yml` and `test.yaml` still pin Flutter `2.0.0` independently of the
  reusable workflow's `flutter-version` input.
- `anothrNick/github-tag-action` is pinned at `1.34.0`, behind the current
  release. It is left alone deliberately: this is the action that *creates* the
  `release-*` / `beta-*` tags, so a regression here silently halts every
  deployment, and a reusable-workflow tag run cannot be exercised locally.
  Bump it on a runner where tag creation can actually be observed.

## Verifying the workflows

`actionlint` (v1.7.7) passes clean on the whole deploy set:

```sh
actionlint .github/workflows/deploy-reusable.yml \
           .github/workflows/deploybeta.yaml \
           .github/workflows/deployprod.yaml
```

A reusable workflow cannot be exercised without a real tag, so the change is
guarded by lint plus a differential check that every step and every secret from
the two original files still exists somewhere in the new set. The first
production run after merging this change should be watched end to end.
