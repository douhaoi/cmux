# Contributing to LocalDeck

LocalDeck is a local macOS fork of cmux. Keep changes scoped to its retained
terminal, browser, workspace and local automation capabilities. Read
[CLAUDE.md](CLAUDE.md), the matching [task skill](skills/README.md), and
[STYLE.md](STYLE.md) before changing an area.

## Source verification

Run repository commands only in a [trusted checkout](docs/contributor-verification.md#trust-boundary).
From the repository root:

```bash
git diff --check
python3 scripts/verify-local.py --all
```

Run affected portable tests as well. These checks do not compile the app,
execute native tests or establish runtime behavior. The
[verification ladder](docs/contributor-verification.md) describes those boundaries.

Swift changes must remain compatible with Swift 6.0. Use the existing package
owners and preserve test wiring. After adding, renaming or deleting a
`cmuxTests/` file, run `scripts/sync-test-wiring`. User-facing native strings
require the [localization audit](skills/cmux-localization/SKILL.md).

## GitHub packaging

Native packaging runs on GitHub-hosted runners through
[Package LocalDeck](.github/workflows/localdeck-package.yml). Choose the branch
with **Actions → Package LocalDeck → Run workflow**. The workflow must be present
on the repository's default branch before GitHub exposes its manual trigger.

The workflow runs static checks, initializes Ghostty and bonsplit, installs the
pinned Zig/Bun tools and Rust toolchains, builds embedded resources, then produces
separate arm64 and x86_64 ZIP/DMG artifacts. Xcode uses the major declared by
`.xcode-version`. Failed jobs retain their build logs.

The artifacts use `com.cmuxterm.local` and ad hoc signing. Apple certificate,
notarization, public Release and auto-update publication are separate work;
no upstream credentials or hosted backend are needed. This workflow does not
launch the app or execute native tests.

Do not run local native builds or packaging for this cleanup. `scripts/reload.sh`
remains an isolated development helper; `scripts/setup.sh` prepares native build
dependencies only when that work is explicitly needed.

## Changes and review

- Preserve user changes and keep each implementation slice independently reviewable.
- Add behavioral regression coverage for bug fixes; retain the focused red/green evidence.
- Use [STYLE.md](STYLE.md) for issues and PR descriptions. Describe what actually ran.
- Fill the PR's Changelog section with an Added/Changed/Fixed/Removed line for a
  user-visible change, otherwise `none`. Do not edit `CHANGELOG.md` in feature work.
- Review substantial changes before merging. App/runtime/UI merges need explicit
  approval after dogfood or a direct merge directive.
- Do not push, publish, tag or merge as part of an ordinary local cleanup request.

## License and provenance

Preserve [LICENSE](LICENSE) and all third-party notices. Retained relay/server
components may have different license terms from the native app. Do not copy
outside contributions into those directories without satisfying their CLA rules.
