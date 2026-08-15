import AppKit
import SwiftUI

struct ProviderBrandIcon: View {
    let provider: ProviderID
    let size: CGFloat

    var body: some View {
        Group {
            if let image = brandImage {
                Image(nsImage: image)
                    .resizable()
                    .renderingMode(provider == .codex ? .template : .original)
                    .foregroundStyle(.primary)
                    .scaledToFit()
            } else {
                Image(systemName: provider.symbolName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(QuotaTheme.color(for: provider))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var brandImage: NSImage? {
        guard let url = Bundle.module.url(
            forResource: provider.brandAssetName,
            withExtension: "png",
            subdirectory: "Brand"
        ) else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}
