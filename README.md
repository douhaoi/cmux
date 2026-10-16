# LocalDeck

A local macOS terminal and browser workspace for coding agents, derived from
[manaflow-ai/cmux](https://github.com/manaflow-ai/cmux).

[简体中文](README.zh-CN.md)

## Included

- Ghostty terminal rendering, tabs, splits and saved workspaces.
- An embedded browser, file and diff viewers.
- Agent notifications, hooks, a bundled CLI and local socket automation.
- Existing local configuration and SSH functionality.

Accounts, hosted Cloud machines, mobile pairing, VPN services, telemetry and
automatic updates are unavailable in this distribution. Native cloud code that
has not yet been detached remains in the source tree behind the product policy.

## Packages

Native builds and packaging run in GitHub Actions. Open **Actions → Package
LocalDeck → Run workflow**, choose the branch, and download its artifacts after
both architecture jobs pass. The workflow is defined in
[localdeck-package.yml](.github/workflows/localdeck-package.yml).

Each architecture produces a ZIP, a DMG, SHA-256 checksums and build metadata.
Packages are ad hoc signed, without Apple notarization; they are development
artifacts, not a notarized public release. No upstream release, Homebrew tap or
update feed is used. Install the matching architecture and update manually.

## Configuration

The app uses bundle ID `com.cmuxterm.local`, configuration at
`~/.config/cmux-local/cmux.json`, and state at `~/.local/state/cmux-local`.
The bundled CLI retains the `cmux` command name for existing local integrations.

See [appearance](docs/customizing-appearance.md),
[shell integration](docs/shell-integration.md) and
[contributor verification](docs/contributor-verification.md).

## Development

Use [CONTRIBUTING.md](CONTRIBUTING.md) for source checks and GitHub packaging.
No local native build is required for the cleanup workflow.

## License and provenance

LocalDeck derives from cmux and retains its license and third-party notices.
See [LICENSE](LICENSE) for the exact license scope. Retained relay components
have their own license terms; this fork does not relicense them.
