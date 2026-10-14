import CmuxSurfaceCatalogModel
import CmuxWorkspacePresence
import Foundation

extension Notification.Name {
    static let workspacePresenceDidChange = Notification.Name("cmux.workspacePresenceDidChange")
}

/// Compatibility projection for Cloud rows excluded from the local distribution.
@MainActor
final class WorkspacePresenceController {
    func refreshSelection() {}

    func observeCloudWorkspace(machine: SurfaceMachineID?, workspaceID: String?, owner: UUID) {}

    func collaborators(forCloudMachine machine: SurfaceMachineID, workspaceID: String) -> [WorkspacePresenceParticipant] {
        []
    }
}
