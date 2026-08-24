import Foundation
import MusicKit

enum ArtworkRef: Hashable, Sendable {
    case appleMusic(Artwork)
    case remote(URL)
}
