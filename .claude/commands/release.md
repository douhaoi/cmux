# Package LocalDeck

Read [the packaging skill](../../skills/cmux-release/SKILL.md) and
[CONTRIBUTING.md](../../CONTRIBUTING.md#github-packaging).

Build and package through GitHub Actions → Package LocalDeck → Run workflow,
selecting the reviewed branch. Do not run local native packaging. A workflow
must be present on the default branch before its manual trigger is exposed.

Check the run's commit, static-check results and both architecture jobs. Download
ZIP/DMG artifacts with SHA256SUMS and build-info.txt. Report failed or skipped jobs;
packaging does not establish native-test execution, launch behavior or notarization.

Push, workflow dispatch, tags and publication require authorization for those
remote actions. The workflow itself only uploads run artifacts.
