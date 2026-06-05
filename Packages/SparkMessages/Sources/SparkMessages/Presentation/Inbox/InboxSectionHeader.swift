// Module: SparkMessages — Section divider with optional unread count.

import SwiftUI

struct InboxSectionHeader: View {
    let title: String
    let systemImage: String
    let unreadCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            if unreadCount > 0 {
                UnreadBadge(count: unreadCount)
            }
        }
        .textCase(nil)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
    }
}
