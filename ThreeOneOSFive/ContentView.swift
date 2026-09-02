import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @State private var tabNavigation: AppTabNavigationState
    @AppStorage(FeatureVisibility.cleanerStorageKey) private var cleanerEnabled = true
    @AppStorage(FeatureVisibility.wallpapersStorageKey) private var wallpapersEnabled = true

    init() {
#if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: Int
        if arguments.contains("--simulate-files-tab") {
            initialTab = 1
        } else if arguments.contains("--simulate-patch-tab") {
            initialTab = 2
        } else if arguments.contains("--simulate-cleaner-tab") {
            initialTab = 3
        } else if arguments.contains("--simulate-wallpaper-tab") {
            initialTab = 4
        } else {
            initialTab = 0
        }
        _tabNavigation = State(initialValue: AppTabNavigationState(selectedTab: initialTab))
#else
        _tabNavigation = State(initialValue: AppTabNavigationState())
#endif
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .appTheme()
        .imageScale(.small)
        .dynamicTypeSize(.small)
        .onChange(of: patchDraftCoordinator.request?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.patches.rawValue) }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.patches.rawValue) }
        }
        .onChange(of: cleanerEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onChange(of: wallpapersEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onAppear {
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
    }

    private var compactLayout: some View {
        TabView(selection: tabSelection) {
            ForEach(featureVisibility.visibleSections) { section in
                sectionContent(section)
                    .tabItem {
                        CompactTabLabel(
                            title: language.text(section.titleKey),
                            systemImage: section.systemImage
                        )
                    }
                    .tag(section.rawValue)
            }
        }
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(featureVisibility.visibleSections) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            tabNavigation.select(section.rawValue)
                        }
                    } label: {
                        Label(language.text(section.titleKey), systemImage: section.systemImage)
                            .fontWeight(section.rawValue == tabNavigation.selectedTab ? .semibold : .regular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        section.rawValue == tabNavigation.selectedTab
                            ? AppTheme.accent.opacity(0.14)
                            : Color.clear
                    )
                    .accessibilityAddTraits(
                        section.rawValue == tabNavigation.selectedTab ? .isSelected : []
                    )
                }
            }
            .navigationTitle("3105")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } detail: {
            sectionContent(selectedVisibleSection)
                .id(selectedVisibleSection.rawValue)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home:
            CHZPrivHomeView()
        case .files:
            AppDataBrowserView(
                tabSession: filesTabSession
            )
        case .patches:
            PatchProjectsView()
        case .cleaner:
            CleanerView()
        case .wallpapers:
            WallpaperLabView()
        }
    }

    private var tabSelection: Binding<Int> {
        Binding(
            get: { tabNavigation.selectedTab },
            set: { tabNavigation.select($0) }
        )
    }

    private var filesTabSession: Binding<FilesTabSession> {
        Binding(
            get: { tabNavigation.filesTabs },
            set: { tabNavigation.setFilesTabs($0) }
        )
    }

    private var featureVisibility: FeatureVisibility {
        FeatureVisibility(
            cleanerEnabled: cleanerEnabled,
            wallpapersEnabled: wallpapersEnabled,
            wallpapersSupported: wallpapersSupported
        )
    }

    private var wallpapersSupported: Bool {
        WallpaperFeatureSupportPolicy.isSupported(major: AppInfo.versionTuple.major)
    }

    private var selectedVisibleSection: AppSection {
        guard let section = AppSection(rawValue: tabNavigation.selectedTab),
              featureVisibility.isVisible(section) else {
            return .home
        }
        return section
    }
}

private struct CompactTabLabel: View {
    let title: String
    let systemImage: String

    @ViewBuilder
    var body: some View {
        if let image = UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        )?.withRenderingMode(.alwaysTemplate) {
            Image(uiImage: image)
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
        }
        Text(title)
    }
}

private extension AppSection {
    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .files: return "tab.files"
        case .patches: return "tab.patches"
        case .cleaner: return "tab.cleaner"
        case .wallpapers: return "tab.wallpapers"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .files: return "folder.fill"
        case .patches: return "shippingbox.fill"
        case .cleaner: return "sparkles"
        case .wallpapers: return "photo.on.rectangle.angled"
        }
    }
}

private struct DashboardView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    @State private var showLogs = false
    @Binding var cleanerEnabled: Bool
    @Binding var wallpapersEnabled: Bool
    let wallpapersSupported: Bool

    var body: some View {
        NavigationStack {
            List {
                deviceSection
                featuresSection
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(AppTheme.accent)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showLogs = true } label: {
                        Image(systemName: "apple.terminal")
                    }
                    .accessibilityLabel(language.text("accessibility.open_logs"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(language.text("accessibility.open_settings"))
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showLogs) { LogView() }
        }
    }

    private var featuresSection: some View {
        Section {
            Toggle(isOn: $cleanerEnabled) {
                Label(language.text("tab.cleaner"), systemImage: "sparkles")
            }
            if wallpapersSupported {
                Toggle(isOn: $wallpapersEnabled) {
                    Label(language.text("tab.wallpapers"), systemImage: "photo.on.rectangle.angled")
                }
            }
        } header: {
            Text(language.text("dashboard.features"))
        } footer: {
            Text(language.text("dashboard.features_footer"))
        }
    }

    private var deviceSection: some View {
        Section {
            LabeledContent(language.text("dashboard.hardware_model")) {
                Text(AppInfo.displayMachineName)
                    .font(.body.monospaced())
            }
            LabeledContent(language.text("settings.ios_version")) {
                Text("\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                    .font(.body.monospaced())
            }
            HStack {
                Text(language.text("settings.compatibility"))
                Spacer()
                Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                .foregroundStyle(appState.isSupported ? AppTheme.success : Color.red)
            }

            if appState.kernelExploitApplicable && AppInfo.versionTuple.major < 26 {
                HStack {
                    Text(language.text("dashboard.kernel_status"))
                    Spacer()
                    if appState.kernelExploitRunning {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text(language.text("dashboard.kernel_running"))
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    } else {
                        Text(language.text(appState.exploitStatus.isSuccess ? "dashboard.kernel_active" : "dashboard.kernel_inactive"))
                        .foregroundStyle(appState.exploitStatus.isSuccess ? AppTheme.success : AppTheme.secondaryText)
                    }
                }
            }
        } header: {
            Text(language.text("common.device"))
        } footer: {
            Text(language.text("settings.supported_range_summary"))
        }
    }
}


private struct CHZPrivHomeView: View {
    private enum GameTab: String, CaseIterable, Identifiable {
        case freeFire = "Aimbot"
        case hologramas = "Hologramas"
        var id: String { rawValue }
    }

    private enum LogLevel: Equatable {
        case info, progress, success, warning

        var tint: Color {
            switch self {
            case .info: return AppTheme.secondaryText
            case .progress: return AppTheme.accentBright
            case .success: return AppTheme.success
            case .warning: return Color.orange
            }
        }

        var symbol: String {
            switch self {
            case .info: return "info.circle.fill"
            case .progress: return "arrow.triangle.2.circlepath"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
    }

    private struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: String
        let message: String
        let level: LogLevel
    }

    @State private var selectedGame: GameTab = .freeFire
    @State private var freeFirePatches: [PatchLibraryItem] = []
    @State private var enabledPatchIDs = Set<UUID>()
    @State private var isWorking = false
    @State private var activityLog = [LogEntry(
        timestamp: Date().formatted(date: .omitted, time: .shortened),
        message: "Sistema pronto — aguardando patches",
        level: .info
    )]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 13) {
                    logo
                    activityLogView
                    gameTabs
                    functions
                    backupStatus
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 18)
            }
            .scrollIndicators(.hidden)
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(AppTheme.accent)
        .onAppear {
            PatchProjectLibrary.installBundledOriginalFreeFirePatches()
            reloadFreeFirePatches()
        }
    }

    private var logo: some View {
        VStack(spacing: -2) {
            Text("CHZ")
                .font(.system(size: 36, weight: .black))
                .italic()
                .foregroundStyle(AppTheme.accent)
            Text("PRIV")
                .font(.system(size: 33, weight: .black))
                .italic()
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    private var gameTabs: some View {
        HStack(spacing: 0) {
            ForEach(GameTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedGame = tab
                    }
                } label: {
                    VStack(spacing: 0) {
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(selectedGame == tab ? .white : AppTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                        Capsule(style: .continuous)
                            .fill(selectedGame == tab ? AppTheme.accentBright : .clear)
                            .frame(height: 3)
                            .padding(.horizontal, 14)
                    }
                    .background(selectedGame == tab ? AppTheme.accent.opacity(0.10) : .clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 0.7)
        }
    }

    private var functions: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Funções")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(visiblePatches.count) patches")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.bottom, 2)

            if !visiblePatches.isEmpty {
                ForEach(visiblePatches) { item in
                    functionRow(item: item)
                }
            } else {
                Text("Nenhum patch disponível para \(selectedGame.rawValue)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 26)
            }
        }
    }

    private func functionRow(item: PatchLibraryItem) -> some View {
        let active = enabledPatchIDs.contains(item.id)
        let title = item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(active ? "Patch ativo · backup protegido" : "Substituição autorizada")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(active ? AppTheme.success : AppTheme.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Toggle("\(title)", isOn: Binding(
                get: { enabledPatchIDs.contains(item.id) },
                set: { updatePatchState(item: item, isEnabled: $0) }
            ))
                .labelsHidden()
                .toggleStyle(CHZSwitchStyle())
                .disabled(item.project == nil || isWorking)
        }
        .padding(.horizontal, 13)
        .frame(minHeight: 70)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 0.7)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.42), lineWidth: 0.55)
        }
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(
                    colors: [.white.opacity(0.13), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                ))
                .frame(height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .allowsHitTesting(false)
        }
    }

    private var visiblePatches: [PatchLibraryItem] {
        freeFirePatches.filter { item in
            let title = (item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent)
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let belongsToHologramas = title.contains("hs peito")
            return selectedGame == .hologramas ? belongsToHologramas : !belongsToHologramas
        }
    }

    private func reloadFreeFirePatches() {
        // Os pacotes empacotados nesta versão pertencem exclusivamente ao Free Fire.
        let items = PatchProjectLibrary.load()
        freeFirePatches = items
        enabledPatchIDs = Set(items.compactMap { item in
            guard DevicePatchService.latestReceipt(projectID: item.id) != nil else { return nil }
            return item.id
        })
    }

    private func updatePatchState(item: PatchLibraryItem, isEnabled: Bool) {
        guard let baseProject = item.project else {
            appendLog("Patch indisponível: pacote bloqueado ou inválido", level: .warning)
            return
        }
        let patchName = baseProject.name
        isWorking = true

        if isEnabled {
            activityLog.removeAll(keepingCapacity: true)
            appendLog("Nova sessão iniciada — \(patchName)", level: .info)
            appendLog("Validando configuração do patch", level: .progress)
            appendLog("Criando backup do arquivo original", level: .progress)
            applyPatch(item: item, baseProject: baseProject, patchName: patchName)
        } else {
            activityLog.removeAll(keepingCapacity: true)
            appendLog("Sessão de restauração — \(patchName)", level: .info)
            appendLog("Verificando journal e backup protegido", level: .progress)
            restorePatch(item: item, patchName: patchName)
        }
    }

    private func applyPatch(item: PatchLibraryItem, baseProject: PatchProject, patchName: String) {
        Task.detached(priority: .userInitiated) {
            do {
                let project = item.summary.schemaVersion >= 2
                    ? try PatchProjectLibrary.synchronizeWorkspace(item: item)
                    : baseProject
                _ = try DevicePatchService.apply(project: project)
                await MainActor.run {
                    enabledPatchIDs.insert(item.id)
                    isWorking = false
                    appendLog("Patch aplicado e verificado", level: .success)
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    appendLog("Falha ao ativar: \(error.localizedDescription)", level: .warning)
                }
            }
        }
    }

    private func restorePatch(item: PatchLibraryItem, patchName: String) {
        guard let receipt = DevicePatchService.latestReceipt(projectID: item.id) else {
            enabledPatchIDs.remove(item.id)
            isWorking = false
            appendLog("Nenhum backup ativo encontrado", level: .warning)
            return
        }
        Task.detached(priority: .userInitiated) {
            do {
                try DevicePatchService.restore(receipt: receipt)
                await MainActor.run {
                    enabledPatchIDs.remove(item.id)
                    isWorking = false
                    appendLog("Arquivo original restaurado", level: .success)
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    appendLog("Falha ao restaurar: \(error.localizedDescription)", level: .warning)
                }
            }
        }
    }

    private func appendLog(_ message: String, level: LogLevel) {
        let timestamp = Date().formatted(date: .omitted, time: .shortened)
        activityLog.append(LogEntry(timestamp: timestamp, message: message, level: level))
        if activityLog.count > 30 {
            activityLog.removeFirst(activityLog.count - 30)
        }
    }

    private var activityLogView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.16))
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.accentBright)
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Log de atividade")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("Sessão atual · \(enabledPatchIDs.count) ativo(s)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Circle()
                    .fill(activityLog.last?.level.tint ?? AppTheme.secondaryText)
                    .frame(width: 8, height: 8)
                    .shadow(color: (activityLog.last?.level.tint ?? AppTheme.secondaryText).opacity(0.65), radius: 5)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 9) {
                        ForEach(activityLog) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: entry.level.symbol)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(entry.level.tint)
                                    .frame(width: 16)
                                    .padding(.top, 1)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(entry.message)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(entry.level == .warning ? Color.orange : .white.opacity(0.88))
                                    Text(entry.timestamp)
                                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                                        .foregroundStyle(AppTheme.tertiaryText)
                                }
                                Spacer(minLength: 0)
                            }
                            .id(entry.id)
                        }
                    }
                }
                .frame(maxHeight: 128)
                .onChange(of: activityLog.count) { _ in
                    if let last = activityLog.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(13)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 0.7)
        }
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(LinearGradient(
                    colors: [.white.opacity(0.10), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                ))
                .frame(height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .allowsHitTesting(false)
        }
    }

    private var backupStatus: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            Text("Backup original protegido")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.top, 18)
    }
}


private struct CHZSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                configuration.isOn.toggle()
            }
        } label: {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule(style: .continuous)
                    .fill(configuration.isOn
                    ? LinearGradient(
                        colors: [AppTheme.accentBright, AppTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.16), Color.black.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                    .frame(width: 58, height: 34)
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(configuration.isOn ? AppTheme.accentBright : Color.white.opacity(0.28), lineWidth: 0.9)
                    }

                Circle()
                    .fill(configuration.isOn ? Color.white : Color(red: 0.70, green: 0.70, blue: 0.74))
                    .frame(width: 28, height: 28)
                    .shadow(color: .black.opacity(0.28), radius: 2, y: 1)
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(configuration.isOn ? "Ativado" : "Desativado")
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
    }
}
