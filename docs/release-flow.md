# Release flow

Releases are cut by hand, and only the web app ships. A push never deploys
anything; a `v<X.Y.Z>` tag does.

```
bump version: in pubspec.yaml, commit
        |
        v
git tag v1.6.12 && git push origin v1.6.12
        |
        v
release.yml  -- checks tag == pubspec.yaml
             -- runs tests
             -- renders web config from template (WEB_API_KEY)
             -- flutter build web --build-name=1.6.12
             -- cache-bust, upload, deploy
        |
        v
GitHub Pages  (https://demo.finside.org)
```

Two workflows exist and neither one deploys from a branch:

| File | Trigger | What it does |
| --- | --- | --- |
| `.github/workflows/test.yaml` | pull request, push to `master` | format + analyze + test gates, coverage upload |
| `.github/workflows/release.yml` | push of a `v<digits>` tag | the whole web release, gated on the tests |

## Releasing

1. Edit `version:` in `pubspec.yaml` (e.g. `1.6.11` → `1.6.12`) and commit
   that on the commit you want to ship.
2. `git tag v1.6.12 && git push origin v1.6.12`.
3. Watch the `release` workflow. It either publishes `build/web` to GitHub
   Pages or fails before publishing anything.

To re-release the same version (e.g. after a runner hiccup), the tag has to
move or be re-pushed, since a tag that already exists on the remote cannot be
pushed again:

```sh
git tag -d v1.6.12 && git push origin :refs/tags/v1.6.12   # remove it
git push origin v1.6.12                                    # re-cut the same one
```

Usually you cut the next number instead.

## Version authority

`pubspec.yaml` and the tag have exactly one job each, and CI checks that they
agree instead of trusting a human to keep them in step.

| Thing | Owner | Notes |
| --- | --- | --- |
| Semantic version (`1.6.12`) | `pubspec.yaml` `version:` | edited by hand |
| Release tag (`v1.6.12`) | the human cutting the release | the only thing that triggers a deploy |
| Build name of the artifact | CI, from the **tag** | `flutter build web --build-name=1.6.12` |
| Build number | CI, `github.run_number` | only ever increases |

The first step of `release.yml` rejects, before any build starts:

- a tag that is not `v<digits>.<digits>.<digits>` (no `-beta`, no `+build`);
- a tag whose version differs from `version:` in `pubspec.yaml`.

That is the answer to "how does this work with the pubspec version": the
pubspec line is what you edit, the tag is what you fire, and if the two do not
match the release fails with a message saying so rather than publishing a
build that misreports which version it is. The tag wins for the artifact's
version name because the tag is the thing that was deliberately released.

There is still no `+<build>` suffix in `pubspec.yaml`. The build number comes
from the Actions run number, so nothing has to be hand-incremented. The old
`version: 1.6.11+22` carried a comment saying the `+n` had to be bumped by
hand on every release even when the semantic version moved — a ritual that
was easy to forget and that used to fail late, at the Play upload.

Note the trigger is `v[0-9]*`, not an exact pattern. A tag that matches
nothing in a trigger fires no workflow at all and fails *silently*, so the
filter is deliberately a little loose and the strict `x.y.z` check lives in
the job, where failing produces a readable error.

## No native deployment

Google Play is no longer part of this pipeline. Removed with it: the AAB
build, the keystore and service-account decoding steps, the Gradle cache,
`flutter_launcher_icons`, the `publish-android` / `google-play-track`
inputs, and the beta caller that existed only to feed the Play internal
track.

`android/`, `ios/` and `scripts/generate_build_config.sh` are untouched, so
a native build can be brought back later as its own job — nothing outside CI
was deleted to make the web the only shipping target.

The `release-*` and `beta-*` tags this repo used to make automatically are
gone as a scheme. Old tags of that shape stay in history and do nothing; the
`v*` scheme is the live one.

## Required repository secrets

What CI needs shrank with the native build:

| Secret | Used by | For |
| --- | --- | --- |
| `WEB_API_KEY` | `release.yml` | renders `config/firebase_config.json` (and `web/index.html`) |
| `CODECOV_TOKEN` | `test.yaml` | coverage upload |

Every one of these is consumed through a step-level `env:` mapping; none is
interpolated into the text of a `run:` script.

These are **no longer used** by CI and can be deleted from the repo settings:
`SIGN_KEY_JKS`, `SERVICE_ACCOUNT_JSON`, `ANDROID_KEY_STORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_API_KEY`, and
`ACCESS_TOKEN` (which existed only so CI could push the tags it no longer
creates). `scripts/generate_build_config.sh` still accepts the Android ones
for local or future manual native builds.

## Generated config (`scripts/generate_build_config.sh`)

Nothing that carries a credential is ever a tracked file, and no workflow
mutates a tracked file at build time.

Tracked, credential-free templates:

| Template | Rendered to (gitignored) | Placeholder source |
| --- | --- | --- |
| `config/firebase_config.json.template` | `config/firebase_config.json` | `WEB_API_KEY` |
| `web/index.html.template` | `web/index.html` | (no placeholders left) |
| `android/app/google-services.json.template` | `android/app/google-services.json` | `ANDROID_API_KEY` (native only) |
| `android/key.properties.template` | `android/key.properties` | `ANDROID_KEY_*` (native only) |

Rules the script enforces:

- Every value comes from the environment. It never takes a credential as a
  command-line argument and never echoes one.
- Substitution is done with shell parameter expansion, not by shelling out to
  `sed`, so the value never appears in a child process `argv` (visible in
  `ps`).
- A missing or empty variable is a hard error rather than a silently rendered
  blank — a release fails loudly instead of shipping a config with an empty
  key.
- Output is written with `umask 077` (owner-only).
- After substitution the generated file is re-checked for the placeholder it
  was supposed to fill, so a typo in a template cannot survive.

The same script serves local development; use a throwaway value when you do
not have the real credential:

```sh
WEB_API_KEY=local-dev scripts/generate_build_config.sh web
```

## Caching

Every workflow that installs Flutter caches, so a run that does not touch
`pubspec.lock` re-downloads nothing:

| Workflow | What is cached | How |
| --- | --- | --- |
| `release.yml` | Flutter SDK + pub cache | `subosito/flutter-action` `cache: true` |
| `test.yaml` | Flutter SDK + pub cache | `subosito/flutter-action` `cache: true` |

`cache: true` covers the pub dependencies as well as the SDK. That is not an
assumption read off the README — the action's own step guard is:

```yaml
if: ${{ (inputs.pub-cache == '' && inputs.cache == 'true') || inputs.pub-cache == 'true' }}
```

so an unset `pub-cache` with `cache: 'true'` takes the pub branch. There *is*
a separate `pub-cache` input, but it is deliberately not written out:
actionlint's bundled action metadata snapshot can lag the actions it checks
(it reported `pub-cache` as an unknown input back at 1.7.7), so spelling it
out would break an otherwise clean lint for no behavioural gain.

`flutter clean` does not undo any of this: it clears `build/` and
`.dart_tool/`, not `~/.pub-cache`, so the cache survives the clean that runs
before `flutter pub get`.

The Gradle cache went with the Android build.

## Cache-busting the web bundle

`flutter build web` emits unversioned filenames and GitHub Pages answers them
with `Cache-Control: max-age=600`, so a redeploy can leave a visitor on the
previous release's bootstrap — and through it the previous app — for as long
as that cache holds. `scripts/cache_bust_web.sh` tags the two links that
decide which code runs with a content hash:

```
index.html            -> flutter_bootstrap.js?v=<hash of flutter_bootstrap.js>
flutter_bootstrap.js -> main.dart.js?v=<hash of main.dart.js>
```

Each deploy is therefore a guaranteed cache miss for what changed and still
cacheable forever for what did not. The script is idempotent (it rewrites an
existing `?v=` rather than failing on it) and dies loudly if it cannot tag
something.

## Known issues in the current design

Documented rather than quietly left out:

- Piping the Codecov uploader straight from `curl` into a shell is still a
  supply-chain risk (the token travels in `CODECOV_TOKEN` in the environment
  rather than on the command line, but the *script* is unpinned). Worth
  migrating to a pinned `codecov/codecov-action`.
- The live Android API key that used to sit in the committed
  `android/app/google-services.json` is still in git history. The template
  stops new leaks; it does not remove the old value. Rotating that key in the
  Firebase console is the actual fix and has to be done by a project owner.
  Deleting the Android secrets from the repo settings does not retire the
  value that is already public, either.
- The Flutter version is written in two places — `release.yml` and
  `test.yaml` (with `.metadata` pointing at the matching stable revision).
  They are still independent literals rather than one value, so a bump has to
  touch both. A single source (a repo variable, or a `.fvmrc` read through
  the action's `flutter-version-file` input) is the eventual fix.
- `release.yml` runs the suite itself rather than reusing `test.yaml`, so a
  release runs the tests again even when the PR already passed them. That is
  the point: the thing that ships is gated by a run of its own, on the commit
  that is tagged.

Two things worth recording that are *not* defects, because both look like
unfinished version bumps and neither is:

- **`subosito/flutter-action` has no `v4` to upgrade to.** The pipeline uses
  `@v2`, which is the current major line (latest release `v2.23.0`); the
  action has only ever shipped `v1` and `v2`. `@v4` would not resolve.
- **`actions/checkout@v7`, `configure-pages@v6`,
  `upload-pages-artifact@v5` and `deploy-pages@v5`** are current pins, kept
  as they were. Dependabot's `github-actions` ecosystem keeps proposing bumps
  for all of them.

## Verifying the workflows

`actionlint` (verified with 1.7.12) passes clean over every file in
`.github/workflows`:

```sh
actionlint .github/workflows/*.yml .github/workflows/*.yaml
```

A release workflow cannot be exercised without a real tag, so the version-check
logic was run on its own against the cases it has to get right — a good tag,
a tag with a suffix, a tag that does not match pubspec, and a pubspec with no
readable version — rather than being discovered at release time. The first
production release after this change is still worth watching end to end.
