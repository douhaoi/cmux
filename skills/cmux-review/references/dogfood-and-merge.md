# Dogfood and merge

**Verification.** Run scoped static and portable tests, then use the GitHub
packaging workflow for native build evidence. The workflow does not execute
native tests, launch the app, post PR media or publish a Release. Keep those
gates open until the needed checks run against the reviewed commit.

**Runtime evidence.** For app/runtime/UI changes, dogfood an isolated artifact
and record its commit, scenarios and results. Preserve the user's running app
and session state. Review screenshots and recordings for the actual changed
behavior. A local implementation request does not authorize uploading evidence,
opening a PR, pushing or merging.

**Approval.** The main agent owns dogfood, approval, mergeability and every
pushed fix. Merging app, runtime or UI changes requires the user's explicit
approval after dogfood, or a direct merge directive that names the merge action
(`merge`, `merge it`, `auto-merge`; `finish`, `lgtm` and `ship it` are not).

**Re-dogfood.** If a fix changes runtime behavior mid-dogfood, rerun GitHub packaging for the new commit
and re-notify, since the earlier verdict covers only the build the user tested.
After a merge directive, re-dogfood (rerun GitHub packaging for the new commit and re-notify with the
checklist) when a later fix changes user-visible behavior beyond what was
dogfooded; skip it for internal, test-only or tightly scoped fixes. Either way,
say on the PR which you did and why.

