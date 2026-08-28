//
//  BuddyMemberProfileSheet.swift
//  坐标系
//
//  圈子 / 工会 / 语音厅：半屏成员资料卡（系统 Form + browser detent）。
//  完整资料走 CircleBrowseRoute.member，与 Tab 栈成员导航一致。
//

import SwiftUI

struct BuddyMemberProfileSheet: View {
    let target: BuddyMemberProfileTarget
    var onBook: ((PaidCompanion) -> Void)? = nil
    var onLeaveMic: (() -> Void)? = nil

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var navigation = TabNavigationState()
    @State private var peerContactRoute: PeerContactRoute?

    private var profile: BuddyProfile { target.item.profile }

    private var paidCompanion: PaidCompanion? {
        if case .paid(let companion) = target.item { return companion }
        return nil
    }

    var body: some View {
        @Bindable var navigation = navigation

        NavigationStack(path: $navigation.path) {
            Form {
                Section {
                    header
                }

                if let line = target.source.contextLine {
                    Section {
                        LabeledContent(BuddyMemberCopy.sourceSectionTitle, value: line)
                    }
                }

                if !profile.bio.isEmpty {
                    Section {
                        Text(profile.bio)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(4)
                    } header: {
                        Text(BuddyDetailCopy.aboutTitle)
                    }
                }

                if case .voiceHall = target.source, let onLeaveMic {
                    Section {
                        Button(BuddyMemberCopy.leaveMic, role: .destructive, action: onLeaveMic)
                    }
                }

                Section {
                    CircleMemberNavigationLink(
                        item: target.item,
                        source: target.source,
                        groupAlias: target.groupAlias
                    ) {
                        Label(BuddyMemberCopy.openFullProfile, systemImage: "person.crop.circle")
                    }
                }
            }
            .navigationTitle(BuddyMemberCopy.profileTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(BuddyMemberCopy.done) { dismiss() }
                }
            }
            .platformDetailBottomBar {
                memberActionBar
            }
            .peerContactDestination(route: $peerContactRoute)
            .circleMemberSheetNavigationDestination()
        }
        .tabNavigationState(navigation)
        .independentNavigationSheetChrome(
            dismissSheet: { dismiss() },
            resetMemberSheetDestination: true
        )
        .platformSheet(.browser)
    }

    private var header: some View {
        VStack(spacing: PlatformMetrics.cardInfoSpacing) {
            PlatformListAvatarView(name: profile.nickname, side: 72)

            Text(target.profileDisplayName)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)

            Text(target.role)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let companion = paidCompanion {
                Text(companion.priceText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PlatformStatus.warning)
            } else if target.item.isOnline {
                Text(BuddyDetailCopy.online)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PlatformStatus.success)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
        .accessibilityElement(children: .combine)
    }

    private var contactActionTitle: String {
        app.peerContactActionTitle(
            for: profile.nickname,
            context: .forMemberTarget(target)
        )
    }

    private var contactActionSymbol: String {
        app.messages.canStartDirectChat(with: profile.nickname, context: .forMemberTarget(target))
            ? "bubble.left"
            : "person.badge.plus"
    }

    private func openPeerChat() {
        peerContactRoute = app.openPeerContact(
            with: profile.nickname,
            context: .forMemberTarget(target)
        )
    }

    @ViewBuilder
    private var memberActionBar: some View {
        if let companion = paidCompanion {
            DetailBottomActionBar {
                Button {
                    openPeerChat()
                } label: {
                    Label(contactActionTitle, systemImage: contactActionSymbol)
                }
                .activityDetailBottomSecondaryCTA()

                Button {
                    onBook?(companion)
                    dismiss()
                } label: {
                    Label(
                        companion.isAvailable ? BuddyBrowseCopy.bookAction : BuddyBrowseCopy.bookUnavailable,
                        systemImage: "bolt.fill"
                    )
                }
                .activityDetailBottomPrimaryCTA()
                .disabled(!companion.isAvailable)
            }
        } else {
            DetailBottomActionBar {
                Button {
                    openPeerChat()
                } label: {
                    Label(contactActionTitle, systemImage: contactActionSymbol)
                }
                .activityDetailBottomPrimaryCTA()
            }
        }
    }
}
