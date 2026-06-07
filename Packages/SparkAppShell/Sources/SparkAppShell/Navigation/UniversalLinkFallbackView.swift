// Module: SparkAppShell — In-app fallback when universal link cannot be handled.

import SparkDesignSystem
import SwiftUI

public struct UniversalLinkFallbackView: View {
    let url: URL
    let onDismiss: () -> Void

    public init(url: URL, onDismiss: @escaping () -> Void) {
        self.url = url
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: SparkLayoutMetrics.matchCardPadding) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(
                String(
                    localized: "deeplink.fallback.title",
                    defaultValue: "无法打开链接",
                    comment: "Deep link fallback title"
                )
            )
            .font(.title3.weight(.semibold))

            Text(
                String(
                    localized: "deeplink.fallback.body",
                    defaultValue: "该链接可能已失效，或需要更新 App 版本。",
                    comment: "Deep link fallback body"
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Text(url.absoluteString)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(SparkLayoutMetrics.standardHorizontalPadding)
                .sparkGlassSurface(RoundedRectangle.sparkCard)

            Spacer(minLength: 0)
        }
        .padding(SparkLayoutMetrics.matchCardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: SparkLayoutMetrics.sectionVerticalPadding) {
                ShareLink(item: url) {
                    Label(
                        String(
                            localized: "deeplink.fallback.share",
                            defaultValue: "分享链接",
                            comment: "Share link"
                        ),
                        systemImage: "square.and.arrow.up"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .sparkMinimumTouchTarget()

                Button(String(localized: "action.close", defaultValue: "关闭", comment: "Close"), action: onDismiss)
                    .buttonStyle(.sparkPressable)
                    .sparkMinimumTouchTarget()
            }
            .padding(.horizontal, SparkLayoutMetrics.matchCardPadding)
            .padding(.bottom, SparkLayoutMetrics.matchCardPadding)
            .background(.bar)
        }
    }
}

#Preview {
    UniversalLinkFallbackView(url: URL(string: "https://spark.app/a/act_1")!, onDismiss: {})
}
