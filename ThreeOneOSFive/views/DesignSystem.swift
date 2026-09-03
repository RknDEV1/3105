import SwiftUI
import UIKit

enum AppTheme {
    // Identidade CHZ PRIV: fundo preto, vermelho vivo, branco e cinza.
    static let accent = Color(red: 1.00, green: 0.015, blue: 0.055)
    static let accentBright = Color(red: 1.00, green: 0.16, blue: 0.19)
    static let accentSoft = Color(red: 1.00, green: 0.015, blue: 0.055).opacity(0.16)
    static let pageBackground = Color.black
    static let consoleBackground = Color(red: 0.045, green: 0.018, blue: 0.022)
    static let cardBackground = Color(red: 0.065, green: 0.020, blue: 0.026)
    static let fieldBackground = Color(red: 0.10, green: 0.035, blue: 0.042)
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.56, green: 0.56, blue: 0.58)
    static let tertiaryText = Color(red: 0.38, green: 0.38, blue: 0.40)
    static let success = Color(red: 0.19, green: 0.82, blue: 0.42)
    static let pageInset: CGFloat = 16
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18
    static let contentCardCornerRadius: CGFloat = 18
    static let contentCardInset: CGFloat = 16
    static let contentCardPadding: CGFloat = 16
}

struct AppCardBorder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.contentCardCornerRadius, style: .continuous)
            .strokeBorder(AppTheme.accent.opacity(0.52), lineWidth: 0.7)
            .accessibilityHidden(true)
    }
}

struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(tint.opacity(0.16))
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.42), lineWidth: 0.6)
                }
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .foregroundStyle(AppTheme.primaryText)
                .tint(AppTheme.accent)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 38)
        .background(
            AppTheme.fieldBackground,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.38), lineWidth: 0.7)
        }
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
        .background(AppTheme.pageBackground)
    }
}

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon = UIImage(named: "AppIcon60x60")
                ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
                ?? UIImage(named: "AppIcon") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.accent)
            }
        }
        .frame(width: size, height: size)
        .background(AppTheme.accent)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(AppTheme.accentBright.opacity(0.85), lineWidth: 1)
        }
        .shadow(color: AppTheme.accent.opacity(0.35), radius: 8)
        .accessibilityHidden(true)
    }
}

struct AppThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
            .tint(AppTheme.accent)
            .environment(\.font, .system(.body, design: .rounded))
            .foregroundStyle(AppTheme.primaryText)
            .scrollContentBackground(.hidden)
            .background(AppTheme.pageBackground.ignoresSafeArea())
    }
}

extension View {
    func appTheme() -> some View {
        modifier(AppThemeModifier())
    }
}
