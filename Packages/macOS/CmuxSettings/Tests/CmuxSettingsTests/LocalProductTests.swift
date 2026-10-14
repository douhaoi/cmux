import Foundation
import Testing
@testable import CmuxSettings

struct LocalProductTests {
    @Test(arguments: ["remotes.list", "remotes.add", "vpn.up", "phone_push.test", "phone_push.settings.update", "phone_push.status.get", "auth.status", "auth.team.create", "vm.billing_checkout", "vm.list", "mobile.host.status", "devices.list", "coderouter.account.upload", "ai_accounts.list", "feedback.submit", "dogfood.feedback.submit", "workspace.cloud_vm_open", "debug.mobile.transport.disconnect", "debug.cloudtree.rows", "debug.pro.welcome", "debug.pricing.show", "debug.native_pricing.show"])
    func removedAPIsAreUnavailable(method: String) {
        #expect(!LocalProduct().includesSocketMethod(method))
    }

    @Test(arguments: ["auth.login", "workspace.create", "surface.send_text", "notification.create", "browser.navigate", "settings.open", "ssh.connect"])
    func localAutomationRemainsAvailable(method: String) {
        #expect(LocalProduct().includesSocketMethod(method))
    }

    @Test(arguments: ["account", "mobile", "cloudMachines", "computers", "networking"])
    func removedSettingsAreUnavailable(section: String) {
        #expect(!LocalProduct().includesSettingsSection(section))
    }

    @Test func localServicesRemainAvailable() {
        #expect(LocalProduct().includesSettingsSection("terminal"))
        #expect(LocalProduct().includesSettingsSection("browser"))
        #expect(!LocalProduct().includesHostedServices)
        #expect(!LocalProduct().includesBackgroundServices)
    }
    @Test func localInstallationUsesIndependentStorageAndDiscovery() {
        let home = URL(fileURLWithPath: "/Users/test-user", isDirectory: true)
        #expect(CmuxConfigLocation(home: home).userConfigFile.path == "/Users/test-user/.config/cmux-local/cmux.json")
        #expect(CmuxStateDirectory.url(homeDirectory: home).path == "/Users/test-user/.local/state/cmux-local")
        #expect(SocketPathMarkerFiles.stableBundleIdentifier == "com.cmuxterm.local")
        #expect(SocketPathMarkerFiles.stableTmpPath == "/tmp/cmux-local-last-socket-path")
        #expect(SocketPathMarkerFiles.defaultSocketPath(
            bundleIdentifier: "com.cmuxterm.local.debug.local-audit", environment: [:],
            isDebugBuild: true, stableSocketPath: "/stable/cmux-local.sock"
        ) == "/tmp/cmux-local-debug-local-audit.sock")
    }

}
