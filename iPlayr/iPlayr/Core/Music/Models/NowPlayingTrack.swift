import Foundation

struct NowPlayingTrack: Equatable, Sendable {
    let id: String
    let title: String
    let artistName: String
    let albumTitle: String?
    let duration: TimeInterval?
    let artwork: ArtworkRef?
}
