import Foundation
import UIKit
import Combine
import Observation

@MainActor
@Observable
final class MusicAccountManager {
    private(set) var activeProviderID: MusicProviderID
    private(set) var status: AccountStatus = .notDetermined

    var isAuthorized: Bool { status.isAuthorized }
    var capabilities: ProviderCapabilities { activeProvider.capabilities }
    var availableProviders: [MusicProviderID] { Array(providers.keys).sorted { $0.rawValue < $1.rawValue } }

    @ObservationIgnored var onActiveProviderChange: ((MusicProviderID) -> Void)?
    @ObservationIgnored private let providers: [MusicProviderID: any AccountProvider]
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    private var activeProvider: any AccountProvider {
        providers[activeProviderID] ?? providers.values.first!
    }

    init(providers: [MusicProviderID: any AccountProvider]) {
        self.providers = providers
        let stored = UserDefaults.standard.string(forKey: UserDefaultsKeys.activeMusicProvider.rawValue)
        self.activeProviderID = stored.flatMap(MusicProviderID.init(rawValue:)) ?? .appleMusic
        status = activeProvider.status
        observeAppLifecycle()
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        await activeProvider.refreshStatus()
        status = activeProvider.status
    }

    func signIn(_ id: MusicProviderID) async -> Bool {
        guard let provider = providers[id] else { return false }
        let granted = await provider.signIn()
        if granted { setActiveProvider(id) }
        status = activeProvider.status
        return granted
    }

    func signOut() {
        activeProvider.signOut()
        status = activeProvider.status
    }

    func status(of id: MusicProviderID) -> AccountStatus {
        providers[id]?.status ?? .notDetermined
    }

    func setActiveProvider(_ id: MusicProviderID) {
        guard providers[id] != nil, id != activeProviderID else { return }
        activeProviderID = id
        UserDefaults.standard.set(id.rawValue, forKey: UserDefaultsKeys.activeMusicProvider.rawValue)
        status = activeProvider.status
        onActiveProviderChange?(id)
    }

    private func observeAppLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in await self?.refreshStatus() }
            }
            .store(in: &cancellables)
    }
}
