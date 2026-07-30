//
//  BuddyVoiceHallViews.swift
//  坐标系
//
//  陪玩页第二幕：Soul 式语音厅（演示场；非真实时音频）。
//

import SwiftUI

struct BuddyVoiceHallShelfCard: View {
    let hall: VoiceHall
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: PlatformMetrics.radiusPoster, style: .continuous)
                    .fill(PlatformStatus.warning.opacity(0.16))
                    .overlay {
                        Image(systemName: hall.systemImage)
                            .font(.largeTitle)
                            .platformSymbolStyle(.status(PlatformStatus.warning))
                    }
                    .aspectRatio(PlatformMetrics.posterCardAspectRatio, contentMode: .fit)

                PlatformMediaCaptionBadge(
                    title: hall.isLive ? "直播中" : "休息中",
                    tint: hall.isLive ? PlatformStatus.success : .secondary
                )
            }
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
                    Text(hall.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(hall.topic)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PlatformMetrics.captionBadgeInset)
                .colorScheme(.dark)
                .allowsHitTesting(false)
            }
            .clipShape(PlatformMetrics.posterShape)
            .contentShape(PlatformMetrics.posterShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(hall.title)，\(hall.topic)，\(hall.isLive ? "直播中" : "休息中")")
        .accessibilityHint("进入语音厅")
    }
}

struct BuddyVoiceHallRoomView: View {
    let hall: VoiceHall

    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var isOnMic = false
    @State private var toast: String?

    private var seats: [String] {
        var names = hall.onMicNicknames
        if isOnMic, !names.contains(where: { $0 == app.user.name }) {
            names.append(app.user.name)
        }
        return names
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: PlatformMetrics.cardInfoSpacing) {
                    HStack {
                        Label(hall.isLive ? "直播中" : "休息中", systemImage: "dot.radiowaves.left.and.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(hall.isLive ? PlatformStatus.success : .secondary)
                        Spacer()
                        Text(hall.audienceText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(hall.title)
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(hall.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                        spacing: 16
                    ) {
                        ForEach(seats, id: \.self) { name in
                            seatCell(name)
                        }
                        if seats.count < 6 {
                            emptySeat
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
            }

            Section("厅信息") {
                LabeledContent("主题", value: hall.topic)
                LabeledContent("城市", value: hall.city)
                LabeledContent("厅主", value: hall.hostNickname)
            }

            Section {
                Text("演示语音厅：可上麦围观，点麦位可打招呼或预约陪玩。正式实时语音将另行接入。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("语音厅")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button(isOnMic ? "下麦" : "上麦") {
                    isOnMic.toggle()
                    toast = isOnMic ? "已上麦（演示）" : "已下麦"
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("离开") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.vertical, 10)
            .background(PlatformSurface.bar)
        }
        .platformTransientFeedback($toast)
        .navigationDestination(for: DiscoverBuddyItem.self) { item in
            BuddyDetailRouteView(item: item)
        }
    }

    private func seatCell(_ name: String) -> some View {
        let item = buddies.item(for: name)
        return Group {
            if let item {
                NavigationLink(value: item) {
                    seatContent(name: name, isHost: name == hall.hostNickname)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    toast = "演示：向 \(name) 打招呼"
                    if let convo = app.startDirectChat(with: name, greeting: "你好，我在「\(hall.title)」听到你了～") {
                        app.openMessages(conversationID: convo.id)
                    }
                } label: {
                    seatContent(name: name, isHost: name == hall.hostNickname)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func seatContent(name: String, isHost: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                PlatformListAvatarView(name: name, side: 64)
                Image(systemName: "mic.fill")
                    .font(.caption2.weight(.bold))
                    .padding(4)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Text(name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(isHost ? "厅主" : "麦上")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var emptySeat: some View {
        Button {
            isOnMic = true
            toast = "已上麦（演示）"
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "plus")
                            .foregroundStyle(.secondary)
                    }
                Text("空麦位")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
