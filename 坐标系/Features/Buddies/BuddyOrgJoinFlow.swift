//
//  BuddyOrgJoinFlow.swift
//  坐标系
//
//  兴趣组织加入链路：确认 → 成功（进群）→ 邀请成员。
//

import SwiftUI

struct BuddyOrgJoinConfirmSheet: View {
    let target: BuddyOrgJoinTarget
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var name: String {
        switch target {
        case .circle(let c): c.name
        case .guild(let g): g.name
        }
    }

    private var subtitle: String {
        switch target {
        case .circle(let c): "\(c.city) · \(c.topic) · \(c.memberCount) 人"
        case .guild(let g): "\(g.city) · \(g.specialty) · \(g.priceFromText)"
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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: PlatformMetrics.cardInfoSpacing) {
                        Image(systemName: systemImage)
                            .font(.largeTitle)
                            .platformSymbolStyle(.multicolor)
                            .frame(width: 72, height: 72)
                            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        Text(name)
                            .font(.title3.weight(.bold))
                            .multilineTextAlignment(.center)

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
                }

                Section("组织说明") {
                    Text(summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Label("加入后进入组织群聊，可看成员与公告", systemImage: "bubble.left.and.bubble.right")
                        .platformContentSymbolStyle()
                        .font(.subheadline)
                    Label("可随时在组织资料或消息里退出", systemImage: "arrow.uturn.backward")
                        .platformContentSymbolStyle()
                        .font(.subheadline)
                } footer: {
                    Text("本地演示：加入状态与群聊会保存在本机。")
                }
            }
            .navigationTitle("加入组织")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认加入") {
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
    var onInvite: () -> Void
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: PlatformMetrics.sectionSpacing) {
                Spacer(minLength: 12)

                Image(systemName: success.systemImage)
                    .font(.system(size: 44))
                    .platformSymbolStyle(.multicolor)

                Text("已加入组织")
                    .font(.title2.weight(.bold))

                Text("「\(success.name)」")
                    .font(.headline)

                Text(
                    hasConversation
                        ? "组织群聊已就绪。可先打个招呼，或稍后再从消息 · 群聊进入。"
                        : "可在「我的 · 我的圈子」里找到它，也可邀请同好一起加入。"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    if hasConversation {
                        Button("进入群聊") {
                            onEnterChat()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    if hasConversation {
                        Button("查看组织资料") {
                            onViewOrg()
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    } else {
                        Button("查看资料") {
                            onViewOrg()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    Button("邀请成员") {
                        onInvite()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button("完成") {
                        onDone()
                        dismiss()
                    }
                    .buttonStyle(.borderless)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, PlatformMetrics.contentInset)
                .padding(.bottom, 8)
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
