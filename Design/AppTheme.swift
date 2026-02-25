import SwiftUI

enum AppTheme {
    static var background: Color {
        Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 32/255, green: 30/255, blue: 45/255, alpha: 1)
                    : UIColor(red: 229/255, green: 225/255, blue: 239/255, alpha: 1)
            }
        )
    }

    static var card: Color {
        Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 48/255, green: 44/255, blue: 67/255, alpha: 1)
                    : UIColor(red: 247/255, green: 246/255, blue: 252/255, alpha: 1)
            }
        )
    }

    static var accent: Color { Color(red: 145/255, green: 127/255, blue: 198/255) }
    static var textPrimary: Color { Color(UIColor.label) }
    static var textSecondary: Color { Color(UIColor.secondaryLabel) }
    static var track: Color { Color(UIColor.systemGray4) }
    static var timeline: Color { accent.opacity(0.35) }
}

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.card)
            )
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(minHeight: 44)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.accent)
                    .opacity(configuration.isPressed ? 0.85 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.textPrimary)
            .frame(minHeight: 44)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.accent.opacity(0.25), lineWidth: 1)
                    )
                    .opacity(configuration.isPressed ? 0.85 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardModifier())
    }

    func appScreenBackground() -> some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            self
        }
    }

    func highTapTarget() -> some View {
        self
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}
