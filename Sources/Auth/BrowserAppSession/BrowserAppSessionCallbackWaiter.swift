import Foundation

/// Resolves a WebKit completion once, even when WebKit drops it or the caller cancels.
@MainActor
final class BrowserAppSessionCallbackWaiter {
    private var continuation: CheckedContinuation<BrowserAppSessionCallbackWaitOutcome, Never>?
    private var outcome: BrowserAppSessionCallbackWaitOutcome?
    private var timeoutTask: Task<Void, Never>?

    func wait(
        timeout: Duration,
        start: (@escaping @Sendable () -> Void) -> Void
    ) async -> BrowserAppSessionCallbackWaitOutcome {
        await withTaskCancellationHandler {
            if Task.isCancelled {
                finish(.cancelled)
            }
            if let outcome {
                return outcome
            }
            return await withCheckedContinuation { continuation in
                self.continuation = continuation
                // A deadline bounds a WebKit callback; finishing cancels the deadline.
                timeoutTask = Task { @MainActor [weak self] in
                    do {
                        try await Task.sleep(for: timeout)
                    } catch {
                        return
                    }
                    self?.finish(.timedOut)
                }
                start { [weak self] in
                    Task { @MainActor in
                        self?.finish(.completed)
                    }
                }
            }
        } onCancel: {
            Task { @MainActor in
                self.finish(.cancelled)
            }
        }
    }

    private func finish(_ resolved: BrowserAppSessionCallbackWaitOutcome) {
        guard outcome == nil else { return }
        outcome = resolved
        timeoutTask?.cancel()
        timeoutTask = nil
        let continuation = continuation
        self.continuation = nil
        continuation?.resume(returning: resolved)
    }
}
