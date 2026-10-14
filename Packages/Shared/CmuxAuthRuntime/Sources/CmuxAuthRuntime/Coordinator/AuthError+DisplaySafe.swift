import Foundation

extension AuthError {
    /// Translate a raw backend error into the display-safe ``AuthError``
    /// vocabulary, or `nil` when the original error should be surfaced
    /// unchanged.
    ///
    /// Stack error codes the sign-in UI renders specifically (schema, OTP,
    /// rate limit, etc.) yield `nil` so the view can localize them; auth
    /// failures collapse to ``AuthError`` cases; URL errors become
    /// ``AuthError/networkError``; everything else becomes a generic server
    /// error. Callers throw `AuthError(displaySafe: error) ?? error`.
    /// - Parameter error: The raw error from a sign-in/session call.
    public init?(displaySafe error: any Error) {
        if let authError = error as? AuthError {
            self = authError
            return
        }
        if error is CancellationError || Task.isCancelled {
            // A cancelled flow (the user backed out, or the sheet's task was
            // torn down) is not a failure to render. Mapping it to the generic
            // server error would flash "Something went wrong" after every
            // deliberate cancel. The `Task.isCancelled` arm matters because
            // URLSession-backed phases surface task cancellation as
            // `URLError(.cancelled)` (or a Stack transport error wrapping it),
            // not as `CancellationError`: this mapping always runs in the
            // cancelled flow's own catch, so any error caught on a cancelled
            // task is the cancellation, not an independent failure.
            self = .cancelled
            return
        }


        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            self = .networkError
            return
        }
        self = .serverError(0, "auth_failed")
    }

    /// How the coordinator should recover when validating a cached session
    /// fails with this error: only a hard ``AuthError/unauthorized`` clears
    /// the cached session; transient failures preserve it so a flaky network
    /// does not sign the user out.
    public var cachedSessionValidationFailureAction: CachedSessionValidationFailureAction {
        self == .unauthorized ? .clearSession : .preserveCachedSession
    }
}
