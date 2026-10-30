import SwiftUI
import UIKit

struct AboutView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(MusicAccountManager.self) private var authManager
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "about")
    @State private var page = 0

    private static let pageCount = 3

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(title: String(localized: "iPlayr"))
            ZStack {
                LinearGradient(colors: [.aboutBackgroundTop, .aboutBackgroundBottom], startPoint: .top, endPoint: .bottom)
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    pageContent
                    Spacer(minLength: 0)
                    pageIndicator
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
            }
        }
        .onAppear(perform: setup)
        .taskAfterNavigation {
            await libraryStore.loadSongsIfNeeded()
            await libraryStore.loadAlbumsIfNeeded()
            await libraryStore.loadArtistsIfNeeded()
            await libraryStore.loadPlaylistsIfNeeded()
            await libraryStore.loadGenresIfNeeded()
            await libraryStore.loadComposersIfNeeded()
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case 0: capacityPage
        case 1: countsPage
        default: devicePage
        }
    }

    private var capacityPage: some View {
        let storage = DeviceStorage.current
        return VStack(spacing: 18) {
            HStack(alignment: .center) {
                Text(storage.usedDescription)
                    .frame(maxWidth: .infinity)
                Image(systemName: authManager.activeProviderID == .appleMusic ? "applelogo" : ImageNames.System.musicNote)
                    .font(.system(size: 54))
                Text(storage.freeDescription)
                    .frame(maxWidth: .infinity)
            }
            .font(.system(size: 14, weight: .bold))
            CapacityBar(usedFraction: storage.usedFraction)
                .frame(height: 12)
                .padding(.horizontal, 24)
        }
        .padding(.horizontal, 8)
    }

    private var countsPage: some View {
        HStack(alignment: .top, spacing: 24) {
            countColumn([
                (String(localized: "Songs"), libraryStore.songs?.count),
                (String(localized: "Albums"), libraryStore.albums?.count),
                (String(localized: "Artists"), libraryStore.artists?.count),
            ])
            countColumn([
                (String(localized: "Playlists"), libraryStore.playlists?.count),
                (String(localized: "Genres"), libraryStore.genres?.count),
                (String(localized: "Composers"), libraryStore.composers?.count),
            ])
        }
        .padding(.horizontal, 20)
    }

    private func countColumn(_ rows: [(String, Int?)]) -> some View {
        VStack(spacing: 6) {
            ForEach(rows.indices, id: \.self) { index in
                HStack {
                    Text(rows[index].0)
                    Spacer()
                    Text(rows[index].1.map(String.init) ?? "—")
                }
            }
        }
        .font(.system(size: 14, weight: .bold))
        .frame(maxWidth: .infinity)
    }

    private var devicePage: some View {
        VStack(spacing: 6) {
            infoRow(String(localized: "Model"), UIDevice.current.model)
            infoRow(String(localized: "Version"), appVersion)
            infoRow(String(localized: "Service"), authManager.activeProviderID.title)
        }
        .font(.system(size: 14, weight: .bold))
        .padding(.horizontal, 32)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<Self.pageCount, id: \.self) { index in
                Circle()
                    .fill(index == page ? Color.white : Color.white.opacity(0.4))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.bottom, 12)
    }

    private func setup() {
        scope.configure(itemCount: 0)
        scope.onAction = { action in
            switch action {
            case .menu:
                navigate(.pop)
            case .select:
                page = (page + 1) % Self.pageCount
            default:
                break
            }
        }
        iPlayrController.activate(scope)
    }
}
