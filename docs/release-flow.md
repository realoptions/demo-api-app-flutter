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
2. Reads the app version out of `pubspec.yaml` into `APP_VERSION` with a
   pattern anchored at column 0, so it matches the top-level `version:` key
   and cannot pick up an indented `version:` belonging to a dependency. An
   unreadable version fails the job — an empty value would otherwise produce a
   tag like `release-`, which still matches `release-*`.
3. Picks a prefix from the branch: `release` for `master`, `beta` otherwise.
4. Builds `CUSTOM_TAG` = `<prefix>-<version>`.
5. If that tag does not already exist locally, pushes it via
   `anothrNick/github-tag-action@1.75.0`.

So merging to `master` yields `release-1.6.11`, and a feature-branch push
yields `beta-1.6.11`.

## Version authority

Two numbers travel with a Flutter release and they are owned in different
places. Before this change both were hand-maintained and the second was a
ritual; now exactly one thing is edited by a human.

| Number | Owner | Where it is set |
| --- | --- | --- |
| Semantic version (`1.6.11`) | `pubspec.yaml` `version:` | edited by a human, read by `tag.yml` |
| Build number (Android `versionCode`, iOS `CFBundleVersion`) | CI | `github.run_number`, applied by `deploy-reusable.yml` |

`pubspec.yaml` deliberately carries **no `+<build>` suffix**. The previous
`version: 1.6.11+22` came with a comment saying the `+n` had to be
incremented by hand on every release even when the semantic version moved —
easy to forget, and it failed late, at the Play upload, because Play rejects
a `versionCode` that has already been published.

The release build now takes both numbers from the run rather than from the
file:

```sh
flutter build appbundle --build-name="$APP_VERSION" --build-number="$BUILD_NUMBER"
```

* `APP_VERSION` is parsed out of the tag that triggered the workflow
  (`release-1.6.11` → `1.6.11`), so the artifact is versioned with the tag
  that caused it to be built rather than whatever the file happened to say at
  checkout time. A tag that does not carry a clean `x.y.z` fails the job.
* `BUILD_NUMBER` is `github.run_number`, which is unique per repository and
  only ever increases, so it satisfies Play's strictly-increasing
  `versionCode` rule with no human in the loop. Re-running the same tag
  yields a new build number, which is what you want from a retry.

The chain is therefore `pubspec.yaml` → tag → build, with one authority per
number and no step that requires remembering anything.

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
2. **Resolve release version** — parses `APP_VERSION` from the triggering tag
   and sets `BUILD_NUMBER` from `github.run_number`; refuses to continue on a
   tag that does not carry a clean `x.y.z`.
3. **Generate Android Firebase config** — `scripts/generate_build_config.sh
   android`, fed by `ANDROID_API_KEY` from the step's `env:` mapping.
4. **Generate web Firebase config** — *only when `publish-web`* —
   `scripts/generate_build_config.sh web`, fed by `WEB_API_KEY`.
5. **Setup Flutter** with the Flutter SDK and pub caches enabled.
6. **Run tests** — `flutter pub get`, `flutter clean`, `flutter test`.
7. **Cache Gradle** keyed on the Android Gradle files plus `pubspec.lock`.
8. **Write JKS / Write json** — decode the base64 signing keystore and service
   account into workspace files.
9. **bundle** — `scripts/generate_build_config.sh keystore` renders
   `android/key.properties`, then generates launcher icons, builds the AAB
   with `--build-name` / `--build-number` from step 2, and deletes
   `key.properties`.
10. **Build web release** — *only when `publish-web`* — `flutter build web
    --release`, also carrying `--build-name` / `--build-number`, which emits
    into `build/web`. Verified against Flutter 3.47.4: the tool prints
    `✓ Built build/web`, and that is the same folder step 11 publishes. No
    web-enabling `flutter config` call is needed (web is on by default and
    the `web/` runner directory is committed here).
11. **Deploy pages** — *only when `publish-web`* — publishes `build/web` to
    `gh-pages`, which serves the live demo at `https://demo.finside.org`.
12. **Deploy google play store** — uploads the AAB to `google-play-track`.

## Caching

Every workflow that installs Flutter now caches, so a run that does not touch
`pubspec.lock` re-downloads nothing:

| Workflow | What is cached | How |
| --- | --- | --- |
| `deploy-reusable.yml` | Flutter SDK + pub cache | `subosito/flutter-action` `cache: true` |
| `deploy-reusable.yml` | Gradle caches and wrapper | `actions/cache@v4` keyed on `android/**/*.gradle`, `gradle-wrapper.properties`, `pubspec.lock` |
| `tag.yml` | Flutter SDK + pub cache | `subosito/flutter-action` `cache: true` |
| `test.yaml` | Flutter SDK + pub cache | `subosito/flutter-action` `cache: true` |

`cache: true` covers the pub dependencies as well as the SDK. That is not an
assumption read off the README — the action's own step guard is:

```yaml
if: ${{ (inputs.pub-cache == '' && inputs.cache == 'true') || inputs.pub-cache == 'true' }}
```

so an unset `pub-cache` with `cache: 'true'` takes the pub branch. There *is*
a separate `pub-cache` input, but it is deliberately not written out:
`actionlint` 1.7.7 ships a snapshot of action metadata that predates it and
reports it as an unknown input, so spelling it out would break an otherwise
clean lint for no behavioural gain. Revisit once the lint metadata catches up
— and do not "fix" that warning by removing something that works.

`flutter clean` does not undo any of this: it clears `build/` and
`.dart_tool/`, not `~/.pub-cache`, so the cache survives the clean that runs
before `flutter pub get`.

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
  touch all three. Sharing a single source (a repo variable, or a
  `.fvmrc` read through the action's `flutter-version-file` input) is the
  eventual fix.

Two things worth recording that are *not* defects here, because both look like
unfinished version bumps and neither is:

- **`subosito/flutter-action` has no `v4` to upgrade to.** The pipeline uses
  `@v2`, which is the current major line (latest release `v2.23.0`); the
  action has only ever shipped `v1` and `v2`. `@v4` would not resolve. It is
  a current pin, not a stale one.
- **`anothrNick/github-tag-action` was moved `1.34.0` → `1.75.0`.** The
  upgrade is safe for how this repo uses it: `CUSTOM_TAG` is still honoured,
  and the README states that setting it "will invalidate any other settings
  set", which is why the old `RELEASE_BRANCHES: '.*'` entry is gone — it was
  already dead config under `CUSTOM_TAG`, not a behaviour change. This is the
  action that creates the `release-*` / `beta-*` tags, so the first run after
  merging should be watched for the tag actually appearing.

## Verifying the workflows

`actionlint` (v1.7.7) passes clean over every file in `.github/workflows`:

```sh
actionlint .github/workflows/*.yml .github/workflows/*.yaml
```

A reusable workflow cannot be exercised without a real tag, so the change is
guarded by lint plus a differential check that every step and every secret from
the two original files still exists somewhere in the new set. The shell logic
that does not need a runner — the tag-to-version parse, the `release`/`beta`
prefix selection, and the rejection of malformed tags — was exercised
separately, because a workflow that first fails at release time is a bad place
to discover a quoting mistake.

`actionlint`'s bundled action metadata is a snapshot and can lag the actions it
checks — see *Caching* for a case where it reports a real input as unknown.
The first production run after merging this change should be watched end to
end.
