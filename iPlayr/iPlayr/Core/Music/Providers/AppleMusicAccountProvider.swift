import Foundation
import MusicKit

@MainActor
@Observable
final class AppleMusicAccountProvider: AccountProvider {
    nonisolated var id: MusicProviderID { .appleMusic }
    nonisolated var capabilities: ProviderCapabilities { [.genres, .composers, .scrubbing, .repeatOne] }

    private(set) var status: AccountStatus = .notDetermined

    init() {
        status = Self.map(MusicAuthorization.currentStatus)
    }

    func refreshStatus() async {
        status = Self.map(MusicAuthorization.currentStatus)
    }

    func signIn() async -> Bool {
        status = Self.map(await MusicAuthorization.request())
        return status.isAuthorized
    }

    func signOut() {
        status = Self.map(MusicAuthorization.currentStatus)
    }

    private static func map(_ status: MusicAuthorization.Status) -> AccountStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        default: return .notDetermined
        }
    }
}
