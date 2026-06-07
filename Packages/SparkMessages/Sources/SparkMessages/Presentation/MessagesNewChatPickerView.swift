// Module: SparkMessages — Pick a peer to start a direct message thread.

import SparkDesignSystem
import SwiftUI

struct MessagesNewChatPickerView: View {
    @Environment(PeerDisplayNameStore.self) private var peerDisplayNameStore

    let candidates: [MessagesChatCandidate]
    let onSelect: (MessagesChatCandidate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredCandidates: [MessagesChatCandidate] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return candidates }
        return candidates.filter {
            let resolved = peerDisplayNameStore.resolvedDisplayName(
                userID: $0.id,
                fallback: $0.displayName
            )
            return resolved.localizedStandardContains(query)
                || $0.displayName.localizedStandardContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if candidates.isEmpty {
                    emptyState
                } else {
                    candidateList
                }
            }
            .navigationTitle(
                String(
                    localized: "messages.newChat.title",
                    defaultValue: "发起聊天",
                    comment: "New chat picker title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: String(
                    localized: "messages.newChat.search",
                    defaultValue: "搜索好友",
                    comment: "Search chat candidates"
                )
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var candidateList: some View {
        List {
            if filteredCandidates.isEmpty {
                ContentUnavailableView(
                    String(
                        localized: "messages.newChat.noResults",
                        defaultValue: "没有匹配的好友",
                        comment: "No search results"
                    ),
                    systemImage: "magnifyingglass",
                    description: Text(
                        String(
                            localized: "messages.newChat.noResults.hint",
                            defaultValue: "换个关键词试试",
                            comment: "No search results hint"
                        )
                    )
                )
            } else {
                ForEach(filteredCandidates) { candidate in
                    Button {
                        onSelect(candidate)
                    } label: {
                        candidateRow(candidate)
                    }
                    .buttonStyle(.sparkPressable)
                }
            }
        }
        .sparkScreenListStyle()
    }

    private func candidateRow(_ candidate: MessagesChatCandidate) -> some View {
        let displayName = peerDisplayNameStore.resolvedDisplayName(
            userID: candidate.id,
            fallback: candidate.displayName
        )
        return HStack(spacing: 14) {
            ConversationHeaderAvatar(
                imageURL: candidate.avatarURL,
                displayName: displayName,
                placeholderSystemImage: "person.circle.fill"
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                if candidate.isNewMatch {
                    Text(
                        String(
                            localized: "messages.newChat.newMatch",
                            defaultValue: "新配对",
                            comment: "New match badge"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, SparkLayoutMetrics.inboxRowVerticalPadding)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                String(
                    localized: "messages.newChat.empty.title",
                    defaultValue: "暂无可聊好友",
                    comment: "Empty new chat picker"
                ),
                systemImage: "person.2"
            )
        } description: {
            Text(
                String(
                    localized: "messages.newChat.empty.subtitle",
                    defaultValue: "配对成功后可以在这里发起聊天",
                    comment: "Empty new chat picker hint"
                )
            )
        }
    }
}

#Preview("New chat — candidates") {
    MessagesNewChatPickerView(
        candidates: [
            MessagesChatCandidate(id: "u_1", displayName: "小雨", isNewMatch: true),
            MessagesChatCandidate(id: "u_2", displayName: "Alex", isNewMatch: false)
        ],
        onSelect: { _ in }
    )
    .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
}

#Preview("New chat — empty") {
    MessagesNewChatPickerView(
        candidates: [],
        onSelect: { _ in }
    )
    .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
}
