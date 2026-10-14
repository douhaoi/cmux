import CMUXMobileCore
import CMUXAuthCore
import CmuxIrohTransport
import CmuxAuthRuntime
import CmuxSettings
import Foundation
import Testing

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

struct MobileHostServiceSettingsTests {
    @Test("Mac discovery and hosting never enable the iOS pairing setting", arguments: [false, true], [false, true])
    func macPreferencesDoNotEnablePhonePairing(discovery: Bool, incoming: Bool) throws {
        let suiteName = "MobileHostServiceSettingsTests.mac-isolation.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: BetaFeaturesCatalogSection().cloudMachines.userDefaultsKey)
        defaults.set(discovery, forKey: DevicesCatalogSection().discoveryEnabled.userDefaultsKey)
        defaults.set(incoming, forKey: DevicesCatalogSection().incomingAccessEnabled.userDefaultsKey)
        #expect(!MobileHostService.isListeningEnabled(defaults: defaults, buildFlavor: .dev))
        defaults.set(true, forKey: MobileHostService.listeningEnabledDefaultsKey)
        #expect(!MobileHostService.isListeningEnabled(defaults: defaults, buildFlavor: .dev))
    }

    @Test(arguments: [BuildFlavor.dev, .nightly, .stable])
    func pairingRequiresExplicitOptInAndPreservesHistoricalChoice(buildFlavor: BuildFlavor) throws {
        let suiteName = "MobileHostServiceSettingsTests.v2.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        #expect(!MobileHostService.isListeningEnabled(defaults: defaults, buildFlavor: buildFlavor))
        defaults.set(true, forKey: "cmuxMobilePairingHostEnabled")
        #expect(!MobileHostService.isListeningEnabled(defaults: defaults, buildFlavor: buildFlavor))
        defaults.set(false, forKey: "cmuxMobilePairingHostEnabled")
        #expect(!MobileHostService.isListeningEnabled(defaults: defaults, buildFlavor: buildFlavor))
        defaults.set(true, forKey: MobileHostService.listeningEnabledDefaultsKey)
        #expect(!MobileHostService.isListeningEnabled(defaults: defaults, buildFlavor: buildFlavor))
        defaults.set(true, forKey: "cmuxMobilePairingHostEnabled")
        defaults.set(false, forKey: MobileHostService.listeningEnabledDefaultsKey)
        #expect(!MobileHostService.isListeningEnabled(defaults: defaults, buildFlavor: buildFlavor))
        #expect(SettingCatalog().mobile.iOSPairingHost.defaultValue == false)
    }

    @Test func configuredPortDefaultsToCatalogDefaultWhenUnset() throws {
        let suiteName = "MobileHostServiceSettingsTests.Port.Default.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let expected = SettingCatalog().mobile.iOSPairingPort.defaultValue
        #expect(MobileHostService.configuredPort(defaults: defaults) == expected)
    }

    @Test func configuredPortHonorsValidOverride() throws {
        let suiteName = "MobileHostServiceSettingsTests.Port.Valid.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(9000, forKey: MobileHostService.portDefaultsKey)
        #expect(MobileHostService.configuredPort(defaults: defaults) == 9000)
    }

    @Test(arguments: [0, -1, 70000, 65536])
    func configuredPortFallsBackForOutOfRangeOverride(invalidPort: Int) throws {
        let suiteName = "MobileHostServiceSettingsTests.Port.Invalid.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(invalidPort, forKey: MobileHostService.portDefaultsKey)
        let expected = SettingCatalog().mobile.iOSPairingPort.defaultValue
        #expect(MobileHostService.configuredPort(defaults: defaults) == expected)
    }

    @Test func settingsUseObservedLocalAddressesAndIgnoreLegacyRouteHints() throws {
        let status = MobileHostServiceStatus(
            isRunning: true, port: 58465, configuredPort: 60000,
            usesEphemeralFallback: false, routes: [try CmxAttachRoute(
                id: "retired-tcp", kind: .tailscale,
                endpoint: .hostPort(host: "100.64.0.1", port: 1234))],
            activeConnectionCount: 2, lastErrorDescription: nil,
            pendingPortChange: true,
            localSocketAddresses: ["192.168.1.2:58465", "[fd00::2]:58465", "192.168.1.2:58465"])
        let snapshot = HostSettingsActions.mobilePairingSnapshot(from: status)
        #expect(snapshot.routes.map(\.endpoint) == ["192.168.1.2:58465", "[fd00::2]:58465"])
        #expect(snapshot.boundPort == 58465)
        #expect(snapshot.configuredPort == 60000)
        #expect(snapshot.pendingPortChange)
    }

    @Test func splitSocketAddressParsesSocketLiteralsOnly() throws {
        let v4 = try #require(HostSettingsActions.splitSocketAddress("93.184.216.34:58465"))
        #expect(v4.host == "93.184.216.34")
        #expect(v4.port == 58_465)
        let v6 = try #require(HostSettingsActions.splitSocketAddress("[2606:4700::6810:1]:443"))
        #expect(v6.host == "2606:4700::6810:1")
        #expect(v6.port == 443)
        #expect(HostSettingsActions.splitSocketAddress("no-port")?.host == nil)
        #expect(HostSettingsActions.splitSocketAddress("2606:4700::6810:1:443")?.host == nil)
        #expect(HostSettingsActions.splitSocketAddress("[2606:4700::6810:1]443")?.host == nil)
        #expect(HostSettingsActions.splitSocketAddress("93.184.216.34:0")?.host == nil)
    }
}

#if DEBUG
@Suite(.serialized)
@MainActor
struct MobileHostMacScopedMutationAuthorizationTests {
    @Test func ignoresUnknownAttachTokenForBroadWorkspaceRequests() async {
        let service = MobileHostService.shared
        service.debugConfigureAcceptedStackAuthTokenForTesting("cmux-dev-token")
        defer { service.debugConfigureAcceptedStackAuthTokenForTesting(nil) }
        for method in ["workspace.list", "workspace.create"] {
            let request = MobileHostRPCRequest(
                id: method,
                method: method,
                params: [:],
                auth: MobileHostRPCAuth(attachToken: "stale-ticket", stackAccessToken: "cmux-dev-token")
            )
            let result = await service.debugAuthorizationError(for: request)
            #expect(result == nil)
        }
    }

}
#endif

@Suite(.serialized, .timeLimit(.minutes(1)))
@MainActor
struct MobileHostV2LifecycleTests {
    @Test(arguments: [BuildFlavor.dev, .nightly, .stable])
    func savedPhonePreferencesCannotStartALocalListener(flavor: BuildFlavor) async throws {
        let name = "MobileHostV2LifecycleTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(true, forKey: MobileHostService.listeningEnabledDefaultsKey)
        defaults.set(true, forKey: "cmuxMobilePairingHostEnabled")
        #expect(!MobileHostService.isListeningEnabled(defaults: defaults, buildFlavor: flavor))
        let service = MobileHostService(defaults: defaults)
        service.start()
        service.syncToSettings()
        let status = await service.ensureListeningAndReady()
        #expect(!status.isRunning)
        #expect(!status.isPairingReady)
        #expect(status.port == nil)
        #expect(status.routes.isEmpty)
        #expect(status.localSocketAddresses.isEmpty)
        #expect(status.activeConnectionCount == 0)
        #expect(await service.applyConfiguredPort(60001) == .savedForLater)
        #expect(await service.applyConfiguredPort(0) == .invalid)
        #expect(!service.statusSnapshot().isRunning)
    }
}
