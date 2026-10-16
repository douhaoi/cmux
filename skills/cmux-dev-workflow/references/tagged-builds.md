# Build and artifact ownership

## GitHub packaging

LocalDeck's native build and packaging entry is
[Package LocalDeck](../../../.github/workflows/localdeck-package.yml).
Choose the branch using GitHub Actions' manual trigger. It produces separate
arm64/x86_64 ZIP and DMG artifacts, checksums and build logs. Native packaging
is not run locally for this workflow.

The build uses an isolated runner-temporary DerivedData directory and does not
launch the app. Artifacts use ad hoc signing; public release signing and
notarization are not part of this pipeline.

## Retained development helper

`scripts/reload.sh` remains available for explicitly authorized tagged native
development. Tags isolate display name, bundle ID, socket and DerivedData.
The helper does not provision an account, backend or cloud client. Hosted-service
build options fail with an explicit unavailable error.

`--build-only` validates an isolated staging bundle, preserves the active tagged
app and removes the temporary artifact. It cannot be combined with `--launch`.
A normal reload replaces only the matching development tag; use your own tag
and clean up only artifacts you created.

## Running applications

Never quit, kill, relaunch, replace or launch-profile the user's running cmux
(`com.cmuxterm.app`). Never set `CMUX_ALLOW_REPLACING_RUNNING_CMUX`. Do not launch
an untagged development app to satisfy a runtime test.

An app build does not compile test targets or execute tests. Keep these evidence
classes separate and use the [verification guide](../../../docs/contributor-verification.md).

## Tagged CLI

```bash
CMUX_TAG=<tag> scripts/cmux-debug-cli.sh list-workspaces
```

Use the matching tagged CLI and socket, never `/tmp/cmux-cli`. Do not report raw
app-bundle paths or file URLs in chat; link the GitHub artifact or build log.
