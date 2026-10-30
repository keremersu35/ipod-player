import SwiftUI

struct VolumeLimitView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "volumeLimit")
    @State private var limit: Float = SystemVolume.limit

    private static let step: Float = 0.0625

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Volume Limit"))
            Spacer()
            VStack(spacing: 10) {
                VolumeBarView(level: limit)
                Text(limit >= 1 ? String(localized: "No Limit") : String(localized: "Max \(limit.formatted(.percent.precision(.fractionLength(0))))"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 8)
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
    }

    private func setup() {
        scope.onScroll = { delta in
            let target = min(max(limit + Float(delta) * Self.step, Self.step), 1)
            guard target != limit else { return false }
            limit = target
            UserDefaults.standard.set(target, forKey: UserDefaultsKeys.volumeLimit.rawValue)
            if SystemVolume.level > target {
                _ = SystemVolume.adjust(by: target - SystemVolume.level)
            }
            return true
        }
        scope.onAction = { action in
            if action == .menu || action == .select { navigate(.pop) }
        }
        iPlayrController.activate(scope)
    }
}
