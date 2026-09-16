# Release flow

Releases are cut by hand, and only the web app ships. A push never deploys
anything; **publishing a GitHub Release** does.

```
gh release create v1.6.12 --generate-notes     (or the Releases UI)
        |
        v
release.yml  -- reads the version out of the release tag
             -- stamps it into pubspec.yaml (build tree only)
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
| `.github/workflows/release.yml` | published GitHub Release (or a manual re-deploy) | the whole web release, gated on the tests |

## Releasing

```sh
gh release create v1.6.12 --generate-notes   # tag is created if it is missing
```

or the same thing in the Releases UI. That is the entire release. The
workflow reads `1.6.12` out of the tag, writes it into `pubspec.yaml` in its
own checkout, runs the tests, builds with `--build-name=1.6.12` and publishes
to Pages.

**You never bump `version:` in `pubspec.yaml` to ship.** See below.

Notes on the trigger:

- A tag pushed on its own (`git tag v1.6.12 && git push`) does **not**
  deploy. The trigger is the release, not the tag. The tag is where the
  version is read from.
- `types: [published]` only. A **draft** release does nothing until you
  publish it, which makes drafting-then-publishing the safe path. `edited` is
  deliberately not wired up: fixing release notes on a shipped release must
  not silently redeploy the app.
- Tags outside `v<MAJOR>.<MINOR>.<PATCH>` are rejected with an error (no
  `-beta`, no `+build`, no `latest`).

### Re-deploying without touching the release

A published release cannot be re-published, so `release.yml` also accepts a
manual run: **Run workflow → `tag` → `v1.6.12`**. It checks that tag out and
releases it. This is the path for a runner hiccup, and the reason the tag is
resolved before `actions/checkout` rather than relying on the event's ref.

Re-cutting the release itself (`gh release delete v1.6.12 --yes && gh release
create v1.6.12`) works too, but re-deploying is usually what you meant.

## Version authority

The direction was reversed from the previous design: the tag writes into
pubspec.yaml instead of pubspec.yaml having to agree with the tag.

| Thing | Owner | Notes |
| --- | --- | --- |
| Release tag (`v1.6.12`) | the human publishing the release | the trigger **and** the version |
| `pubspec.yaml` `version:` | CI stamps it from the tag | build-tree only; never pushed back |
| Build name of the artifact | CI, from the tag | `flutter build web --build-name=1.6.12` |
| Build number | CI, `github.run_number` | only ever increases |

Consequences worth being explicit about:

- **Nothing to keep in sync.** Releasing is one action. `pubspec.yaml` is a
  copy of whatever was last released (or whatever you set locally), so it can
  never make a release wrong.
- **A mismatch is a notice, not a failure.** If the repo's pubspec says
  `1.6.11` and you release `v1.7.0`, the run stamps `1.7.0` and prints a
  `::notice::` saying so. The tag won.
- **No hand-incremented build suffix.** `BUILD_NUMBER` is the run number, so
  a re-deploy is newer than what it replaces instead of a byte-identical
  retry.

### Why the stamped pubspec is never committed back

Tempting, and deliberately not done. A version bump committed by the release
job lands on the branch as a commit that is **not inside the release it just
cut** — the tag points at the commit before it. That is not syncing, it is
relocating the drift, plus a `contents: write` credential to do it, plus a
push that can conflict with whatever landed meanwhile.

Stamping in the build tree gives the whole benefit (nobody edits the file to
ship, and the tree the build reads always agrees with the tag) with none of
that. `release.yml` therefore runs with `contents: read`.

### What the stamp actually does

`scripts`-free inline logic in the "Stamp the release version into
pubspec.yaml" step:

- Replaces the top-level `version:` line, anchored at column 0 — an indented
  `version:` belonging to a dependency is neither matched nor rewritten.
- If there is no top-level `version:` line at all (a hand-written app pubspec
  can omit one), inserts one straight after `name:` so the key stays
  top-level and the file stays valid YAML.
- Re-reads the file afterwards and fails if it does not now read the tag's
  version — a substitution that silently did nothing is exactly the failure
  that would ship the wrong version, so it is checked rather than assumed.
- Is idempotent: a second stamp is a byte-for-byte no-op.
- Comments around the version line survive; only the line itself is replaced.

The value substituted is validated to `^[0-9]+\.[0-9]+\.[0-9]+$` before it
gets anywhere near `sed` or `awk -v`, so a tag cannot smuggle a replacement
expression, a newline or a shell metacharacter into the rewrite.

## No native deployment

Google Play is no longer part of this pipeline. Removed with it: the AAB
build, the keystore and service-account decoding steps, the Gradle cache,
`flutter_launcher_icons`, the `publish-android` / `google-play-track`
inputs, and the beta caller that existed only to feed the Play internal
track.

`android/`, `ios/` and `scripts/generate_build_config.sh` are untouched, so
a native build can be brought back later as its own job — nothing outside CI
was deleted to make the web the only shipping target. (`flutter_launcher_icons`
is still a dev dependency and its `flutter_icons:` config is android/ios
only, so the web bundle never needed it.)

The `release-*` and `beta-*` tags this repo used to make automatically are
gone as a scheme. Old tags of that shape stay in history and do nothing; the
versioned `v*` tag on a published release is the live thing.

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

Note the one place a workflow *does* rewrite a tracked file is the version
stamp in `release.yml` — on an untracked checkout, in a build tree nobody
commits from, with a value that is validated digits-and-dots. Different
threat model from writing a credential into a tracked file, which is what the
rule above is really guarding.

## Ordering inside the release job

```
resolve version → checkout the tag → stamp pubspec.yaml → setup Flutter
→ tests → render web config → build → cache-bust → deploy Pages
```

- Resolve comes **before checkout** so a re-deploy can name a tag other than
  the one the run came from.
- The stamp comes **before `flutter pub get`**, so the single dependency
  resolution this run performs sees the final file rather than re-resolving
  after a mutation.
- Tests come **before any secret is touched**, so a red suite fails without
  pulling credentials.

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
`.dart_tool/`, not `~/.pub-cache`, so the cache survives a clean. The Gradle
cache went with the Android build.

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
  the point: the thing that ships is gated by a run of its own.
- `pubspec.yaml` in the repository can read lower than the newest release for
  as long as nobody commits a bump — which is intended, but is a visible
  inconsistency if you look at the file expecting it to track deployments. The
  alternative (CI committing the bump) was rejected above; if the visible
  inconsistency ever becomes the bigger problem, the fix is a release-PR
  rather than a push from the deploy job.

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

A release workflow cannot be exercised without a real release, so the shell
logic was run on its own, extracted from the workflow file, against the cases
it has to get right:

- resolving: release tag present, dispatch tag present, both at once (release
  tag wins), neither (fails), `v1.6` / `-beta` / `+build` / `latest` /
  `release-1.6.11` (all rejected), and tags carrying `;rm -rf /` and `$(id)`
  (rejected before reaching a ref or a flag).
- stamping: the repo's own pubspec, an old `+build` suffix, a pubspec with no
  `version:` key at all (inserted after `name:`, re-parsed as valid YAML), a
  pubspec with neither `version:` nor `name:` (fails loudly), an indented
  dependency `version:` left alone, the file's comments preserved, a single
  top-level `version:` line afterwards, and a second stamp being a byte-exact
  no-op.

The first production release after a change to this pipeline is still worth
watching end to end — lint and logic tests cannot cover a real Pages deploy.
