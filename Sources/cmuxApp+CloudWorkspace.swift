import CmuxCloud
import CmuxCloudMachines
import CmuxSurfaceCatalogModel
import Foundation

extension cmuxApp {
    /// The fleet, in its reported order, minus every machine that cannot receive
    /// a new workspace: one being deleted, or one locked past its free-access
    /// window (the same rule the sidebar's New Workspace row uses). Lock state
    /// is computed exactly as the sidebar computes it for the machine's row.
    static func cloudWorkspaceTargetMachineIDs(
        page: VMListPage,
        deleting: Set<String>,
        now: Date = Date()
    ) -> [String] {
        let windowDays = page.limits?.freeAccessWindowDays ?? 0
        return page.vms.filter { summary in
            !deleting.contains(summary.id) && MachineSnapshotBuilder
                .snapshot(from: summary, freeAccessWindowDays: windowDays, now: now)
                .acceptsNewWorkspaces
        }.map(\.id)
    }

    /// Composes the native creation path with the window and provider owners.
    /// Keeping these boundaries injectable lets shortcut tests delay remote work
    /// while exercising the same local admission and focus policy as the app.
    static func makeCloudWorkspaceCoordinator(
        machinePinStore: CloudMachinePinStore,
        allowsOperation: @escaping @MainActor @Sendable () -> Bool,
        loadMachines: @escaping @MainActor @Sendable () async throws -> [String],
        tabManager: @escaping @MainActor (UUID) -> TabManager?,
        provider: @escaping @MainActor (String) async -> (any SurfaceProvider)?,
        catalog: SurfaceCatalog
    ) -> CloudWorkspaceCoordinator {
        CloudWorkspaceCoordinator(
            machinePinStore: machinePinStore,
            allowsOperation: allowsOperation,
            loadMachines: loadMachines,
            createWorkspace: { request in
                guard let manager = tabManager(request.windowID) else { return nil }
                let validate: @MainActor () throws -> Void = { [weak manager] in
                    try Task.checkCancellation()
                    guard allowsOperation(),
                          machinePinStore.scopeIdentifier == request.scopeID,
                          let manager, !manager.isFinalizedForWindowClose else { throw CancellationError() }
                }
                try validate()
                let host = CloudWorkspaceCreationHost(manager: manager)
                let focus = request.selectionRevision == manager.cloudWorkspaceSelection.revision
                let provisionalTitle = catalog.cloudWorkspaceCreationCoordinator
                    .provisionalWorkspaceTitle(
                        machine: .cloud(request.machineID), name: nil, catalog: catalog
                    )
                let reservation = try catalog.cloudWorkspaceCreationCoordinator.reserveLocalWorkspace(
                    machine: .cloud(request.machineID),
                    title: provisionalTitle,
                    focus: focus,
                    host: host,
                    validateOperation: validate
                )
                var handedToCreation = false
                defer {
                    if !handedToCreation,
                       !catalog.cloudWorkspaceCreationCoordinator.ownsReservation(reservation) {
                        host.discard(reservation, catalog: catalog)
                    }
                }
                guard let provider = await provider(request.machineID) else {
                    throw VMClientError.backendUnreachable(url: AuthEnvironment.apiBaseURL.absoluteString, detail: "Cloud machine provider unavailable")
                }
                try validate()
                let result = try await CloudTreeNodeActions.createWorkspaceAndOpenLocally(
                    machine: .cloud(request.machineID), provider: provider, catalog: catalog,
                    name: nil, focus: focus, existingReservation: reservation, host: host,
                    validateOperation: validate
                )
                handedToCreation = true
                return result.opened?.workspaceID
            }
        )
    }
}
