//
//  BuddyVoiceHallViews.swift
//  坐标系
//
//  语音厅房间：麦位 → 半屏资料卡（不离厅、不 Zoom）；空麦位申请上麦。
//  发现页频道卡见 BuddyBrowseShelves.BuddyVoiceChannelCard。
//

import SwiftUI

struct BuddyVoiceHallRoomView: View {
    let hall: VoiceHall

    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var isOnMic = false
    @State private var toast: String?
    @State private var selectedSeat: BuddyMemberProfileTarget?
    @State private var confirmTakeMic = false
    @State private var peerContactRoute: PeerContactRoute?

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
                        columns: Array(repeating: GridItem(.flexible(), spacing: PlatformMetrics.cardFooterSpacing), count: 3),
                        spacing: PlatformMetrics.discoverCardSpacing
                    ) {
                        ForEach(seats, id: \.self) { name in
                            seatCell(name)
                        }
                        if seats.count < 6 {
                            emptySeat
                        }
                    }
                    .padding(.top, PlatformMetrics.minContentGap)
                }
                .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
            }

            Section("厅信息") {
                LabeledContent("主题", value: hall.topic)
                LabeledContent("城市", value: hall.city)
                LabeledContent("厅主", value: hall.hostNickname)
            }

            Section {
                Text("演示语音厅：可上麦围观，点麦位查看资料。正式实时语音将另行接入。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("语音厅")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: PlatformMetrics.cardFooterSpacing) {
                Button(isOnMic ? BuddyMemberCopy.leaveMic : BuddyMemberCopy.takeMic) {
                    if isOnMic {
                        isOnMic = false
                        toast = BuddyMemberCopy.offMicDemo
                    } else {
                        confirmTakeMic = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("离开") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.vertical, PlatformMetrics.formRowVerticalPadding * 2)
            .background(PlatformSurface.bar)
        }
        .alert(BuddyMemberCopy.takeMic, isPresented: $confirmTakeMic) {
            Button(BuddyMemberCopy.takeMic) {
                isOnMic = true
                toast = BuddyMemberCopy.onMicDemo
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(BuddyMemberCopy.emptySeatHint)
        }
        .peerContactDestination(route: $peerContactRoute)
        .sheet(item: $selectedSeat) { target in
            BuddyMemberProfileSheet(
                target: target,
                onBook: { companion in
                    buddies.book(companion)
                },
                onLeaveMic: target.item.profile.nickname == app.user.name
                    ? {
                        isOnMic = false
                        selectedSeat = nil
                        toast = BuddyMemberCopy.offMicDemo
                    }
                    : nil
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .platformFeedbackAlert($toast)
    }

    private func seatCell(_ name: String) -> some View {
        let isHost = name == hall.hostNickname
        let isSelf = name == app.user.name
        return Button {
            openSeat(name: name, isHost: isHost)
        } label: {
            seatContent(name: name, isHost: isHost, isSelf: isSelf)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(BuddyMemberCopy.seatAccessibility(nickname: name, isHost: isHost))
        .accessibilityHint(BuddyMemberCopy.profileTitle)
    }

    private func openSeat(name: String, isHost: Bool) {
        let source = BuddyProfileSource.voiceHall(title: hall.title, isHost: isHost)
        let role = isHost ? BuddyMemberCopy.roleHost : BuddyMemberCopy.roleOnMic

        if let item = buddies.item(for: name) {
            selectedSeat = BuddyMemberProfileTarget(item: item, source: source, role: role)
            return
        }

        // 麦上昵称无完整资料时：进入私聊，不自动发消息
        peerContactRoute = app.openPeerContact(
            with: name,
            context: .voiceHall(hallTitle: hall.title)
        )
    }

    private func seatContent(name: String, isHost: Bool, isSelf: Bool) -> some View {
        VStack(spacing: PlatformMetrics.minContentGap) {
            ZStack(alignment: .bottomTrailing) {
                PlatformListAvatarView(name: name, side: 64)
                Image(systemName: "mic.fill")
                    .font(.caption2.weight(.bold))
                    .padding(PlatformMetrics.avatarBadgeOffset)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Text(isSelf ? BuddyMemberCopy.roleSelf : name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(isHost ? BuddyMemberCopy.roleHost : BuddyMemberCopy.roleOnMic)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.minContentGap)
    }

    private var emptySeat: some View {
        Button {
            confirmTakeMic = true
        } label: {
            VStack(spacing: PlatformMetrics.minContentGap) {
                Circle()
                    .strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "plus")
                            .foregroundStyle(.secondary)
                    }
                Text(BuddyMemberCopy.emptySeat)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlatformMetrics.minContentGap)
        }
        .buttonStyle(.plain)
        .disabled(isOnMic)
        .accessibilityLabel(BuddyMemberCopy.emptySeat)
        .accessibilityHint(BuddyMemberCopy.emptySeatHint)
    }
}
