import CmuxGit
import Foundation

/// The cache-reuse inputs captured when a per-directory snapshot task starts.
struct WorkspaceGitSnapshotTaskContext: Equatable, Sendable {
    let id = UUID()
    let trackedPathEventGeneration: GitTrackedPathEventGeneration?
    let invalidationGeneration: UInt64?
}
