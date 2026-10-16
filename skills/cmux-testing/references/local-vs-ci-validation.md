# Choose verification for the change

Run repository commands only from a [trusted checkout](../../../docs/contributor-verification.md#trust-boundary).
Start with local source checks and the affected portable tests:

```bash
python3 scripts/verify-local.py --all
```

For edited Swift, `--only swift-syntax --swift-changed` parses the changed files
with the installed compiler. This does not type-check imports or run tests.
Use the failed check's printed command for a focused rerun.

## Native compilation and packaging

Native builds and packaging use
[Package LocalDeck](../../../.github/workflows/localdeck-package.yml) on GitHub.
Do not build or package locally for this workflow. The manual architecture jobs
compile the Release app and upload ZIP/DMG artifacts, checksums and build logs.
They do not compile test targets or execute native tests.

For a native behavior change, the owning test suite still needs an explicit
native test lane and isolated runtime evidence. The former upstream fleet,
focused E2E dispatcher and hosted runner selectors are retired; they do not
provide a usable test gate in this fork. Never claim their coverage from a
static pass or a packaging result.

## Runtime and socket checks

Use a separately authorized isolated development artifact. For retained Python
socket tests in `tests_v2/`, set `CMUX_SOCKET_PATH` to that artifact's socket.
For CLI dogfood use `CMUX_TAG=<tag> scripts/cmux-debug-cli.sh ...`, never the
ambient `/tmp/cmux-cli` link. Confirm the tested artifact and source commit.
Preserve the user's running cmux, LocalDeck and saved sessions.

Report source checks, app compilation, test compilation, executed native tests
and runtime observations separately, including any remaining gates.
