import AVFoundation
import MediaPlayer
import UIKit

@MainActor
enum SystemVolume {
    private static let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))

    private static var slider: UISlider? {
        if volumeView.superview == nil {
            let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            scene?.windows.first?.addSubview(volumeView)
        }
        return volumeView.subviews.compactMap { $0 as? UISlider }.first
    }

    static var limit: Float {
        UserDefaults.standard.object(forKey: UserDefaultsKeys.volumeLimit.rawValue) as? Float ?? 1
    }

    static var level: Float {
        AVAudioSession.sharedInstance().outputVolume
    }

    static func adjust(by delta: Float) -> Float? {
        guard let slider else { return nil }
        let target = min(max(slider.value + delta, 0), limit)
        guard target != slider.value else { return nil }
        slider.value = target
        slider.sendActions(for: .valueChanged)
        return target
    }
}
