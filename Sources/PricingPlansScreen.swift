import AppKit
import CmuxCloud
import Foundation

/// Compatibility entrypoints for retired subscription surfaces.
/// No entrypoint opens a window, provisions an account, or makes a request.
enum ProUpgradePresenter {
    @MainActor static func present(source: ProUpgradeSource) {}
    @MainActor static func prefetch(source: ProUpgradeSource) {}
    @MainActor static func presentAppPricingWeb(source: ProUpgradeSource) {}
    @MainActor static func presentNativePricingPreview() {}
    @MainActor static func presentCheckout(source: ProUpgradeSource, plan: CheckoutPlan = .pro) {}
    @MainActor static func presentBillingPortal() {}
    @MainActor static func presentBrowserSplit(url: URL, transparentBackground: Bool) {}

    nonisolated static func checkoutURL(
        source: ProUpgradeSource,
        plan: CheckoutPlan = .pro,
        base: URL = AuthEnvironment.billingCheckoutURL
    ) -> URL {
        CheckoutAttribution.checkoutURL(source: source, plan: plan, base: base)
    }

    @MainActor static func appPricingURLForCurrentAppearance(source: ProUpgradeSource) -> URL {
        CheckoutAttribution.applying(to: decoratedAppWebURL(AuthEnvironment.appPricingURL), source: source)
    }
}

struct ProUpgradeWorkspaceReuseState {
    private(set) var workspaceId: UUID?

    mutating func recordCreatedWorkspace(id: UUID) {
        workspaceId = id
    }

    mutating func reusableWorkspaceID(exists: (UUID) -> Bool) -> UUID? {
        guard let workspaceId else { return nil }
        guard exists(workspaceId) else {
            self.workspaceId = nil
            return nil
        }
        return workspaceId
    }

    mutating func clear() {
        workspaceId = nil
    }
}
