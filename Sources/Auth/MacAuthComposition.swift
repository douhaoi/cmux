import CmuxCloud
import CmuxAuthRuntime
import AppKit
import Foundation

/// Residual hosted-account type references. The local app never constructs this graph.
@MainActor
struct MacAuthComposition {
    /// The shared auth orchestrator (session state, tokens, teams).
    let coordinator: AuthCoordinator
    /// Recognizes/parses auth callback URLs (AppDelegate URL routing).
    let callbackRouter: AuthCallbackRouter
    /// The hosted-browser sign-in flow used by app-session recovery.
    let browserSignIn: HostBrowserSignInFlow
    /// Bridges the native Stack session into explicitly opened cmux web panes.
    let browserAppSession: BrowserAppSessionController
    /// Shared observable account projection used by Settings and sidebar UI.
    let accountFlow: HostAccountFlow

}
