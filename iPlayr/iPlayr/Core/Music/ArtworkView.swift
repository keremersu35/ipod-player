import SwiftUI
import MusicKit

struct ArtworkView: View {
    let artwork: ArtworkRef?
    let width: CGFloat
    var height: CGFloat?

    private var resolvedHeight: CGFloat { height ?? width }

    var body: some View {
        switch artwork {
        case .appleMusic(let artwork):
            ArtworkImage(artwork, width: width, height: resolvedHeight)
        case .remote(let url):
            AsyncImage(url: url) { image in
                image.resizable()
            } placeholder: {
                placeholder
            }
            .frame(width: width, height: resolvedHeight)
        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: resolvedHeight)
        case nil:
            placeholder
                .frame(width: width, height: resolvedHeight)
        }
    }

    private var placeholder: some View {
        Image(ImageNames.Custom.coverPlaceholder)
            .resizable()
            .scaledToFit()
    }
}
