//
//  BuddyMemberProfileSheet.swift
//  坐标系
//
//  组织 / 工会 / 语音厅：半屏成员资料卡（系统 Form + confirm detent）。
//  小圆头像不走 Zoom；完整资料用视图式 NavigationLink 推入。
//

import SwiftUI

struct BuddyMemberProfileSheet: View {
    let target: BuddyMemberProfileTarget
    var onMessage: (DiscoverBuddyItem) -> Void
    var onBook: ((PaidCompanion) -> Void)? = nil
    var onLeaveMic: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    private var profile: BuddyProfile { target.item.profile }

    private var paidCompanion: PaidCompanion? {
        if case .paid(let companion) = target.item { return companion }
        return nil
    }

    var body: some View {
        NavigationStack {
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

                Section {
                    Button {
                        onMessage(target.item)
                        dismiss()
                    } label: {
                        Label(BuddyMemberCopy.message, systemImage: "bubble.left")
                            .frame(maxWidth: .infinity)
                    }
                    .fontWeight(.semibold)

                    if let companion = paidCompanion {
                        Button {
                            onBook?(companion)
                            dismiss()
                        } label: {
                            Label(
                                companion.isAvailable ? BuddyMemberCopy.book : BuddyMemberCopy.bookUnavailable,
                                systemImage: "calendar.badge.clock"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .fontWeight(target.source.emphasizesBooking ? .semibold : .regular)
                        .disabled(!companion.isAvailable)
                    }

                    if case .voiceHall = target.source, let onLeaveMic {
                        Button(BuddyMemberCopy.leaveMic, role: .destructive, action: onLeaveMic)
                    }
                }

                Section {
                    NavigationLink {
                        BuddyDetailRouteView(item: target.item, source: target.source)
                    } label: {
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
        }
        .platformSheet(.browser)
    }

    private var header: some View {
        VStack(spacing: PlatformMetrics.cardInfoSpacing) {
            PlatformListAvatarView(name: profile.nickname, side: 72)

            Text(profile.nickname)
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
}
