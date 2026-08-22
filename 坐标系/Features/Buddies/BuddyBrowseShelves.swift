//
//  BuddyBrowseShelves.swift
//  坐标系
//
//  语音厅：频道卡 + 横滑轨。
//

import SwiftUI

// MARK: - 语音厅

struct BuddyVoiceChannelCard: View {
    let hall: VoiceHall
    var onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var dynamicMicSide: CGFloat {
        (dynamicTypeSize.listAvatarSide * 0.85).rounded(.toNearestOrAwayFromZero)
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: PlatformMetrics.minContentGap) {
                    Label(hall.title, systemImage: "speaker.wave.2.fill")
                        .font(.headline.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(hall.isLive ? PlatformStatus.success : .primary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(hall.isLive ? "直播中" : "休息中")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(hall.isLive ? PlatformStatus.success : .secondary)
                }

                Text(hall.topic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: PlatformMetrics.cardFooterSpacing) {
                    micAvatarStack
                    Text(hall.audienceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Text("进厅")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(PlatformMetrics.contentInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(hall.title)，\(hall.topic)，\(hall.audienceText)")
        .accessibilityHint("进入语音厅")
    }

    private var micAvatarStack: some View {
        HStack(spacing: -PlatformMetrics.minContentGap) {
            ForEach(Array(hall.onMicNicknames.prefix(4).enumerated()), id: \.offset) { _, name in
                PlatformListAvatarView(name: name, side: dynamicMicSide)
                    .overlay {
                        Circle().strokeBorder(PlatformSurface.elevated, lineWidth: 2)
                    }
            }
            if hall.onMicNicknames.count > 4 {
                Text("+\(hall.onMicNicknames.count - 4)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, PlatformMetrics.minContentGap)
            }
        }
        .accessibilityHidden(true)
    }
}

struct BuddyVoiceChannelRail: View {
    let halls: [VoiceHall]
    var onOpen: (VoiceHall) -> Void

    var body: some View {
        DiscoverBrowseSection(
            title: "语音厅",
            subtitle: "先听氛围再决定"
        ) {
            DiscoverHorizontalRail {
                ForEach(halls) { hall in
                    BuddyVoiceChannelCard(hall: hall) {
                        onOpen(hall)
                    }
                    .platformContinueRailFrame()
                }
            }
        }
    }
}
