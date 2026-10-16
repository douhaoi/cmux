import Foundation
import Testing

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

struct SessionAutosaveHookStoreCacheTests {
    @Test
    func readsSameSizeChangesEvenWhenModificationDateIsUnchanged() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let decodes = AsyncStream<Data>.makeStream()
        let cache = SessionAutosaveHookStoreCache { data in
            decodes.continuation.yield(data)
            return try JSONDecoder().decode(RestorableAgentHookSessionStoreFile.self, from: data)
        }
        let timestamp = Date(timeIntervalSince1970: 1)
        try Data(#"{"version":1,"sessions":{}}"#.utf8).write(to: url)
        try FileManager.default.setAttributes([.modificationDate: timestamp], ofItemAtPath: url.path)
        let first = await cache.load(urls: [url])
        let unchanged = await cache.load(urls: [url])
        #expect(first[url]?.version == 1)
        #expect(unchanged[url]?.version == 1)

        try Data(#"{"version":2,"sessions":{}}"#.utf8).write(to: url)
        try FileManager.default.setAttributes([.modificationDate: timestamp], ofItemAtPath: url.path)
        let changed = await cache.load(urls: [url])
        #expect(changed[url]?.version == 2)
        decodes.continuation.finish()
        var decodedCount = 0
        for await _ in decodes.stream { decodedCount += 1 }
        #expect(decodedCount == 2, "Unchanged bytes reuse decoding; a same-size write is decoded again")
    }

    @Test(arguments: [0, 1024])
    func corruptionAndRemovalNeverReturnLastGoodStore(maximumBytes: Int) async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let cache = SessionAutosaveHookStoreCache(maximumBytes: maximumBytes)
        try Data(#"{"version":1,"sessions":{}}"#.utf8).write(to: url)
        #expect(await cache.load(urls: [url])[url]?.version == 1)
        try Data("invalid JSON".utf8).write(to: url)
        #expect(await cache.load(urls: [url])[url] == nil)
        try FileManager.default.removeItem(at: url)
        #expect(await cache.load(urls: [url])[url] == nil)
        try Data(#"{"version":2,"sessions":{}}"#.utf8).write(to: url)
        #expect(await cache.load(urls: [url])[url]?.version == 2)
    }
}
