//
//  BuddyOrgJoinFlow.swift
//  坐标系
//
//  兴趣圈子加入链路：确认 → 成功（进群）。
//

import SwiftUI

nonisolated enum BuddyOrgJoinCopy {
    static let confirmTitle = "加入圈子"
    static let confirmJoinCTA = "确认加入"

    static let confirmChatRowTitle = "加入后"
    static let confirmChatRowValue = "进入圈子群聊"
    static let confirmChatFooter = "群聊将出现在「消息」，你可在圈子资料中随时退出。"

    static let confirmGuildRowTitle = "关注后"
    static let confirmGuildRowValue = "查看工会陪玩"
    static let confirmGuildFooter = "可在工会资料中随时取消关注。"
}

struct BuddyOrgJoinConfirmSheet: View {
    let target: BuddyOrgJoinTarget
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var displayName: String {
        switch target {
        case .circle(let c):
            let count = SampleData.circleBuddies.filter { $0.circleName == c.name }.count
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
            .navigationTitle(BuddyOrgJoinCopy.confirmTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
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

    var body: some View {
        NavigationStack {
            VStack(spacing: PlatformMetrics.sectionSpacing) {
                Spacer(minLength: PlatformMetrics.cardFooterSpacing)

                Image(systemName: success.systemImage)
                    .font(.largeTitle)
                    .platformSymbolStyle(.multicolor)
                    .accessibilityHidden(true)

                Text("已加入圈子")
                    .font(.title2.weight(.bold))

                Text("「\(success.name)」")
                    .font(.headline)

                if !hasConversation {
                    Text("可在「我的 · 我的圈子」里找到它。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                VStack(spacing: PlatformMetrics.cardFooterSpacing) {
                    if hasConversation {
                        Button("进入群聊") {
                            onEnterChat()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    } else {
                        Button("查看资料") {
                            onViewOrg()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
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
                    Button("关闭") {
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
    var onSend: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected = Set<String>()

    private var candidates: [String] {
        let names: [String]
        switch target {
        case .circle:
            names = SampleData.circleBuddies.map(\.profile.nickname)
        case .guild:
            names = SampleData.paidCompanions.map(\.profile.nickname)
        }
        return names.uniqued()
    }

    private var title: String {
        switch target {
        case .circle(let c): "邀请加入「\(c.name)」"
        case .guild(let g): "邀请关注「\(g.name)」"
        }
    }

    var body: some View {
        NavigationStack {
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
                    Text("演示：发送后对方会收到邀请提示。")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发送") {
                        onSend(Array(selected))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selected.isEmpty)
                }
            }
        }
        .platformSheet(.browser)
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}
