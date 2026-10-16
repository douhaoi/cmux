# GitHub workflow coverage

The fork has one manually dispatched [packaging workflow](../../../.github/workflows/localdeck-package.yml).
There is no automatic pull-request test router or fleet label contract.

The checks job runs `python3 scripts/verify-local.py --all`. The arm64/x86_64 jobs
compile the Release app, verify binary architectures and signatures, and upload
ZIP/DMG artifacts. Read the run's commit and executed steps before reporting a pass.

The workflow does not execute native tests or validate an installed app. Retained
regressions without a current workflow command are `manual` in
`tests/test-execution.toml`; the generic lane runner alone does not establish CI coverage.
Add a dedicated test job when a change requires those gates, then confirm cases
actually ran. `full-ci`, `unit-ci` and `dev-build` have no effect in this fork.
