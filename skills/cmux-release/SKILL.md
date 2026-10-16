---
name: cmux-release
description: "cmux release workflow, version bumping, changelog updates, pretag guard, release tags, and release asset expectations. Use when preparing or troubleshooting a cmux release."
---

# LocalDeck packaging

Use [Package LocalDeck](../../.github/workflows/localdeck-package.yml) on GitHub Actions.
Follow [CONTRIBUTING.md](../../CONTRIBUTING.md#github-packaging) for branch selection
and artifact download. Do not build or package locally; `build-sign-upload.sh`
is a retired entrypoint.

The workflow makes separate arm64 and x86_64 ZIP/DMG artifacts, SHA256SUMS and
commit metadata. Signing is ad hoc. It uses no Apple signing credentials, performs
no notarization, and does not publish Releases or Sparkle appcasts.

Publishing, certificate signing and notarization require a separately authorized
workflow and validation plan. A packaging request alone does not authorize
version bumps, Git tags, pushes or publication. Preserve `CHANGELOG.md` and
third-party attribution in ordinary feature work.
