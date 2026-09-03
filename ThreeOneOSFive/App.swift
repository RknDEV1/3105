import SwiftUI
import UIKit

@main
struct ThreeOneOSFiveApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var patchDraftCoordinator = PatchDraftCoordinator()
    @StateObject private var fileOperationCoordinator = FileOperationCoordinator()
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    // A interface CHZ PRIV abre após a seleção do jogo.
    @State private var showOnboarding = false
    @State private var showGamePicker = true
    @State private var selectedEdition: GameEdition = .freeFire
    @State private var showAttribution = false
    @State private var updateOffer: AppUpdateChecker.Offer?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        setupLogCapture()
        log("app: 3105 launching — iOS \(AppInfo.osVersion) (\(AppInfo.osBuild)) \(AppInfo.machineName)")
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    private func checkForUpdate() {
        Task {
            guard let offer = await AppUpdateChecker.check() else { return }
            await MainActor.run { updateOffer = offer }
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                                    ContentView(
                        isFreeFireMax: selectedEdition == .freeFireMax,
                        onExitToGamePicker: {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                                showGamePicker = true
                            }
                        }
                    )

                    .environmentObject(appState)
                    .environmentObject(patchDraftCoordinator)
                    .environmentObject(fileOperationCoordinator)
                    .environment(\.appLanguage, language)
                    .environment(\.locale, language.locale)
                    .opacity(showOnboarding || showGamePicker ? 0 : 1)
                    .allowsHitTesting(!showOnboarding && !showGamePicker)

                if showGamePicker && !showOnboarding {
                    FreeFireSelectionView { edition in
                        selectedEdition = edition
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                            showGamePicker = false
                        }
                    }
                    .environment(\.appLanguage, language)
                    .environment(\.locale, language.locale)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(1)
                }

                if showOnboarding {
                    OnboardingView {
                        OnboardingStore.markCompleted()
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                            showOnboarding = false
                        }
                        appState.detectSupport()
                        checkForUpdate()
                    }
                    .environment(\.appLanguage, language)
                    .environment(\.locale, language.locale)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(1)
                }
            }
            .displayIdentityAttribution(isPresented: $showAttribution, enabled: !showOnboarding && !showGamePicker)
            .sheet(isPresented: $showAttribution) {
                DisplayAttributionSheet()
            }
            .alert(item: $updateOffer) { offer in
                Alert(
                    title: Text(language.text("update.title")),
                    message: Text(language.text("update.message", offer.version)),
                    primaryButton: .default(Text(language.text("update.agree"))) {
                        UIApplication.shared.open(offer.url)
                    },
                    secondaryButton: .cancel(Text(language.text("update.dismiss"))) {
                        AppUpdateChecker.dismiss(version: offer.version)
                    }
                )
            }
            .onAppear {
                if !showOnboarding {
                    appState.detectSupport()
                    checkForUpdate()
                }
            }
            .onChange(of: scenePhase) { phase in
                guard phase == .active, !showOnboarding else { return }
                appState.detectSupport()
            }
            .onOpenURL { url in
                patchDraftCoordinator.presentImport(url)
            }
        }
    }
}

private enum GameEdition {
    case freeFire
    case freeFireMax
}

private struct FreeFireSelectionView: View {
    let onContinue: (GameEdition) -> Void

    private var artworkSide: CGFloat {
        min(108, max(88, UIScreen.main.bounds.width * 0.24))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Circle()
                .fill(Color.red.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 120, y: -230)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    Spacer(minLength: 22)

                VStack(spacing: 5) {
                    Text("CHZ")
                        .font(.custom("Burbank Big Condensed", size: 31))
                        .italic()
                        .foregroundStyle(AppTheme.accent)
                        .shadow(color: AppTheme.accent.opacity(0.72), radius: 0.7)
                    Text("PRIV")
                        .font(.custom("Burbank Big Condensed", size: 29))
                        .italic()
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.45), radius: 0.7)
                }

                Button(action: { onContinue(.freeFire) }) {
                    VStack(spacing: 12) {
                        Image("FreeFire")
                            .resizable()
                            .scaledToFit()
                            .frame(width: artworkSide, height: artworkSide)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            }
                            .shadow(color: AppTheme.accent.opacity(0.30), radius: 16, y: 7)

                        Text("Free Fire")
                            .font(.custom("Burbank Big Condensed", size: 24))
                            .italic()
                            .foregroundStyle(.white)
                            .shadow(color: .white.opacity(0.35), radius: 0.6)

                        Text("Toque para continuar")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.62))
                    }
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial.opacity(0.82), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Free Fire, tocar para acessar")

                Button(action: { onContinue(.freeFireMax) }) {
                    VStack(spacing: 12) {
                        Image("FreeFireMax")
                            .resizable()
                            .scaledToFit()
                            .frame(width: artworkSide, height: artworkSide)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            }
                            .opacity(0.72)

                        Text("Free Fire Max")
                            .font(.custom("Burbank Big Condensed", size: 23))
                            .italic()
                            .foregroundStyle(.white)
                            .shadow(color: .white.opacity(0.30), radius: 0.6)

                        Text("Suporte em breve…")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.58))
                    }
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial.opacity(0.64), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Free Fire Max, tocar para acessar")

                    Spacer(minLength: 22)
                }
                .padding(.horizontal, 22)
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var exploitStatus: ExploitStatus = .notStarted
    @Published var unsupportedMessage: String?
    @Published var kernelExploitRunning = false

    private var autoRunAttempted = false

    var kernelExploitApplicable: Bool {
        KernelExploit.isApplicable(
            major: AppInfo.versionTuple.major,
            minor: AppInfo.versionTuple.minor,
            patch: AppInfo.versionTuple.patch,
            build: AppInfo.osBuild
        )
    }

    var isSupported: Bool { unsupportedMessage == nil }

    func detectSupport() {
        let v = AppInfo.versionTuple
        let supported = ExploitSupportPolicy.isSupported(
            major: v.major,
            minor: v.minor,
            patch: v.patch,
            build: AppInfo.osBuild
        )
#if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--simulate-access") {
            exploitStatus = .success(method: "Simulator preview")
        }
#endif

        unsupportedMessage = supported ? nil : "iOS \(AppInfo.osVersion) (\(AppInfo.osBuild))"
        if let unsupportedMessage {
            exploitStatus = .unsupported(unsupportedMessage)
            return
        }

        let applicable = KernelExploit.isApplicable(
            major: v.major,
            minor: v.minor,
            patch: v.patch,
            build: AppInfo.osBuild
        )
        guard applicable else { return }

        refreshKernelExploitStatus()
        maybeAutoRunKernelExploit()
    }

    private func maybeAutoRunKernelExploit() {
        guard !kernelExploitRunning,
              !exploitStatus.isSuccess,
              !exploitStatus.isFailed,
              !autoRunAttempted else { return }
        autoRunAttempted = true
        log("app: starting kernel exploit automatically")
        runKernelExploitIfNeeded()
    }

    private func refreshKernelExploitStatus() {
        guard !kernelExploitRunning else { return }

        // iOS < 26: kernel R/W success persists (no sandbox probe)
        // iOS >= 26: verify full sandbox escape is still active
        if KernelExploit.requiresSandboxEscape {
            if KernelExploit.hasSandboxAccess() {
                if !exploitStatus.isSuccess {
                    exploitStatus = .success(method: "kexploit")
                    log("app: existing sandbox access is still active; skipping kernel exploit")
                }
            } else if exploitStatus.isSuccess {
                exploitStatus = .notStarted
                log("app: sandbox access is no longer active")
            }
        }
    }

    func runKernelExploitIfNeeded() {
        refreshKernelExploitStatus()
        guard !kernelExploitRunning,
              !exploitStatus.isSuccess,
              !exploitStatus.isFailed else { return }
        kernelExploitRunning = true
        exploitStatus = .notStarted
        log("app: running kernel exploit on background...")
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = KernelExploit.run()
            DispatchQueue.main.async {
                self.kernelExploitRunning = false
                if ok {
                    self.exploitStatus = .success(method: "kexploit")
                    if KernelExploit.requiresSandboxEscape {
                        log("app: kernel exploit success — sandbox access verified")
                    } else {
                        log("app: kernel exploit success — kernel access active")
                    }
                } else {
                    self.exploitStatus = .failed(method: "kexploit", code: -1)
                    log("app: kernel exploit failed — relaunch the app before retrying")
                }
            }
        }
    }
}
