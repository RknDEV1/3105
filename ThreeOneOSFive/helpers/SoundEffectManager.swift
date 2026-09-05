import AudioToolbox
final class SoundEffectManager {
    static let shared = SoundEffectManager()
    static let enabledKey = "chz.priv.soundEffectsEnabled"

    enum Effect {
        case confirmation

        var systemSoundID: SystemSoundID { 1104 }
    }

    private init() {}

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    func play(_ effect: Effect = .confirmation) {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
}
