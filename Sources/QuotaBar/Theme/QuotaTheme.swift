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

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(reduceTransparency ? AnyShapeStyle(Color(nsColor: .windowBackgroundColor)) : AnyShapeStyle(.ultraThinMaterial))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 0.75)
            }
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}
