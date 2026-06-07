// Module: SparkSearch — Person result detail from search.

import SparkDesignSystem
import SwiftUI

public struct SearchPersonProfileView: View {
    public let item: SearchResultItem
    public let onOpenMessages: ((String) -> Void)?

    public init(item: SearchResultItem, onOpenMessages: ((String) -> Void)? = nil) {
        self.item = item
        self.onOpenMessages = onOpenMessages
    }

    public var body: some View {
        SparkUnifiedIdentityContent(
            model: SparkUnifiedIdentityModel(
                id: item.id,
                displayName: item.title,
                bio: item.subtitle
            )
        ) {
            if let onOpenMessages {
                Button {
                    onOpenMessages(item.id)
                } label: {
                    Text(
                        String(
                            localized: "search.person.message",
                            defaultValue: "发消息",
                            comment: "Message person"
                        )
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle(
            String(localized: "search.person.title", defaultValue: "用户资料", comment: "Person profile title")
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SearchPersonProfileView(
            item: SearchResultItem(
                id: "u_1",
                title: "Alex",
                subtitle: "上海 · 徒步",
                kind: SearchResultKind.person.rawValue
            ),
            onOpenMessages: { _ in }
        )
    }
}
