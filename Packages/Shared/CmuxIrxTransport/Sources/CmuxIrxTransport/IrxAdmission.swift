public import Foundation

/// Admission outcome carried into the host: the peer tuple the grant proved,
/// bound to the TLS-authenticated key by the verifier closure.
public struct IrxAdmittedPeerInfo: Equatable, Sendable {
    public var bindingID: String
    public var deviceID: String
    public var tag: String
    public var endpointIDHex: String
    public var identityGeneration: Int

    public init(
        bindingID: String,
        deviceID: String,
        tag: String,
        endpointIDHex: String,
        identityGeneration: Int
    ) {
        self.bindingID = bindingID
        self.deviceID = deviceID
        self.tag = tag
        self.endpointIDHex = endpointIDHex
        self.identityGeneration = identityGeneration
    }
}

public struct IrxAdmissionDenied: Error, Equatable, Sendable {
    public var code: IrxCloseCode

    public init(code: IrxCloseCode) {
        self.code = code
    }
}

/// Admission judgment seam: given the (optional) presented grant JWS and the
/// TLS-proved remote key, either return the admitted peer tuple or throw
/// ``IrxAdmissionDenied``. The list judge ignores the grant entirely; the
/// legacy grant judge requires one. Deliberately OFFLINE (no backend call
/// sits on the admission path - revocations enforce via the pushed device
/// list, or at the next admission).
public typealias IrxGrantJudgment =
    @Sendable (_ grantJWS: String?, _ remoteEndpointIDHex: String) throws -> IrxAdmittedPeerInfo
