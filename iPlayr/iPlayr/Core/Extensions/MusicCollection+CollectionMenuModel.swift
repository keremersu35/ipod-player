import MusicKit

extension Playlist {
    func toCollectionMenuModel() -> CollectionMenuModel {
        CollectionMenuModel(artwork: artwork.map(ArtworkRef.appleMusic), name: name, description: "")
    }
}

extension Album {
    func toCollectionMenuModel() -> CollectionMenuModel {
        CollectionMenuModel(artwork: artwork.map(ArtworkRef.appleMusic), name: title, description: artistName)
    }
}

extension Track {
    func toCollectionMenuModel() -> CollectionMenuModel {
        CollectionMenuModel(artwork: artwork.map(ArtworkRef.appleMusic), name: title, description: artistName)
    }
}

extension Song {
    func toCollectionMenuModel() -> CollectionMenuModel {
        CollectionMenuModel(artwork: artwork.map(ArtworkRef.appleMusic), name: title, description: artistName)
    }
}
