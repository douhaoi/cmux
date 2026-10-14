public import CMUXAuthCore

/// An account client for distributions without an authentication backend.
///
/// It never reads credentials or contacts a server. Sign-in and account
/// mutations fail closed; read operations expose no authenticated identity.
public struct UnavailableAuthClient: AuthClient {
    /// Creates the credential-free client.
    public init() {}

    /// Returns no access token.
    public func accessToken() async -> String? { nil }
    /// Returns no access token, regardless of refresh preference.
    public func resolvedAccessToken(forceRefresh: Bool) async throws -> String? { nil }
    /// Returns no refresh token.
    public func refreshToken() async -> String? { nil }
    /// Returns no refreshed token.
    public func forceRefreshAccessToken() async -> String? { nil }
    /// Returns no user, or fails when an authenticated user is required.
    public func currentUser(throwOnMissing: Bool) async throws -> CMUXAuthUser? {
        if throwOnMissing { throw AuthClientError.unsupported }
        return nil
    }
    /// Returns no team memberships.
    public func listTeams() async throws -> [CMUXAuthTeam] { [] }
    /// Fails because sign-in is unavailable.
    public func sendMagicLinkEmail(email: String, callbackURL: String) async throws -> String {
        throw AuthClientError.unsupported
    }
    /// Fails because sign-in is unavailable.
    public func signInWithMagicLink(code: String) async throws { throw AuthClientError.unsupported }
    /// Fails because sign-in is unavailable.
    public func signInWithCredential(email: String, password: String) async throws { throw AuthClientError.unsupported }
    /// Fails because sign-in is unavailable.
    public func signInWithOAuth(provider: String, anchor: any AuthPresentationAnchoring) async throws {
        throw AuthClientError.unsupported
    }
    /// Returns no stored token.
    public func storedAccessToken() async -> String? { nil }
    /// Has no stored session to clear.
    public func clearLocalSession() async {}
    /// Has no stored session to clear.
    public func clearLocalSession(ifRefreshTokenMatches refreshToken: String) async {}
    /// Fails without contacting any session-revocation endpoint.
    public func revokeSession(accessToken: String?, refreshToken: String?) async throws {
        throw AuthClientError.unsupported
    }
    /// Returns no token and never refreshes the provided credentials.
    public func freshAccessToken(accessToken: String?, refreshToken: String) async -> String? { nil }
}
