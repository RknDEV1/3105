import AudioToolbox
import UIKit

final class SoundEffectManager {
    static let shared = SoundEffectManager()
    static let enabledKey = "chz.priv.soundEffectsEnabled"

    enum Effect {
        case tap
        case tab
        case patchStart
        case success
        case failure

        var systemSoundID: SystemSoundID {
            switch self {
            case .tap: return 1104
            case .tab: return 1103
            case .patchStart: return 1113
            case .success: return 1025
            case .failure: return 1073
            }
        }

        var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle? {
            switch self {
            case .tap, .tab: return .light
            case .patchStart: return .medium
            case .success, .failure: return nil
            }
        }
    }

    private init() {}

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    func play(_ effect: Effect) {
        guard isEnabled else { return }
        if let style = effect.feedbackStyle {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
}
