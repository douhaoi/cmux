# Packaging checks

Follow [the packaging skill](../SKILL.md). Confirm the workflow ran against the
reviewed commit and both architecture jobs completed after static checks.

Download the ZIP/DMG, SHA256SUMS and build-info.txt from each job. Check signatures,
architecture, bundle identity and bundled terminal/web resources. On failure,
inspect that architecture's retained build logs before rerunning.

The artifacts are ad hoc signed and not notarized. Native test execution and
isolated installed-app behavior remain separate gates. Publishing or certificate
signing needs its own authorized plan; do not treat artifact upload as a release.
