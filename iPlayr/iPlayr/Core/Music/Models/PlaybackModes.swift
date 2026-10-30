import Foundation

enum ShuffleMode: Hashable, Sendable, CaseIterable {
    case off
    case songs
    case albums

    var title: String {
        switch self {
        case .off: return String(localized: "Off")
        case .songs: return String(localized: "Songs")
        case .albums: return String(localized: "Albums")
        }
    }

    var next: ShuffleMode {
        let all = Self.allCases
        return all[((all.firstIndex(of: self) ?? 0) + 1) % all.count]
    }
}

enum RepeatMode: Hashable, Sendable {
    case off
    case one
    case all
}
