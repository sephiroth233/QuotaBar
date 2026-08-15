import SwiftUI

enum QuotaTheme {
    static func color(for provider: ProviderID) -> Color {
        switch provider {
        case .codex: .mint
        case .openRouter: .indigo
        case .deepSeek: .blue
        }
    }

    static func color(for health: ProviderHealth) -> Color {
        switch health {
        case .healthy: .green
        case .warning: .orange
        case .critical: .red
        case .unavailable: .secondary
        }
    }
}

struct GlassCardModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.primary.opacity(colorScheme == .dark ? 0.14 : 0.09), lineWidth: 0.75)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.14 : 0.045), radius: 5, y: 2)
    }

    private var cardFill: Color {
        if reduceTransparency {
            return Color(nsColor: .controlBackgroundColor)
        }
        if colorScheme == .dark {
            return Color(nsColor: .controlBackgroundColor).opacity(0.90)
        }
        return Color.white.opacity(0.84)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}
