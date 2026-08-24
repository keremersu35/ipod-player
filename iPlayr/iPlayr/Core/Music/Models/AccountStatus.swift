import Foundation

enum AccountStatus: Hashable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case needsReauth

    var isAuthorized: Bool { self == .authorized }
}
