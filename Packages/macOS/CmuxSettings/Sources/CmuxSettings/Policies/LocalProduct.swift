import Foundation

/// The capabilities shipped by this local desktop distribution.
///
/// Product capabilities are fixed at build time. Preferences, restored sessions,
/// environment variables and remote flags cannot enable a removed service.
public struct LocalProduct: Sendable {
    /// Creates the local desktop capability policy.
    public init() {}

    /// Whether the distribution includes account-backed hosted services.
    public var includesHostedServices: Bool { false }

    /// Whether the distribution includes analytics or automatic updates.
    public var includesBackgroundServices: Bool { false }

    /// Whether a Settings destination belongs to this distribution.
    /// - Parameter section: The persisted Settings section identifier.
    /// - Returns: Whether the section can be displayed or searched.
    public func includesSettingsSection(_ section: String) -> Bool {
        !["account", "mobile", "cloudMachines", "computers", "networking"].contains(section)
    }

    /// Whether a socket method is supported by the local desktop distribution.
    /// - Parameter method: The fully qualified v2 socket method name.
    /// - Returns: `false` for removed account, cloud and remote-device APIs.
    public func includesSocketMethod(_ method: String) -> Bool {
        if ["workspace.cloud_vm_", "debug.cloud", "debug.mobile", "debug.device", "debug.auth", "debug.iroh", "debug.pro", "debug.pricing", "debug.native_pricing", "dogfood.feedback."].contains(where: method.hasPrefix) { return false }
        if method == "auth.login" { return true }
        let family = method.split(separator: ".", maxSplits: 1).first.map(String.init) ?? method
        return !["auth", "vm", "cloud", "mobile", "device", "devices", "hive", "aiAccounts", "ai_accounts", "feedback", "coderouter", "phone", "phone_push", "presence", "remotes", "vpn"].contains(family)
    }
}
