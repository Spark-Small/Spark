// Module: SparkMessages — Peer profile from DM conversation context.

import SparkDesignSystem
import SwiftUI

@available(*, deprecated, message: "Use SparkProfile.UserContextSheet via onOpenUserProfile from the app shell.")
public struct ConversationPeerProfileView: View {
    @Environment(PeerDisplayNameStore.self) private var peerDisplayNameStore

    let peerUserID: String
    let peerDisplayName: String
    let context: ConversationContext?
    var onOpenActivity: ((String) -> Void)?
    var onProposeMeetup: (() -> Void)?

    @State private var remarkDraft: String = ""
    @FocusState private var isRemarkFocused: Bool

    public init(
        peerUserID: String,
        peerDisplayName: String,
        context: ConversationContext?,
        onOpenActivity: ((String) -> Void)? = nil,
        onProposeMeetup: (() -> Void)? = nil
    ) {
        self.peerUserID = peerUserID
        self.peerDisplayName = peerDisplayName
        self.context = context
        self.onOpenActivity = onOpenActivity
        self.onProposeMeetup = onProposeMeetup
    }

    private var resolvedDisplayName: String {
        peerDisplayNameStore.resolvedDisplayName(userID: peerUserID, fallback: peerDisplayName)
    }

    public var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Circle()
                        .frame(width: 72, height: 72)
                        .sparkGlassControl(Circle())
                        .overlay {
                            Text(String(resolvedDisplayName.prefix(1)))
                                .font(.title.weight(.semibold))
                        }
                    Text(resolvedDisplayName)
                        .font(.title3.weight(.semibold))
                    if resolvedDisplayName != peerDisplayName {
                        Text(
                            String(
                                format: String(
                                    localized: "messages.peer.originalName.format",
                                    defaultValue: "昵称：%@",
                                    comment: "Original display name; %@ is name"
                                ),
                                locale: .current,
                                peerDisplayName
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    if let status = relationshipLabel {
                        Text(status)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section(
                String(
                    localized: "messages.peer.remark.section",
                    defaultValue: "备注",
                    comment: "Peer remark section"
                )
            ) {
                TextField(
                    String(
                        localized: "messages.peer.remark.placeholder",
                        defaultValue: "添加备注名",
                        comment: "Remark placeholder"
                    ),
                    text: $remarkDraft
                )
                .focused($isRemarkFocused)
                .submitLabel(.done)
                .onSubmit(saveRemark)
                .onChange(of: remarkDraft) { _, newValue in
                    saveRemarkIfNeeded(newValue)
                }
            }

            if onProposeMeetup != nil {
                Section(
                    String(
                        localized: "messages.peer.meetup.section",
                        defaultValue: "一起见面",
                        comment: "Propose meetup section"
                    )
                ) {
                    Button(action: { onProposeMeetup?() }) {
                        Label(
                            String(
                                localized: "messages.peer.proposeCoffee",
                                defaultValue: "约咖啡小局",
                                comment: "Propose coffee meetup after match"
                            ),
                            systemImage: "cup.and.saucer.fill"
                        )
                    }
                    .buttonStyle(.sparkPressable)
                }
            }

            if let activities = context?.sharedActivities, !activities.isEmpty {
                Section(
                    String(
                        localized: "messages.peer.sharedActivities",
                        defaultValue: "共同活动",
                        comment: "Shared activities section"
                    )
                ) {
                    ForEach(activities) { activity in
                        Button {
                            onOpenActivity?(activity.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activity.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(activity.countdownText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.sparkPressable)
                    }
                }
            }
        }
        .sparkScreenListStyle()
        .navigationTitle(
            String(localized: "messages.peer.profile.title", defaultValue: "资料", comment: "Peer profile title")
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            remarkDraft = peerDisplayNameStore.alias(for: peerUserID) ?? ""
        }
        .onDisappear {
            saveRemarkIfNeeded(remarkDraft)
        }
    }

    private var relationshipLabel: String? {
        guard let status = context?.relationshipStatus, status != "none" else { return nil }
        switch status {
        case "matched":
            return String(localized: "messages.peer.matched", defaultValue: "互相喜欢", comment: "Matched status")
        case "friend":
            return String(localized: "messages.peer.friend", defaultValue: "好友", comment: "Friend status")
        default:
            return status
        }
    }

    private func saveRemark() {
        saveRemarkIfNeeded(remarkDraft)
        isRemarkFocused = false
    }

    private func saveRemarkIfNeeded(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let existing = peerDisplayNameStore.alias(for: peerUserID) ?? ""
        guard trimmed != existing else { return }
        peerDisplayNameStore.setAlias(trimmed.isEmpty ? nil : trimmed, for: peerUserID)
    }
}

#Preview {
    NavigationStack {
        ConversationPeerProfileView(
            peerUserID: "u_like_1",
            peerDisplayName: "小雨",
            context: ConversationContext(
                sharedActivities: [
                    InboxActivitySummary(
                        id: "act_1",
                        title: "周末徒步",
                        startsAt: Date().addingTimeInterval(86_400),
                        attendeeCount: 8
                    )
                ],
                relationshipStatus: "matched"
            )
        )
        .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
    }
}
