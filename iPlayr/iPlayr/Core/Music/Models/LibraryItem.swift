import Foundation

struct LibraryItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let artwork: ArtworkRef?

    init(id: String, title: String, subtitle: String = "", artwork: ArtworkRef? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.artwork = artwork
    }
}
