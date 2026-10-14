import CMUXMobileCore
import CmuxIrohTransport
import CmuxIrxTransport
import CmuxSurfaceCatalogModel
import Foundation

/// Compatibility owner for retired device routes. It cannot create an endpoint.
actor DeviceIrxClient {
    /// Returns whether a waiting session has an authoritative local revocation.
    nonisolated static func shouldReleaseWaitingSession(cache: V2CachedState?, releaseAll: Bool = false) -> Bool {
        guard !releaseAll, let cache else { return releaseAll }
        return cache.authorityRevoked || cache.device?.revoked == true
    }

    /// Returns whether an authoritative verified-session failure retires its endpoint slot.
    nonisolated static func shouldReleaseVerifiedSession(after failure: IrxMacPeerAuthorization.Failure) -> Bool {
        switch failure {
        case .staleDirectory:
            return false
        case .unavailable, .revoked, .notDiscoverable, .identityMismatch:
            return true
        }
    }


    func discoverMacs() async throws -> [DeviceDiscoveredMac] { [] }
    func directoryStamp() async -> DeviceDirectoryStamp? { nil }
    func directoryChanges() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
    func transport(
        for request: CmxByteTransportRequest,
        instance: SurfaceDeviceInstanceID
    ) async throws -> any CmxByteTransport {
        throw DeviceLinkError.notConnected
    }
    func events(
        for request: CmxByteTransportRequest,
        instance: SurfaceDeviceInstanceID
    ) async throws -> CmxIndependentEventByteStream {
        throw DeviceLinkError.notConnected
    }
    func stop() async {}
    func enforce(_ cache: V2CachedState?, releaseAll: Bool = false) async {}
    func enforceAccount(_ account: AccountMacDirectorySnapshot?) async {}
}
