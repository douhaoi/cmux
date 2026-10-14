import Foundation
import Testing

#if canImport(cmux_DEV)
@testable import cmux_DEV

@Suite(.serialized)
struct PostHogAnalyticsPropertiesTests {
    @MainActor
    @Test func localFlagsIgnoreCachedRolloutAndInjectedNetworkLoader() async throws {
        let suite = "cmux.local.flags.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = CmuxFeatureFlags.appKitSidebarListFlag.key
        defaults.set(true, forKey: "cmux.flags.remote.\(key)")
        defaults.set(false, forKey: "cmux.flags.override.\(key)")
        let probe = FeatureFlagRemoteLoaderProbe()
        let flags = CmuxFeatureFlags(defaults: defaults, remoteFlagValueProvider: { _ in true },
            remoteFlagLoader: { await probe.load() }, pinsFlagsToLocalValues: false)
        flags.start()
        flags.applyLoadedFlags()
        #expect(!flags.isAppKitSidebarListEnabled)
        #expect(!flags.isMobileConnectButtonEnabled)
        #expect(!flags.isSidebarAccountButtonEnabled)
        #expect(!flags.isGoPlanEnabled)
        #expect(await probe.callCount == 0)
    }

    @MainActor
    @Test(arguments: [false, true])
    func localControlPlaneCannotCreateRequestsOrInstallationIdentity(consent: Bool) throws {
        let suite = "cmux.local.identity.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(CmuxFeatureFlags.postHogControlPlaneRequest(telemetryEnabled: consent, defaults: defaults) == nil)
        #expect(defaults.object(forKey: "cmux.flags.releaseControlDistinctID") == nil)
    }

    @Test
    func dailyActivePropertiesIncludeVersionAndBuild() {
        let properties = PostHogAnalytics.dailyActiveProperties(
            dayUTC: "2026-02-21",
            reason: "didBecomeActive",
            infoDictionary: [
                "CFBundleShortVersionString": "0.31.0",
                "CFBundleVersion": "230",
            ]
        )

        #expect(properties["day_utc"] as? String == "2026-02-21")
        #expect(properties["reason"] as? String == "didBecomeActive")
        #expect(properties["app_version"] as? String == "0.31.0")
        #expect(properties["app_build"] as? String == "230")
    }

    @Test
    func superPropertiesIncludePlatformVersionAndBuild() {
        let properties = PostHogAnalytics.superProperties(
            infoDictionary: [
                "CFBundleShortVersionString": "0.31.0",
                "CFBundleVersion": "230",
            ]
        )

        #expect(properties["platform"] as? String == "cmuxterm")
        #expect(properties["app_version"] as? String == "0.31.0")
        #expect(properties["app_build"] as? String == "230")
    }

    @Test
    func hourlyActivePropertiesIncludeVersionAndBuild() {
        let properties = PostHogAnalytics.hourlyActiveProperties(
            hourUTC: "2026-02-21T14",
            reason: "didBecomeActive",
            infoDictionary: [
                "CFBundleShortVersionString": "0.31.0",
                "CFBundleVersion": "230",
            ]
        )

        #expect(properties["hour_utc"] as? String == "2026-02-21T14")
        #expect(properties["reason"] as? String == "didBecomeActive")
        #expect(properties["app_version"] as? String == "0.31.0")
        #expect(properties["app_build"] as? String == "230")
    }

    @Test
    func hourlyPropertiesOmitVersionFieldsWhenUnavailable() {
        let properties = PostHogAnalytics.hourlyActiveProperties(
            hourUTC: "2026-02-21T14",
            reason: "activeTimer",
            infoDictionary: [:]
        )

        #expect(properties["hour_utc"] as? String == "2026-02-21T14")
        #expect(properties["reason"] as? String == "activeTimer")
        #expect(properties["app_version"] == nil)
        #expect(properties["app_build"] == nil)
    }

    @Test
    func propertiesOmitVersionFieldsWhenUnavailable() {
        let superProperties = PostHogAnalytics.superProperties(infoDictionary: [:])
        #expect(superProperties["platform"] as? String == "cmuxterm")
        #expect(superProperties["app_version"] == nil)
        #expect(superProperties["app_build"] == nil)

        let dailyProperties = PostHogAnalytics.dailyActiveProperties(
            dayUTC: "2026-02-21",
            reason: "activeTimer",
            infoDictionary: [:]
        )
        #expect(dailyProperties["day_utc"] as? String == "2026-02-21")
        #expect(dailyProperties["reason"] as? String == "activeTimer")
        #expect(dailyProperties["app_version"] == nil)
        #expect(dailyProperties["app_build"] == nil)
    }

    @Test
    func flushPolicyIncludesDailyAndHourlyActiveEvents() {
        #expect(PostHogAnalytics.shouldFlushAfterCapture(event: "cmux_daily_active"))
        #expect(PostHogAnalytics.shouldFlushAfterCapture(event: "cmux_hourly_active"))
        #expect(!PostHogAnalytics.shouldFlushAfterCapture(event: "cmux_other_event"))
    }

    @Test
    func crashExceptionPropertiesIncludeCrashAndLaunchVersions() throws {
        let reported = GhosttyCrashReportMetadata.ReportedException(
            type: "EXC_BAD_ACCESS",
            value: "KERN_INVALID_ADDRESS at 0x0000000000000000",
            mechanismType: "mach",
            appVersion: "0.64.22",
            appBuild: "6422",
            appNamespace: "com.cmuxterm.local"
        )
        let properties = PostHogAnalytics.crashExceptionProperties(
            reported: reported,
            infoDictionary: [
                "CFBundleShortVersionString": "0.64.23",
                "CFBundleVersion": "6423",
            ]
        )

        #expect(properties["$exception_level"] as? String == "error")
        #expect(properties["$exception_fingerprint"] as? String == "cmux-mac-crash:EXC_BAD_ACCESS")
        let list = try #require(properties["$exception_list"] as? [[String: Any]])
        let entry = try #require(list.first)
        #expect(entry["type"] as? String == "EXC_BAD_ACCESS")
        #expect(entry["value"] as? String == "Previous launch crashed")
        let mechanism = try #require(entry["mechanism"] as? [String: Any])
        #expect(mechanism["handled"] as? Bool == false)
        #expect(mechanism["type"] as? String == "mach")
        // The crashed build and the reporting launch are identified separately.
        #expect(properties["crash_app_version"] as? String == "0.64.22")
        #expect(properties["crash_app_build"] as? String == "6422")
        #expect(properties["crash_app_namespace"] as? String == "com.cmuxterm.local")
        #expect(properties["app_version"] as? String == "0.64.23")
        #expect(properties["app_build"] as? String == "6423")
        #expect((properties["channel"] as? String)?.isEmpty == false)
    }

    @Test
    func crashExceptionPropertiesTolerateMissingReport() {
        let properties = PostHogAnalytics.crashExceptionProperties(
            reported: nil,
            infoDictionary: [:]
        )

        #expect(properties["$exception_level"] as? String == "error")
        #expect(properties["$exception_fingerprint"] as? String == "cmux-mac-crash:UnknownCrash")
        let entry = (properties["$exception_list"] as? [[String: Any]])?.first
        #expect(entry?["type"] as? String == "UnknownCrash")
        let mechanism = entry?["mechanism"] as? [String: Any]
        #expect(mechanism?["handled"] as? Bool == false)
        #expect(mechanism?["type"] as? String == "ghostty_crash_report")
        #expect(properties["crash_app_version"] == nil)
        #expect(properties["crash_app_build"] == nil)
        #expect(properties["crash_app_namespace"] == nil)
        #expect(properties["app_version"] == nil)
        #expect(properties["app_build"] == nil)
    }

    @Test
    func crashExceptionPropertiesSanitizeTokensAndScrubValues() {
        #expect(PostHogAnalytics.sanitizedExceptionToken("EXC_CRASH") == "EXC_CRASH")
        #expect(PostHogAnalytics.sanitizedExceptionToken("NSInternalInconsistencyException") == "NSInternalInconsistencyException")
        #expect(PostHogAnalytics.sanitizedExceptionToken("bad type /Users/dev") == nil)
        #expect(PostHogAnalytics.sanitizedExceptionToken("   ") == nil)
        #expect(PostHogAnalytics.sanitizedExceptionToken(nil) == nil)

    }

    @Test(arguments: [
        "Crash at /Users/Jane Doe/Private Project.swift",
        "Opening /tmp/Customer Contract.pdf failed",
        "password=hunter2 token=private-token alice@example.com",
        "Server returned confidential customer content",
    ])
    func crashExceptionDoesNotTransmitRawReason(reason: String) throws {
        let reported = GhosttyCrashReportMetadata.ReportedException(
            type: "EXC_CRASH",
            value: reason,
            mechanismType: "signal",
            appVersion: "0.64.22",
            appBuild: "6422",
            appNamespace: "com.cmuxterm.local"
        )
        let properties = PostHogAnalytics.crashExceptionProperties(reported: reported, infoDictionary: [:])
        let entry = try #require((properties["$exception_list"] as? [[String: Any]])?.first)
        #expect(entry["value"] as? String == "Previous launch crashed")
        let serialized = String(decoding: try JSONSerialization.data(withJSONObject: properties), as: UTF8.self)
        #expect(!serialized.contains(reason))
    }

    @Test
    func reportedExceptionReadsCrashAndAppContextFromEnvelope() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cmux-crash-exception-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let crashURL = directory.appendingPathComponent("sample.ghosttycrash")
        let event: [String: Any] = [
            "exception": [
                "values": [
                    [
                        "type": "EXC_BAD_ACCESS",
                        "value": "KERN_INVALID_ADDRESS at 0x0",
                        "mechanism": ["type": "mach"],
                    ],
                ],
            ],
            "contexts": [
                "app": [
                    "app_version": "0.64.22",
                    "app_build": "6422",
                    "app_identifier": "com.cmuxterm.local",
                ],
            ],
        ]
        let eventData = try JSONSerialization.data(withJSONObject: event)
        var envelope = Data(#"{"event_id":"00000000-0000-0000-0000-000000000000"}"#.utf8)
        envelope.append(0x0A)
        envelope.append(Data(#"{"type":"event","length":\#(eventData.count)}"#.utf8))
        envelope.append(0x0A)
        envelope.append(eventData)
        envelope.append(0x0A)
        try envelope.write(to: crashURL)

        let reported = try #require(GhosttyCrashReportMetadata.reportedException(in: crashURL))
        #expect(reported.type == "EXC_BAD_ACCESS")
        #expect(reported.value == "KERN_INVALID_ADDRESS at 0x0")
        #expect(reported.mechanismType == "mach")
        #expect(reported.appVersion == "0.64.22")
        #expect(reported.appBuild == "6422")
        #expect(reported.appNamespace == "com.cmuxterm.local")
    }

    @Test
    func reportedExceptionFallsBackWithoutExceptionPayload() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cmux-crash-exception-empty-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let crashURL = directory.appendingPathComponent("no-exception.ghosttycrash")
        let eventData = try JSONSerialization.data(withJSONObject: [
            "debug_meta": ["images": [["code_file": "/Applications/cmux.app/Contents/MacOS/cmux"]]],
        ])
        var envelope = Data(#"{"event_id":"00000000-0000-0000-0000-000000000000"}"#.utf8)
        envelope.append(0x0A)
        envelope.append(Data(#"{"type":"event","length":\#(eventData.count)}"#.utf8))
        envelope.append(0x0A)
        envelope.append(eventData)
        envelope.append(0x0A)
        try envelope.write(to: crashURL)

        #expect(GhosttyCrashReportMetadata.reportedException(in: crashURL)?.type == "UnknownCrash")
        #expect(GhosttyCrashReportMetadata.reportedException(
            in: directory.appendingPathComponent("missing.ghosttycrash")
        ) == nil)
    }
}

private actor FeatureFlagRemoteLoaderProbe {
    private(set) var callCount = 0
    func load() -> [String: Bool]? {
        callCount += 1
        return [:]
    }
}
#endif
