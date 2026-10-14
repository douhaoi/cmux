import Foundation
import os

func sentryBreadcrumb(_ message: String, category: String = "ui", data: [String: Any]? = nil) {
    Logger(subsystem: Bundle.main.bundleIdentifier ?? "cmux.local", category: category).debug("\(message, privacy: .public)")
}

func sentryCaptureWarning(_ message: String, category: String = "ui", data: [String: Any]? = nil, contextKey: String? = nil) {
    Logger(subsystem: Bundle.main.bundleIdentifier ?? "cmux.local", category: category).warning("\(message, privacy: .public)")
}

func sentryCaptureError(_ message: String, category: String = "ui", data: [String: Any]? = nil, contextKey: String? = nil) {
    Logger(subsystem: Bundle.main.bundleIdentifier ?? "cmux.local", category: category).error("\(message, privacy: .public)")
}

@MainActor func sentryStartMemoryContextRefresh() {}
@MainActor func sentryStopMemoryContextRefresh() {}
nonisolated func sentryRefreshMemoryContext(reason: String) async {}
