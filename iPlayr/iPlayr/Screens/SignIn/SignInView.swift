import SwiftUI

struct SignInView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(MusicAccountManager.self) private var authManager
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "login")
    @State private var isShowingModal = false

    private var providers: [MusicProviderID] { authManager.availableProviders }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Sign In"))
            ForEach(providers.indices, id: \.self) { index in
                MenuItemView(menu: menu(at: index), isSelected: scope.selection == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .alert(String(localized: "Permission Required"), isPresented: $isShowingModal) {
            Button("Go to Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This app requires access to Apple Music. Please enable it in Settings.")
        }
    }

    private func menu(at index: Int) -> Menu {
        let provider = providers[index]
        let isSignedIn = authManager.status(of: provider).isAuthorized
        return Menu(name: provider.title, next: !isSignedIn, value: isSignedIn ? "\u{2713}" : nil)
    }

    private func setup() {
        scope.configure(itemCount: providers.count)
        scope.onAction = { action in
            switch action {
            case .menu:
                navigate(.pop)
            case .select:
                Task { await handleSignIn() }
            default:
                break
            }
        }
        iPlayrController.activate(scope)
    }

    private func handleSignIn() async {
        guard providers.indices.contains(scope.selection) else { return }
        let provider = providers[scope.selection]

        if authManager.status(of: provider) == .denied {
            isShowingModal = true
            return
        }

        if await authManager.signIn(provider) {
            navigate(.pop)
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
