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

struct NativeSectionModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        Color(nsColor: .separatorColor).opacity(colorScheme == .dark ? 0.55 : 0.7),
                        lineWidth: 0.5
                    )
            }
    }

    private var cardFill: Color {
        if reduceTransparency {
            return Color(nsColor: .controlBackgroundColor)
        }
        return Color.primary.opacity(colorScheme == .dark ? 0.055 : 0.035)
    }
}

extension View {
    func nativeSection() -> some View {
        modifier(NativeSectionModifier())
    }
}
