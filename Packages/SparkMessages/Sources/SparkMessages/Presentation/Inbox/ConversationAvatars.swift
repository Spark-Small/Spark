// Module: SparkMessages — DM and group chat avatar stacks.

import SwiftUI

struct DMAvatar: View {
    let partner: InboxUserProfile?
    let displayName: String
    let isOnline: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            if isOnline {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().strokeBorder(.background, lineWidth: 2))
                    .offset(x: 2, y: 2)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(displayName)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let url = partner?.avatarURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    initialsPlaceholder
                }
            }
        } else {
            initialsPlaceholder
        }
    }

    private var initialsPlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Color.accentColor)
    }
}

struct GroupChatAvatar: View {
    let activity: InboxActivitySummary?
    let displayName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .frame(width: 48, height: 48)
            if let url = activity?.coverURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        groupIcon
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                groupIcon
            }
        }
        .accessibilityLabel(displayName)
    }

    private var groupIcon: some View {
        Image(systemName: "figure.hiking")
            .font(.title3)
            .foregroundStyle(Color.accentColor)
    }
}
