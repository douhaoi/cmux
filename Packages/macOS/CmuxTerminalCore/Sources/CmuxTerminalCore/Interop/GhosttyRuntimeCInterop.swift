public import Darwin
public import Foundation
public import GhosttyKit

/// Shared entry points for libghostty initialization and selection operations.
///
/// Calls use GhosttyKit's C declarations so the header owns their calling
/// convention and pointer nullability across package and app compilation.
// lint:allow namespace-type — shared libghostty entry points with no Swift receiver.
public struct GhosttyRuntimeCInterop {
    private static let initializationLock = NSLock()
    nonisolated(unsafe) private static var initializationResult: Int32?

    private init() {}

    /// Initializes libghostty once for the process.
    public static func initialize() -> Int32 {
        initializationLock.lock()
        defer { initializationLock.unlock() }

        if let initializationResult {
            return initializationResult
        }

        if getenv("NO_COLOR") != nil {
            unsetenv("NO_COLOR")
        }

        let result = ghostty_init(UInt(CommandLine.argc), CommandLine.unsafeArgv)
        // ghostty_init applies the user's locale. Config parsing can now be the
        // first caller, before GhosttyApp's own re-pin, so restore the
        // CoreUI-safe numeric locale here for every caller.
        _ = setlocale(LC_NUMERIC, "C")
        initializationResult = result
        return result
    }

    /// Clears the active selection on a runtime surface.
    ///
    /// Mirrors `ghostty_surface_clear_selection` from the cmux libghostty
    /// fork. The surface pointer must be a live `ghostty_surface_t`; passing a
    /// freed pointer is undefined behavior, exactly as with any other ghostty
    /// C call.
    ///
    /// - Parameter surface: The live runtime surface to clear.
    /// - Returns: Whether the runtime cleared a selection.
    @discardableResult
    public static func clearSelection(_ surface: ghostty_surface_t) -> Bool {
        ghostty_surface_clear_selection(surface)
    }

}
