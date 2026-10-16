import CmuxSettings
import Foundation

/// Compatibility sink for older call sites; this distribution has no analytics transport.
final class PostHogAnalytics: Sendable {
    static let shared = PostHogAnalytics()
    func recordLaunchIdentity() {}
    func startIfNeeded() {}
    func trackActive(reason: String) {}
    func capture(_ event: String, properties: [String: Any]) {}
    func captureCrashException(pendingCrash: GhosttyCrashBreadcrumb.PendingCrash) {}
    func trackDailyActive(reason: String) {}
    func trackHourlyActive(reason: String) {}

    nonisolated static func superProperties(infoDictionary: [String: Any]) -> [String: Any] {
        var properties: [String: Any] = ["platform": "cmuxterm"]
        properties.merge(versionProperties(infoDictionary: infoDictionary)) { _, new in new }
        return properties
    }

    nonisolated static func dailyActiveProperties(
        dayUTC: String,
        reason: String,
        infoDictionary: [String: Any]
    ) -> [String: Any] {
        var properties: [String: Any] = [
            "day_utc": dayUTC,
            "reason": reason,
        ]
        properties.merge(versionProperties(infoDictionary: infoDictionary)) { _, new in new }
        return properties
    }

    nonisolated static func hourlyActiveProperties(
        hourUTC: String,
        reason: String,
        infoDictionary: [String: Any]
    ) -> [String: Any] {
        var properties: [String: Any] = [
            "hour_utc": hourUTC,
            "reason": reason,
        ]
        properties.merge(versionProperties(infoDictionary: infoDictionary)) { _, new in new }
        return properties
    }

    /// PostHog Error Tracking payload for a previous-run crash. The crashed
    /// build's version/namespace come from the crash envelope (`crash_app_*`),
    /// while `versionProperties` describe the reporting launch, matching every
    /// other cmux event. The posthog-ios SDK additionally attaches its
    /// automatic `$app_version`/`$app_build`/`$app_namespace` at capture time.
    nonisolated static func crashExceptionProperties(
        reported: GhosttyCrashReportMetadata.ReportedException?,
        infoDictionary: [String: Any]
    ) -> [String: Any] {
        let type = sanitizedExceptionToken(reported?.type) ?? "UnknownCrash"
        let mechanism: [String: Any] = [
            "handled": false,
            "type": sanitizedExceptionToken(reported?.mechanismType) ?? "ghostty_crash_report",
        ]
        let exception: [String: Any] = [
            "type": type,
            // Envelope reasons are arbitrary app text. Do not mirror paths,
            // commands, secrets, or customer content into analytics.
            "value": "Previous launch crashed",
            "mechanism": mechanism,
        ]
        var properties: [String: Any] = [
            "$exception_level": "error",
            // Group by crash type only; the version breakdown comes from the
            // crash_app_* and version properties, not the fingerprint.
            "$exception_fingerprint": String("cmux-mac-crash:\(type)".prefix(200)),
            "$exception_list": [exception],
        ]
        if let appVersion = reported?.appVersion, !appVersion.isEmpty {
            properties["crash_app_version"] = appVersion
        }
        if let appBuild = reported?.appBuild, !appBuild.isEmpty {
            properties["crash_app_build"] = appBuild
        }
        if let appNamespace = reported?.appNamespace, !appNamespace.isEmpty {
            properties["crash_app_namespace"] = appNamespace
        }
        properties.merge(versionProperties(infoDictionary: infoDictionary)) { _, new in new }
        return properties
    }

    /// Exception and mechanism types are identifier-like tokens; anything else
    /// collapses to nil so unexpected payloads never reach PostHog.
    nonisolated static func sanitizedExceptionToken(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        guard !trimmed.isEmpty,
              trimmed.count <= 120,
              trimmed.unicodeScalars.allSatisfy(allowed.contains)
        else { return nil }
        return trimmed
    }

    nonisolated static func shouldFlushAfterCapture(event: String) -> Bool {
        switch event {
        case "cmux_daily_active", "cmux_hourly_active":
            return true
        default:
            return false
        }
    }

    nonisolated private static func versionProperties(
        infoDictionary: [String: Any],
        flavor: BuildFlavor = BuildFlavor.current
    ) -> [String: Any] {
        // `channel` answers "stable, RC, NIGHTLY or DEV?" for every Mac event; the
        // web side carries the same value on checkout as `checkout_channel`.
        var properties: [String: Any] = ["channel": flavor.rawValue]
        if let value = infoDictionary["CFBundleShortVersionString"] as? String, !value.isEmpty {
            properties["app_version"] = value
        }
        if let value = infoDictionary["CFBundleVersion"] as? String, !value.isEmpty {
            properties["app_build"] = value
        }
        return properties
    }
}
