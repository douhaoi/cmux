import Foundation
import Combine
import Testing
import CmuxAgentSessionStore

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

@Suite(.serialized)
struct SessionIndexSnapshotLoaderTests {
    @MainActor
    @Test
    func twoThousandTranscriptCorpusScansOffMainActor() async throws {
        let corpus = try await SessionIndexSyntheticCorpus.create(
            projectCount: 20,
            transcriptsPerProject: 100
        )
        let loader = SessionIndexSnapshotLoader {
            corpus.loadEntries()
        }
        let entries = await loader.load(
            ampSessionRepository: AmpHookSessionRepository()
        )
        await corpus.remove()

        #expect(entries.count == 2_000)
        #expect(entries.allSatisfy { $0.title == "off-main" })
    }

    @MainActor
    @Test(.timeLimit(.minutes(1)))
    func manualReloadPublishesSessionsAddedSincePreviousSnapshot() async {
        let defaults = UserDefaults.standard
        let keys = ["sessionIndex.agentOrder", "sessionIndex.directoryOrder"]
        let previous = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, previous) {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        let firstEntry = Self.makeEntry(id: "first", title: "before refresh")
        let secondEntry = Self.makeEntry(id: "second", title: "after refresh")
        let source = SessionIndexReloadSource(snapshots: [[firstEntry], [firstEntry, secondEntry]])
        let store = SessionIndexStore(snapshotLoader: SessionIndexSnapshotLoader { await source.nextSnapshot() })

        store.reload()
        #expect(store.isLoading)
        for await isLoading in store.$isLoading.values {
            if !isLoading { break }
        }
        #expect(store.entries.map(\.title) == ["before refresh"])

        store.reload()
        #expect(store.isLoading)
        #expect(store.entries == [firstEntry], "Keep the current list while refreshing")
        for await isLoading in store.$isLoading.values {
            if !isLoading { break }
        }
        #expect(store.entries.map(\.id) == [firstEntry.id, secondEntry.id])
        #expect(store.entries.map(\.title) == ["before refresh", "after refresh"])
    }

    @MainActor
    @Test(.timeLimit(.minutes(1)), arguments: [false, true])
    func reloadPublishesOnlyWhenTheCompleteEntryChanges(changeTitle: Bool) async {
        let restoreDefaults = Self.preserveSessionOrder()
        defer { restoreDefaults() }
        let entry = Self.makeEntry(id: "unchanged", title: "same payload")
        let refreshed = Self.makeEntry(id: "unchanged", title: changeTitle ? "new title" : "same payload")
        let source = SessionIndexReloadSource(snapshots: [[entry], [refreshed]])
        let store = SessionIndexStore(snapshotLoader: SessionIndexSnapshotLoader { await source.nextSnapshot() })
        var publications = 0
        let subscription = store.$entries.dropFirst().sink { _ in publications += 1 }
        defer { subscription.cancel() }
        for _ in 0..<2 {
            store.reload()
            for await isLoading in store.$isLoading.values {
                if !isLoading { break }
            }
        }
        #expect(store.entries == [refreshed])
        #expect(publications == (changeTitle ? 2 : 1))
    }

    @MainActor
    @Test(.timeLimit(.minutes(1)))
    func overlappingReloadsFinishWithOneFreshFollowupScan() async {
        let restoreDefaults = Self.preserveSessionOrder()
        defer { restoreDefaults() }
        let old = Self.makeEntry(id: "old", title: "removed during refresh")
        let fresh = Self.makeEntry(id: "new", title: "added during refresh")
        let source = GatedSessionIndexReloadSource(first: [old], next: [fresh])
        let store = SessionIndexStore(snapshotLoader: SessionIndexSnapshotLoader { await source.load() })
        store.reload()
        await source.waitForFirstScan()
        store.reload()
        store.reload()
        store.reload()
        #expect(await source.scanCount == 1)
        await source.releaseFirstScan()
        for await isLoading in store.$isLoading.values {
            if !isLoading { break }
        }
        #expect(await source.scanCount == 2)
        #expect(store.entries == [fresh])
    }

    @MainActor
    private static func preserveSessionOrder() -> () -> Void {
        let defaults = UserDefaults.standard
        let keys = ["sessionIndex.agentOrder", "sessionIndex.directoryOrder"]
        let previous = keys.map { defaults.object(forKey: $0) }
        return {
            for (key, value) in zip(keys, previous) {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
    }

    private static func makeEntry(id: String, title: String) -> SessionEntry {
        SessionEntry(
            id: "claude:/tmp/\(id).jsonl",
            agent: .claude,
            sessionId: id,
            title: title,
            cwd: "/tmp",
            gitBranch: nil,
            pullRequest: nil,
            modified: Date(timeIntervalSince1970: 1),
            fileURL: nil,
            specifics: .claude(model: nil, permissionMode: nil, configDirectoryForResume: nil)
        )
    }
}

private actor GatedSessionIndexReloadSource {
    private let first: [SessionEntry]
    private let next: [SessionEntry]
    private let started = AsyncStream<Void>.makeStream()
    private let released = AsyncStream<Void>.makeStream()
    private(set) var scanCount = 0

    init(first: [SessionEntry], next: [SessionEntry]) {
        self.first = first
        self.next = next
    }

    func load() async -> [SessionEntry] {
        scanCount += 1
        guard scanCount == 1 else { return next }
        started.continuation.yield(())
        var iterator = released.stream.makeAsyncIterator()
        _ = await iterator.next()
        return first
    }

    func waitForFirstScan() async {
        var iterator = started.stream.makeAsyncIterator()
        _ = await iterator.next()
    }

    func releaseFirstScan() { released.continuation.yield(()) }
}

private actor SessionIndexReloadSource {
    private var snapshots: [[SessionEntry]]

    init(snapshots: [[SessionEntry]]) {
        self.snapshots = snapshots
    }

    func nextSnapshot() -> [SessionEntry] {
        snapshots.isEmpty ? [] : snapshots.removeFirst()
    }
}
