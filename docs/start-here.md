# Start here

LocalDeck is a local macOS fork of cmux. Begin with [CONTRIBUTING.md](../CONTRIBUTING.md)
and the [task skills](../skills/README.md). Scope changes to the retained terminal,
browser, workspaces and local automation capabilities.

Run `python3 scripts/verify-local.py --all` and affected portable tests locally.
[Verification boundaries](contributor-verification.md) distinguish static checks,
native compilation, executed tests and runtime evidence.

Build and package through [Package LocalDeck](../.github/workflows/localdeck-package.yml)
on GitHub Actions. Download the architecture-specific artifacts and verify their
SHA256SUMS. Do not package locally. The workflow uses ad hoc signing, without
notarization or Release publication, and does not launch the app or run native tests.

Preserve licenses, third-party attribution and user changes. A local implementation
request does not authorize pushes, publication or merging.
