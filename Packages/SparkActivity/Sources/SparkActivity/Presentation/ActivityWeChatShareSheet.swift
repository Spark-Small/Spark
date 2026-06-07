// Module: SparkActivity — WeChat-oriented invite share (MODULE-H stub, no SDK).

import SparkDesignSystem
import SwiftUI

struct ActivityWeChatShareSheet: View {
    let activity: ActivityDetail
    let onCopied: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                shareCardPreview
                    .padding(SparkLayoutMetrics.matchCardPadding)
            }
            .navigationTitle(
                String(
                    localized: "activity.wechatShare.title",
                    defaultValue: "分享到微信",
                    comment: "WeChat share title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.close", defaultValue: "关闭", comment: "Close")) {
                        dismiss()
                    }
                    .buttonStyle(.sparkPressable)
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionButtons
                    .padding(.horizontal, SparkLayoutMetrics.matchCardPadding)
                    .padding(.bottom, SparkLayoutMetrics.compactVerticalPadding)
                    .background(.bar)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var shareCardPreview: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            Text(activity.title)
                .font(.headline)
            Text(activity.scheduleLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(activity.locationName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(ActivityInviteURL.inviteCopyText(activity: activity))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SparkLayoutMetrics.standardHorizontalPadding)
        .sparkGlassSurface(RoundedRectangle.sparkCard)
    }

    private var actionButtons: some View {
        VStack(spacing: SparkLayoutMetrics.sectionVerticalPadding) {
            Button {
                ActivityPasteboard.copy(ActivityInviteURL.inviteCopyText(activity: activity))
                onCopied()
            } label: {
                Label(
                    String(
                        localized: "activity.wechatShare.copy",
                        defaultValue: "复制邀请文案",
                        comment: "Copy for WeChat"
                    ),
                    systemImage: "doc.on.doc"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .sparkMinimumTouchTarget()

            Button {
                ActivityPasteboard.copy(ActivityInviteURL.inviteCopyText(activity: activity))
                onCopied()
                if let url = URL(string: "weixin://") {
                    openURL(url)
                }
            } label: {
                Label(
                    String(
                        localized: "activity.wechatShare.openWeChat",
                        defaultValue: "复制并打开微信",
                        comment: "Open WeChat"
                    ),
                    systemImage: "message.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .sparkMinimumTouchTarget()

            Text(
                String(
                    localized: "activity.wechatShare.footer",
                    defaultValue: "未集成微信 SDK 时，请粘贴文案到聊天窗口发送。",
                    comment: "WeChat share footer"
                )
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    if let activity = MockActivityCatalog.detail(id: "act_1") {
        ActivityWeChatShareSheet(activity: activity, onCopied: {})
    }
}
