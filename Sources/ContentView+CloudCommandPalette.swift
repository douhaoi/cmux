import CmuxCloud
import CmuxCommandPalette
import AppKit
import Foundation

extension ContentView {
    static let commandPaletteCloudAvailabilityInfoCommandId = "palette.cloud.availabilityInfo"
    static let commandPaletteCloudForkCommandId = "palette.cloud.fork"
    static let commandPaletteCloudSnapshotCommandId = "palette.cloud.snapshot"
    static let commandPaletteCloudRestoreCommandId = "palette.cloud.restore"
    static let commandPaletteCloudPromoteTemplateCommandId = "palette.cloud.promoteTemplate"
    static let commandPaletteCloudStatusCommandId = "palette.cloud.status"
    static let commandPaletteCloudPortsCommandId = "palette.cloud.ports"
    static let commandPaletteCloudToolsCommandId = "palette.cloud.tools"
    static let commandPaletteCloudHandoffCommandId = "palette.cloud.handoff"
    static let commandPaletteCloudNewWorkspaceCommandId = "palette.cloud.newWorkspace"
    static let commandPaletteCloudNewMachineCommandId = "palette.cloud.newMachine"

    /// Returns Cloud VM commands when the Cloud feature and account are ready.
    static func commandPaletteCloudCommandContributions(
        isAuthenticated: Bool? = nil
    ) -> [CommandPaletteCommandContribution] {
        []
    }

    /// Builds the Cloud-context explanation for local-only palette actions.
    /// Keeping this as a normal command makes the availability explanation
    /// searchable and gives Cloud users a localized reason for omitted rows.
    static func commandPaletteCloudAvailabilityInfoContribution(
        locale: Locale = .current
    ) -> CommandPaletteCommandContribution {
        CommandPaletteCommandContribution(
            commandId: commandPaletteCloudAvailabilityInfoCommandId,
            title: { _ in
                String(
                    localized: "command.cloudVM.availabilityInfo.title",
                    defaultValue: "Show Cloud command availability",
                    locale: locale
                )
            },
            subtitle: { _ in
                String(
                    localized: "command.cloudVM.availabilityInfo.subtitle",
                    defaultValue: "Cloud workspace",
                    locale: locale
                )
            },
            keywords: String(
                localized: "command.cloudVM.availabilityInfo.keywords",
                defaultValue: "cloud, workspace, availability, local, unavailable, actions",
                locale: locale
            )
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            when: { $0.bool(CommandPaletteContextKeys.workspaceIsCloud) }
        )
    }

    /// Registers Cloud palette handlers with the shared command dispatcher.
    func registerCloudCommandHandlers(_ registry: inout CommandPaletteHandlerRegistry) {
        let commandWindow = observedWindow ?? NSApp.keyWindow ?? NSApp.mainWindow
        registry.register(commandId: Self.commandPaletteCloudAvailabilityInfoCommandId) {
            let alert = NSAlert()
            alert.messageText = String(
                localized: "command.cloudVM.availabilityInfo.alertTitle",
                defaultValue: "Some commands are local-only"
            )
            alert.informativeText = String(
                localized: "command.cloudVM.availabilityInfo.alertMessage",
                defaultValue: "Folder, simulator, local browser creation, directory search, and diff commands are available after selecting a local workspace. Cloud VM commands may be unavailable here."
            )
            alert.addButton(withTitle: String(localized: "common.ok", defaultValue: "OK"))
            if let commandWindow {
                alert.beginSheetModal(for: commandWindow, completionHandler: nil)
            } else {
                NSSound.beep()
            }
        }
        registry.register(commandId: Self.commandPaletteCloudNewMachineCommandId) {
            _ = AppDelegate.shared?.performNewCloudMachineAction(
                tabManager: tabManager,
                preferredWindow: commandWindow,
                debugSource: "palette.cloud.newMachine"
            )
        }
        registry.register(commandId: Self.commandPaletteCloudNewWorkspaceCommandId) {
            _ = AppDelegate.shared?.performNewCloudWorkspaceOnResolvedMachineAction(
                tabManager: tabManager,
                preferredWindow: commandWindow,
                debugSource: "palette.cloud.newWorkspace"
            )
        }
        registry.register(commandId: Self.commandPaletteCloudForkCommandId) {
            _ = AppDelegate.shared?.performCurrentCloudVMCommand(
                .fork,
                tabManager: tabManager,
                preferredWindow: commandWindow,
                debugSource: "palette.cloud.fork"
            )
        }
        registry.register(commandId: Self.commandPaletteCloudSnapshotCommandId) {
            _ = AppDelegate.shared?.performCurrentCloudVMCommand(
                .snapshot,
                tabManager: tabManager,
                preferredWindow: commandWindow,
                debugSource: "palette.cloud.snapshot"
            )
        }
        registry.register(commandId: Self.commandPaletteCloudRestoreCommandId) {
            _ = AppDelegate.shared?.performCloudVMRestoreCommand(
                tabManager: tabManager,
                preferredWindow: commandWindow,
                debugSource: "palette.cloud.restore"
            )
        }
        registry.register(commandId: Self.commandPaletteCloudPromoteTemplateCommandId) {
            _ = AppDelegate.shared?.performCurrentCloudVMCommand(
                .promoteTemplate,
                tabManager: tabManager,
                preferredWindow: commandWindow,
                debugSource: "palette.cloud.promoteTemplate"
            )
        }
        registry.register(commandId: Self.commandPaletteCloudStatusCommandId) {
            _ = AppDelegate.shared?.performCurrentCloudVMCommand(
                .status,
                tabManager: tabManager,
                preferredWindow: commandWindow,
                debugSource: "palette.cloud.status"
            )
        }
        registry.register(commandId: Self.commandPaletteCloudPortsCommandId) {
            _ = AppDelegate.shared?.performCurrentCloudVMCommand(
                .ports,
                tabManager: tabManager,
                preferredWindow: commandWindow,
                debugSource: "palette.cloud.ports"
            )
        }
        registry.register(commandId: Self.commandPaletteCloudToolsCommandId) {
            _ = AppDelegate.shared?.performCurrentCloudVMCommand(
                .tools,
                tabManager: tabManager,
                preferredWindow: commandWindow,
                debugSource: "palette.cloud.tools"
            )
        }
        registry.register(commandId: Self.commandPaletteCloudHandoffCommandId) {
            _ = AppDelegate.shared?.performCurrentCloudVMCommand(
                .handoff,
                tabManager: tabManager,
                preferredWindow: commandWindow,
                debugSource: "palette.cloud.handoff"
            )
        }
    }
}
