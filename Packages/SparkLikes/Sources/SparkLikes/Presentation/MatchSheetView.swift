// Module: SparkLikes — Mutual like celebration + icebreakers.

import SparkDesignSystem
import SwiftUI

struct MatchSheetView: View {
    let peerName: String
    let peerCard: DiscoverCard?
    let icebreakers: [String]
    let onSendMessage: (String?) -> Void
    let onDismiss: () -> Void
    var onOpenSharedActivity: ((String) -> Void)?

    @State private var selectedIcebreaker: String?

    var body: some View {
        VStack(spacing: 16) {
            avatarRow
            Text(
                String(
                    localized: "likes.match.celebration.title",
                    defaultValue: "互相心动了！",
                    comment: "Match celebration title"
                )
            )
            .font(.title.weight(.bold))
            Text(matchSubtitle(for: peerName))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !icebreakers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        String(
                            localized: "likes.match.icebreaker.section",
                            defaultValue: "选一句开场白",
                            comment: "Icebreaker section"
                        )
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(icebreakers, id: \.self) { line in
                        Button {
                            selectedIcebreaker = line
                        } label: {
                            HStack {
                                Text(line)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if selectedIcebreaker == line {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.pink)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .sparkGlassSurface(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let activity = peerCard?.sharedActivityTitle {
                Text(activityHint(for: activity))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            if let activityID = peerCard?.sharedActivityID, let onOpenSharedActivity {
                Button(
                    String(
                        localized: "likes.match.openActivity",
                        defaultValue: "查看共同活动",
                        comment: "Open shared activity"
                    )
                ) {
                    onOpenSharedActivity(activityID)
                }
                .buttonStyle(.bordered)
            }

            Button(
                String(localized: "likes.match.message", defaultValue: "发消息", comment: "Open chat"),
                action: { onSendMessage(selectedIcebreaker) }
            )
            .buttonStyle(.borderedProminent)
            .accessibilityHint(
                String(
                    localized: "likes.match.message.hint",
                    defaultValue: "打开消息会话",
                    comment: "Match message hint"
                )
            )

            Button(String(localized: "action.later", defaultValue: "稍后再说", comment: "Later"), action: onDismiss)
                .buttonStyle(.borderless)
        }
        .padding(24)
        .presentationBackground(.regularMaterial)
        .presentationDetents([.medium, .large])
    }

    private var avatarRow: some View {
        HStack(spacing: 16) {
            matchAvatar(symbol: "person.crop.circle.fill")
            Image(systemName: "heart.fill")
                .font(.title)
                .foregroundStyle(.pink)
                .accessibilityHidden(true)
            matchAvatar(symbol: "person.crop.circle.fill")
        }
        .padding(.top, 8)
    }

    private func matchAvatar(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .frame(width: 72, height: 72)
            .sparkGlassControl(Circle())
    }

    private func matchSubtitle(for peerName: String) -> String {
        let format = String(
            localized: "likes.match.subtitle.format",
            defaultValue: "你和 %@ 互相喜欢",
            comment: "Match subtitle; %@ is name"
        )
        return String(format: format, locale: .current, peerName)
    }

    private func activityHint(for activity: String) -> String {
        let format = String(
            localized: "likes.match.activity.hint.format",
            defaultValue: "你们都对「%@」感兴趣，聊聊要不要一起参加？",
            comment: "Match activity hint"
        )
        return String(format: format, locale: .current, activity)
    }
}

#Preview {
    MatchSheetView(
        peerName: "小雨",
        peerCard: nil,
        icebreakers: ["你好，很高兴配对成功"],
        onSendMessage: { _ in },
        onDismiss: {}
    )
}

#Preview("Match — dark") {
    SparkPreviewSupport.darkMode {
        MatchSheetView(
            peerName: "小雨",
            peerCard: nil,
            icebreakers: ["你好，很高兴配对成功"],
            onSendMessage: { _ in },
            onDismiss: {}
        )
    }
}

#Preview("Match — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        MatchSheetView(
            peerName: "小雨",
            peerCard: nil,
            icebreakers: ["你好，很高兴配对成功", "周末有空一起喝咖啡吗？"],
            onSendMessage: { _ in },
            onDismiss: {}
        )
    }
}
