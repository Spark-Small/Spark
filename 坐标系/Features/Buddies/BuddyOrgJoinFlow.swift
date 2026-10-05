//
//  BuddyOrgJoinFlow.swift
//  坐标系
//
//  兴趣圈子加入链路：确认 → 成功（进群）。
//

import SwiftUI
import CoordinateModels

struct BuddyOrgJoinConfirmSheet: View {
    let target: BuddyOrgJoinTarget
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var displayName: String {
        switch target {
        case .circle(let c):
            let count: Int
            if BuddiesSupplyPolicy.allowsSampleDiscoverCatalog {
                count = SampleData.circleBuddies.filter { $0.circleName == c.name }.count
            } else {
                count = max(c.memberCount, 0)
            }
            return "\(c.name)（\(count)）"
        case .guild(let g):
            return g.name
        }
    }

    private var subtitle: String? {
        switch target {
        case .circle:
            return nil
        case .guild(let g):
            return "\(g.city) · \(g.specialty) · \(g.priceFromText)"
        }
    }

    private var summary: String {
        switch target {
        case .circle(let c): c.summary
        case .guild(let g): g.summary
        }
    }

    private var systemImage: String {
        switch target {
        case .circle(let c): c.systemImage
        case .guild(let g): g.systemImage
        }
    }

    private var confirmTitle: String {
        switch target {
        case .circle: BuddyOrgJoinCopy.confirmCircleTitle
        case .guild: BuddyOrgJoinCopy.confirmGuildTitle
        }
    }

    private var joinOutcomeRow: (title: String, value: String) {
        switch target {
        case .circle:
            return (BuddyOrgJoinCopy.confirmChatRowTitle, BuddyOrgJoinCopy.confirmChatRowValue)
        case .guild:
            return (BuddyOrgJoinCopy.confirmGuildRowTitle, BuddyOrgJoinCopy.confirmGuildRowValue)
        }
    }

    private var joinOutcomeFooter: String {
        switch target {
        case .circle: BuddyOrgJoinCopy.confirmChatFooter
        case .guild: BuddyOrgJoinCopy.confirmGuildFooter
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: PlatformMetrics.cardInfoSpacing) {
                        Image(systemName: systemImage)
                            .font(.largeTitle)
                            .platformSymbolStyle(.multicolor)
                            .frame(width: 72, height: 72)
                            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: PlatformMetrics.radiusCard, style: .continuous))

                        Text(displayName)
                            .font(.title3.weight(.bold))
                            .multilineTextAlignment(.center)

                        if let subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        Text(summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
                }

                Section {
                    LabeledContent(joinOutcomeRow.title, value: joinOutcomeRow.value)
                } footer: {
                    Text(joinOutcomeFooter)
                }
            }
            .navigationTitle(confirmTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(BuddyOrgJoinCopy.cancel) {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(BuddyOrgJoinCopy.confirmJoinCTA) {
                        onConfirm()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .platformSheet(.confirm)
    }
}

struct BuddyOrgJoinSuccessSheet: View {
    let success: BuddyOrgJoinSuccess
    var hasConversation: Bool
    var onEnterChat: () -> Void
    var onViewOrg: () -> Void
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var joinedTitle: String {
        switch success.kind {
        case .circle: "已加入俱乐部"
        case .guild: "已关注工会"
        }
    }

    private var joinedHint: String? {
        switch success.kind {
        case .circle:
            return hasConversation
                ? "群聊在资料页或「消息」中进入；退出俱乐部不等于只退群聊。"
                : "可在俱乐部资料中随时退出。"
        case .guild:
            return "可在工会资料中随时取消关注。"
        }
    }

    private var viewOrgButtonTitle: String {
        switch success.kind {
        case .circle: "查看俱乐部"
        case .guild: "查看资料"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: PlatformMetrics.sectionSpacing) {
                Spacer(minLength: PlatformMetrics.cardFooterSpacing)

                Image(systemName: success.systemImage)
                    .font(.largeTitle)
                    .platformSymbolStyle(.multicolor)
                    .accessibilityHidden(true)

                Text(joinedTitle)
                    .font(.title2.weight(.bold))

                Text("「\(success.name)」")
                    .font(.headline)

                if let joinedHint {
                    Text(joinedHint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PlatformMetrics.contentInset)
                }

                Spacer()

                VStack(spacing: PlatformMetrics.cardFooterSpacing) {
                    Button(viewOrgButtonTitle) {
                        onViewOrg()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if hasConversation {
                        Button(BuddyOrgJoinCopy.enterChat) {
                            onEnterChat()
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, PlatformMetrics.contentInset)
                .padding(.bottom, PlatformMetrics.minContentGap)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(BuddyOrgJoinCopy.close) {
                        onDone()
                        dismiss()
                    }
                }
            }
        }
        .platformSheet(.confirm)
    }
}

struct BuddyOrgInviteMembersSheet: View {
    let target: BuddyOrgInviteTarget
    let viewerName: String
    let blockedUserNames: Set<String>
    var onSend: ([String]) -> Void
    var onBrowseBuddies: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(BuddiesModel.self) private var buddies
    @Environment(MessagesModel.self) private var messages
    @State private var selected = Set<String>()

    private var candidates: [String] {
        var names: [String] = []
        if BuddiesSupplyPolicy.allowsSampleDiscoverCatalog {
            switch target {
            case .circle:
                names.append(contentsOf: SampleData.circleBuddies.map(\.profile.nickname))
            case .guild:
                names.append(contentsOf: SampleData.paidCompanions.map(\.profile.nickname))
            }
        }
        names.append(
            contentsOf: MessagesContactRoster.nicknames(
                conversations: messages.conversations,
                inviteNicknames: buddies.inviteRecords.map(\.nickname),
                bookingNicknames: buddies.bookingRecords.map(\.companionNickname),
                blockedNames: Array(blockedUserNames)
            )
        )
        return names
            .uniqued()
            .filter { $0.caseInsensitiveCompare(viewerName) != .orderedSame }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private var title: String {
        switch target {
        case .circle(let c): "邀请加入「\(c.name)」"
        case .guild(let g): "邀请关注「\(g.name)」"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if candidates.isEmpty {
                    ContentUnavailableView {
                        Label(BuddiesSupplyPolicy.orgInviteEmptyTitle, systemImage: "person.badge.plus")
                    } description: {
                        Text(BuddiesSupplyPolicy.orgInviteEmptyDescription)
                    } actions: {
                        Button(BuddiesSupplyPolicy.orgInviteBrowseCTA) {
                            dismiss()
                            onBrowseBuddies?()
                        }
                        Button(BuddyOrgJoinCopy.close) { dismiss() }
                    }
                } else {
                    List {
                        Section {
                            ForEach(candidates, id: \.self) { name in
                                Button {
                                    if selected.contains(name) {
                                        selected.remove(name)
                                    } else {
                                        selected.insert(name)
                                    }
                                } label: {
                                    HStack {
                                        PlatformListAvatarView(name: name, side: 36)
                                        Text(name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selected.contains(name) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.tint)
                                        }
                                    }
                                }
                            }
                        } footer: {
                            Text(BuddyOrgJoinCopy.inviteLocalFooter)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(BuddyOrgJoinCopy.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(BuddyOrgJoinCopy.send) {
                        onSend(Array(selected))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    // 发送通道未接：禁用，避免点「发送」后假成功。
                    .disabled(true)
                    .accessibilityHint(BuddyOrgJoinCopy.inviteUnavailable)
                }
            }
        }
        .platformSheet(.browser)
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0.lowercased()).inserted }
    }
}
