import Foundation
import Observation

@MainActor
@Observable
final class OnTheGoStore {
    static let playlistID = "onTheGo"

    private(set) var items: [LibraryItem] = []

    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        let stored = defaults.array(forKey: UserDefaultsKeys.onTheGoItems.rawValue) as? [[String: String]] ?? []
        items = stored.compactMap { entry in
            guard let id = entry["id"], let title = entry["title"] else { return nil }
            return LibraryItem(id: id, title: title, subtitle: entry["subtitle"] ?? "")
        }
    }

    var playlistItem: LibraryItem {
        LibraryItem(
            id: Self.playlistID,
            title: String(localized: "On-The-Go"),
            subtitle: String(localized: "\(items.count) Songs")
        )
    }

    func add(_ item: LibraryItem) {
        items.append(LibraryItem(id: item.id, title: item.title, subtitle: item.subtitle))
        persist()
    }

    func clear() {
        items = []
        persist()
    }

    private func persist() {
        defaults.set(items.map { ["id": $0.id, "title": $0.title, "subtitle": $0.subtitle] }, forKey: UserDefaultsKeys.onTheGoItems.rawValue)
    }
}

@MainActor
@Observable
final class RatingStore {
    static let maxRating = 5

    private(set) var ratings: [String: Int]

    init() {
        ratings = UserDefaults.standard.dictionary(forKey: UserDefaultsKeys.trackRatings.rawValue) as? [String: Int] ?? [:]
    }

    func rating(for trackID: String?) -> Int {
        guard let trackID else { return 0 }
        return ratings[trackID] ?? 0
    }

    func setRating(_ rating: Int, for trackID: String) {
        ratings[trackID] = min(max(rating, 0), Self.maxRating)
        UserDefaults.standard.set(ratings, forKey: UserDefaultsKeys.trackRatings.rawValue)
    }
}
