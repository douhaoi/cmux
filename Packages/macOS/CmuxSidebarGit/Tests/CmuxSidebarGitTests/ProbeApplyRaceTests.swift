import Foundation
import Testing
import CmuxGit
@testable import CmuxSidebarGit

@MainActor
@Suite struct ProbeApplyRaceTests {
    private func makeService(
        host: RecordingSidebarGitHost,
        reader: GatedMetadataReader,
        clock: ManualGitPollClock,
        pullRequestProbing: RecordingPullRequestProbing = RecordingPullRequestProbing()
    ) -> SidebarGitMetadataService {
        let service = SidebarGitMetadataService(
            workspaceGitMetadataReader: reader,
            gitMetadataService: GitMetadataService(),
            pullRequestProbing: pullRequestProbing,
            probeLimiter: WorkspaceGitMetadataProbeLimiter(limit: 2),
            clock: clock
        )
        service.attach(host: host)
        return service
    }

    @Test(.timeLimit(.minutes(1)), arguments: [false, true])
    func remoteTrustWhileProbeInFlightDropsLocalSnapshotApply(deferApply: Bool) async throws {
        let host = RecordingSidebarGitHost()
        let (workspaceId, panelId) = host.addWorkspace(panelDirectory: "/tmp/repo")
        host.workspaces[0].state.isRemote = true
        let clock = ManualGitPollClock()
        let pullRequestProbing = RecordingPullRequestProbing()
        let reader = GatedMetadataReader(metadata: .repository(branch: "local-main"), gated: true)
        let service = makeService(
            host: host,
            reader: reader,
            clock: clock,
            pullRequestProbing: pullRequestProbing
        )

        service.scheduleWorkspaceGitMetadataRefreshIfPossible(
            workspaceId: workspaceId,
            panelId: panelId,
            reason: "test"
        )
        await clock.waitForSleeper()
        await clock.resumeNext()
        #expect(await reader.waitForProbe())

        if deferApply {
            host.terminalTypingActive = true
            await reader.openGate()
            await clock.waitForSleeper()
            host.workspaces[0].state.panels[panelId]?.hasTrustedRemoteDirectory = true
            host.terminalTypingActive = false
            await clock.resumeNext()
        } else {
            host.workspaces[0].state.panels[panelId]?.hasTrustedRemoteDirectory = true
            await reader.openGate()
        }

        #expect(await waitUntil {
            service.activeWorkspaceGitProbePanelIds(workspaceId: workspaceId).isEmpty
        })
        #expect(host.workspaces[0].state.panels[panelId]?.branch == nil)
        #expect(!host.events.contains { event in
            if case .gitBranch = event { return true }
            return false
        })
        #expect(pullRequestProbing.scheduledRefreshes.isEmpty)
        #expect(pullRequestProbing.clearedTrackingKeys.contains {
            $0.workspaceId == workspaceId && $0.panelId == panelId
        })
    }

    @Test(.timeLimit(.minutes(1)), arguments: [
        "unchanged", "filesystemEvent", "newRequest", "unwatched",
        "cancelled", "directoryChanged", "pollingDisabled",
    ])
    func snapshotFinishingDuringTypingReusesOnlyWatchedValidResults(scenario: String) async throws {
        let host = RecordingSidebarGitHost()
        let (workspaceId, panelId) = host.addWorkspace(panelDirectory: "/tmp/repo")
        let clock = ManualGitPollClock()
        let reader = GatedMetadataReader(
            metadata: .repository(branch: "local-main", isDirty: false),
            gated: true
        )
        let service = makeService(host: host, reader: reader, clock: clock)

        if scenario != "unwatched" {
            service.markWorkspaceGitSnapshotCacheEligible(directory: "/tmp/repo")
        }

        service.scheduleWorkspaceGitMetadataRefreshIfPossible(
            workspaceId: workspaceId,
            panelId: panelId,
            reason: "test"
        )
        await clock.waitForSleeper()
        await clock.resumeNext()
        #expect(await reader.waitForProbe())

        host.terminalTypingActive = true
        await reader.openGate()
        await clock.waitForSleeper()
        #expect(host.workspaces[0].state.panels[panelId]?.branch == nil)

        if scenario == "newRequest" {
            service.markWorkspaceGitSnapshotRerunPending(directory: "/tmp/repo")
        } else if scenario == "filesystemEvent" {
            service.advanceWorkspaceGitSnapshotCacheGenerationIfEligible(directory: "/tmp/repo")
        } else if scenario == "cancelled" {
            service.resetAllWorkspaceGitProbeTracking()
        } else if scenario == "directoryChanged" {
            host.workspaces[0].state.panels[panelId]?.directory = "/tmp/other-repo"
        } else if scenario == "pollingDisabled" {
            host.gitMetadataActivity = .disabled
        }

        host.terminalTypingActive = false
        await clock.resumeNext()
        if ["cancelled", "directoryChanged", "pollingDisabled"].contains(scenario) {
            #expect(await waitUntil {
                service.activeWorkspaceGitProbePanelIds(workspaceId: workspaceId).isEmpty
            })
            #expect(host.workspaces[0].state.panels[panelId]?.branch == nil)
            #expect(service.workspaceGitSnapshotTasksByDirectory.isEmpty)
            #expect(service.workspaceGitSnapshotRequestsByDirectory.isEmpty)
            #expect(await reader.probedDirectories.count == 1)
            return
        }
        if scenario != "unchanged" {
            await clock.waitForSleeper()
            await clock.resumeNext()
        }
        #expect(await waitUntil {
            host.workspaces[0].state.panels[panelId]?.branch?.branch == "local-main"
        })
        #expect(await reader.probedDirectories.count == (scenario == "unchanged" ? 1 : 2))
    }
}
