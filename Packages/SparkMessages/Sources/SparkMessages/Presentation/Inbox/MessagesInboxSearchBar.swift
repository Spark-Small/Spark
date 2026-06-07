// Module: SparkMessages — Inbox search field (first row of conversation List).

import SparkDesignSystem
import SwiftUI

/// First row inside the inbox `List` — scrolls with conversation rows, separate from toolbar segment.
struct MessagesInboxSearchBar: View {
    @Binding var text: String
    let segment: MessagesInboxSegment
    @FocusState private var isFocused: Bool

    private var prompt: String {
        switch segment {
        case .dm:
            String(
                localized: "messages.inbox.search.prompt.dm",
                defaultValue: "搜索消息",
                comment: "Inbox DM search prompt"
            )
        case .groupChats:
            String(
                localized: "messages.inbox.search.prompt.groups",
                defaultValue: "搜索群聊",
                comment: "Inbox group search prompt"
            )
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .submitLabel(.search)
                .accessibilityLabel(prompt)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.sparkPressable)
                .sparkMinimumTouchTarget()
                .accessibilityLabel(
                    String(
                        localized: "messages.inbox.search.clear.a11y",
                        defaultValue: "清除搜索",
                        comment: "Clear inbox search"
                    )
                )
            }
        }
        .padding(.horizontal, SparkLayoutMetrics.composerFieldHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.composerFieldVerticalPadding)
        .sparkGlassControl(Capsule())
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        .sparkFlatTabRowBackground()
    }
}

#Preview("Messages inbox search bar") {
    @Previewable @State var query = ""
    List {
        MessagesInboxSearchBar(text: $query, segment: .dm)
            .sparkInboxSearchListRow()
        Text("Conversation row")
            .sparkFlatTabListRow()
    }
    .sparkFlatTabListStyle()
}
