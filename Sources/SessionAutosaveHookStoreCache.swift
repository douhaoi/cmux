import Foundation

/// Reuses JSON decoding only when a freshly read hook store has identical bytes.
/// Process, transcript and ownership checks still run on every autosave scan.
actor SessionAutosaveHookStoreCache {
    private struct Entry {
        let data: Data
        let store: RestorableAgentHookSessionStoreFile
    }

    private let maximumBytes: Int
    private let decode: @Sendable (Data) throws -> RestorableAgentHookSessionStoreFile
    private var entries: [URL: Entry] = [:]

    init(
        maximumBytes: Int = 8 * 1024 * 1024,
        decode: @escaping @Sendable (Data) throws -> RestorableAgentHookSessionStoreFile = {
            try JSONDecoder().decode(RestorableAgentHookSessionStoreFile.self, from: $0)
        }
    ) {
        self.maximumBytes = max(0, maximumBytes)
        self.decode = decode
    }

    func load(urls: [URL]) -> [URL: RestorableAgentHookSessionStoreFile] {
        var next: [URL: Entry] = [:]
        var result: [URL: RestorableAgentHookSessionStoreFile] = [:]
        var retainedBytes = 0
        for url in Set(urls) {
            guard !Task.isCancelled else { break }
            // Read again even when mtime/size match: atomic replacement, same-size
            // writes and timestamp granularity must not hide a new hook owner.
            guard let data = try? Data(contentsOf: url) else { continue }
            let store: RestorableAgentHookSessionStoreFile
            if let cached = entries[url], cached.data == data {
                store = cached.store
            } else {
                guard let decoded = try? decode(data) else { continue }
                store = decoded
            }
            result[url] = store
            if data.count <= maximumBytes - retainedBytes {
                next[url] = Entry(data: data, store: store)
                retainedBytes += data.count
            }
        }
        entries = next
        return result
    }
}
