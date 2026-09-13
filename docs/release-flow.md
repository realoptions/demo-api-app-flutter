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

Inputs: `flutter-version` (default `3.47.4`), `flutter-channel` (default
`stable`), `publish-web` (default `false`), `google-play-track` (default
`production`).

Steps, in order:

1. **Checkout.**
2. **Generate Android Firebase config** — `scripts/generate_build_config.sh
   android`, fed by `ANDROID_API_KEY` from the step's `env:` mapping.
3. **Generate web Firebase config** — *only when `publish-web`* —
   `scripts/generate_build_config.sh web`, fed by `WEB_API_KEY`.
4. **Setup Flutter** with the pub cache enabled.
5. **Run tests** — `flutter pub get`, `flutter clean`, `flutter test`.
6. **Cache Gradle** keyed on the Android Gradle files plus `pubspec.lock`.
7. **Write JKS / Write json** — decode the base64 signing keystore and service
   account into workspace files.
8. **bundle** — `scripts/generate_build_config.sh keystore` renders
   `android/key.properties`, then generates launcher icons, builds the AAB and
   deletes `key.properties`.
9. **Build web release** — *only when `publish-web`* — `flutter build web
   --release`, which emits into `build/web`. Verified against Flutter 3.47.4:
   the tool prints `✓ Built build/web`, and that is the same folder step 10
   publishes. No web-enabling `flutter config` call is needed (web is on by
   default and the `web/` runner directory is committed here).
10. **Deploy pages** — *only when `publish-web`* — publishes `build/web` to
    `gh-pages`, which serves the live demo at `https://demo.finside.org`.
11. **Deploy google play store** — uploads the AAB to `google-play-track`.

## Generated config (`scripts/generate_build_config.sh`)

Nothing that carries a credential is ever a tracked file, and no workflow mutates
a tracked file at build time.

Tracked, credential-free templates:

| Template | Rendered to (gitignored) | Placeholder source |
| --- | --- | --- |
| `android/app/google-services.json.template` | `android/app/google-services.json` | `ANDROID_API_KEY` |
| `web/index.html.template` | `web/index.html` | `WEB_API_KEY` |
| `android/key.properties.template` | `android/key.properties` | `ANDROID_KEY_*`, `ANDROID_KEYSTORE_PATH` |

Rules the script enforces:

- Every value comes from the environment. It never takes a credential as a
  command-line argument and never echoes one.
- Substitution is done with shell parameter expansion, not by shelling out to
  `sed`, so the value never appears in a child process `argv` (visible in `ps`).
- A missing or empty variable is a hard error rather than a silently rendered
  blank — a release fails loudly instead of shipping a config with an empty key.
- Output is written with `umask 077` (owner-only).
- After substitution the generated file is re-checked for the placeholder it was
  supposed to fill, so a typo in a template cannot survive.

The same script serves local development; use a throwaway value when you do not
have the real credential:

```sh
ANDROID_API_KEY=local-dev scripts/generate_build_config.sh android
WEB_API_KEY=local-dev     scripts/generate_build_config.sh web
```

Re-running the Android render with the real project key reproduces the file that
used to be committed byte-for-byte (plus a trailing newline), which is what
`apply plugin: 'com.google.gms.google-services'` needs at build time.

## Required repository secrets

Every one of these is consumed through a step-level `env:` mapping; none is
interpolated into the text of a `run:` script.

| Secret | Used for |
| --- | --- |
| `ANDROID_API_KEY` | Android `google-services.json` (rendered) |
| `WEB_API_KEY` | web `index.html` (production only) |
| `SIGN_KEY_JKS` | base64 signing keystore |
| `SERVICE_ACCOUNT_JSON` | base64 Play service account |
| `ANDROID_KEY_STORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |
| `ACCESS_TOKEN` | PAT for pushing `gh-pages` and creating tags |
| `CODECOV_TOKEN` | coverage upload (in `tag.yml`), read from the environment |

## Known issues in the current design

Documented here because they are deliberately *not* changed by this
consolidation:

- Piping the Codecov uploader straight from `curl` into a shell is still a
  supply-chain risk (the token itself is now passed via `CODECOV_TOKEN` in the
  environment instead of a command-line argument, but the *script* is still
  unpinned). Worth migrating to a pinned `codecov/codecov-action`.
- The live Android API key that used to sit in the committed
  `android/app/google-services.json` is still in git history. Moving it to a
  template stops new leaks; it does not remove the old value. Rotating that key
  in the Firebase console is the actual fix and has to be done by a project
  owner.
- The Flutter version is written in three places — the reusable workflow's
  `flutter-version` default, `tag.yml` and `test.yaml`. All three now sit at
  `3.47.4` (with `.metadata` pointing at the matching stable revision), but
  they are still independent literals rather than one value, so a bump has to
  touch all three. Sharing a single source (a repo variable or reading
  `.metadata`) is the eventual fix.
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
