# Contributor verification ladder

Use the smallest check that can expose the failure, then verify the affected
integration boundary. Native builds and packaging run in GitHub Actions;
source and portable-tooling checks can run locally.

| Change | Local evidence | Additional evidence |
| --- | --- | --- |
| Docs or scripts | Links, syntax, affected portable tests | Exercise the changed command without native compilation |
| Workspace and project configuration | Workspace generation, project checks and wiring | GitHub app build |
| Swift implementation | Syntax, focused portable checks where applicable | Native test compilation/execution and isolated runtime verification |
| UI, socket, focus or persistence | Owning behavioral regression | Runtime checks through every affected entrypoint |

## Trust boundary

Run repository commands only from a reviewed checkout. Static checks, help/list
commands, imported helpers and tracked hooks execute repository code. Selecting
`--repo` changes whose code runs; a passing preflight is not a trust attestation.
Never execute untrusted candidate code with privileged release credentials.

## Local checks

```bash
git diff --check
python3 scripts/verify-local.py --all
```

For a focused rerun use the failed check's printed command. The
[command guide](verification-receipts.md) documents selections and receipts.
Syntax parsing does not type-check imports or execute native tests.
Run the affected script tests and confirm that the expected cases executed.

Workspace membership is generated from the retained package directories:

```bash
python3 scripts/check-workspace-package-groups.py --write
python3 scripts/check-workspace-package-groups.py --check
```

Do not hand-edit workspace package groups. Test wiring is a separate check;
a passing app build does not establish that test targets compile.

## GitHub build and packaging

Use [Package LocalDeck](../.github/workflows/localdeck-package.yml), selecting
the branch in GitHub Actions. It runs source checks before arm64 and x86_64
Release builds, packages ZIP/DMG artifacts, and keeps build logs. It requires
no local native build and does not run app-host/UI tests or launch the product.

A successful architecture job establishes only that build's compilation,
package assembly, binary architecture and code-signature checks. It does not
establish native test execution, live behavior or Apple notarization.

## Runtime verification

Use an isolated development artifact when a native behavior change needs
runtime evidence. Preserve the user's running cmux and LocalDeck instances,
configuration and session state. Never quit or replace the user's running cmux
(`com.cmuxterm.app`) to validate a change.

Report native test and runtime checks separately. If no suitable native test
or dogfood lane was run, keep those gates open rather than treating source
checks or a package artifact as runtime acceptance.
