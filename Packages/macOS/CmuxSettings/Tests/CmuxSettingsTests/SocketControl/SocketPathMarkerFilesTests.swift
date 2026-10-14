import Testing
@testable import CmuxSettings

@Test func markerFilesAreVariantAware() {
    #expect(SocketPathMarkerFiles.variant(
        bundleIdentifier: "com.cmuxterm.local",
        environment: [:]
    ) == .stable)
    #expect(SocketPathMarkerFiles.variant(
        bundleIdentifier: "com.cmuxterm.local.nightly",
        environment: [:]
    ) == .nightly(slug: nil))
    #expect(SocketPathMarkerFiles.variant(
        bundleIdentifier: "com.cmuxterm.local.rc",
        environment: [:]
    ) == .rc(slug: nil))
    #expect(SocketPathMarkerFiles.variant(
        bundleIdentifier: "com.cmuxterm.local.rc.my-feature",
        environment: [:]
    ) == .rc(slug: "my-feature"))
    #expect(SocketPathMarkerFiles.variant(
        bundleIdentifier: "com.cmuxterm.local.debug.agent",
        environment: [:]
    ) == .dev(slug: "agent"))
    #expect(SocketPathMarkerFiles.variant(
        bundleIdentifier: "com.cmuxterm.local.debug",
        environment: ["CMUX_TAG": "Issue 3542"]
    ) == .dev(slug: "issue-3542"))
    #expect(SocketPathMarkerFiles.variant(
        bundleIdentifier: "com.cmuxterm.local.debug",
        environment: ["CMUX_TAG": "café"]
    ) == .dev(slug: "caf"))
}

@Test func defaultSocketPathsStayVariantScoped() {
    #expect(SocketPathMarkerFiles.defaultSocketPath(
        bundleIdentifier: "com.cmuxterm.local",
        environment: [:],
        isDebugBuild: false,
        stableSocketPath: "/stable/cmux.sock"
    ) == "/stable/cmux.sock")
    #expect(SocketPathMarkerFiles.defaultSocketPath(
        bundleIdentifier: "com.cmuxterm.local.nightly",
        environment: [:],
        isDebugBuild: false,
        stableSocketPath: "/stable/cmux.sock"
    ) == "/tmp/cmux-local-nightly.sock")
    #expect(SocketPathMarkerFiles.defaultSocketPath(
        bundleIdentifier: "com.cmuxterm.local.rc",
        environment: [:],
        isDebugBuild: false,
        stableSocketPath: "/stable/cmux.sock"
    ) == "/tmp/cmux-local-rc.sock")
    #expect(SocketPathMarkerFiles.defaultSocketPath(
        bundleIdentifier: "com.cmuxterm.local.rc.candidate1",
        environment: [:],
        isDebugBuild: false,
        stableSocketPath: "/stable/cmux.sock"
    ) == "/tmp/cmux-local-rc-candidate1.sock")
    #expect(SocketPathMarkerFiles.defaultSocketPath(
        bundleIdentifier: "com.cmuxterm.local.staging.my-feature",
        environment: [:],
        isDebugBuild: false,
        stableSocketPath: "/stable/cmux.sock"
    ) == "/tmp/cmux-local-staging-my-feature.sock")
    #expect(SocketPathMarkerFiles.defaultSocketPath(
        bundleIdentifier: "com.cmuxterm.local.debug",
        environment: ["CMUX_TAG": "Issue 3542"],
        isDebugBuild: false,
        stableSocketPath: "/stable/cmux.sock"
    ) == "/tmp/cmux-local-debug-issue-3542.sock")
}
