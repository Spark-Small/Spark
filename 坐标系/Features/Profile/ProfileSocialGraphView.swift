//
//  ProfileSocialGraphView.swift
//  坐标系
//
//  互关 / 关注 / 粉丝：SwiftUI List + searchable；头像用可知边真图。
//

import SwiftUI
import CoordinateModels

struct ProfileSocialGraphView: View {
    let kind: ProfileSocialGraphKind

    @Environment(AppModel.self) private var app
    @Environment(MessagesModel.self) private var messages
    @Environment(BuddiesModel.self) private var buddies

    @State private var searchText = ""

    private var names: [String] {
        ProfileSocialStats.names(for: kind, app: app, messages: messages)
    }

    private var filteredNames: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return names }
        return names.filter { name in
            let display = messages.displayName(for: name)
            return name.localizedCaseInsensitiveContains(trimmed)
                || display.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        Group {
            if names.isEmpty {
                emptyContent
            } else if filteredNames.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .platformContentUnavailablePageChrome()
            } else {
                List {
                    Section {
                        ForEach(filteredNames, id: \.self) { name in
                            NavigationLink {
                                destination(for: name)
                            } label: {
                                ProfileSocialGraphRow(
                                    nickname: name,
                                    displayName: messages.displayName(for: name),
                                    photoRef: ProfileSocialAvatarResolver.photoRef(
                                        for: name,
                                        buddies: buddies
                                    )
                                )
                            }
                            .accessibilityHint(ProfileSocialCopy.openProfileHint)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if kind == .following || kind == .mutual {
                                    Button(ProfileSocialCopy.unfollow, role: .destructive) {
                                        if app.isFollowing(name) {
                                            app.toggleFollow(name)
                                        }
                                    }
                                }
                            }
                        }
                    } footer: {
                        Text(ProfileSocialCopy.footer(for: kind))
                    }
                }
                .profileSecondaryListChrome()
            }
        }
        .navigationTitle(kind.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: ProfileSocialCopy.searchPrompt
        )
    }

    private var emptyContent: some View {
        ProfileLibraryEmptyView(
            title: ProfileSocialCopy.emptyTitle(for: kind),
            systemImage: emptySymbol,
            description: ProfileSocialCopy.emptyDescription(for: kind)
        )
    }

    private var emptySymbol: String {
        switch kind {
        case .mutual: "person.2"
        case .following: "person.badge.plus"
        case .fans: "person.3"
        }
    }

    @ViewBuilder
    private func destination(for name: String) -> some View {
        if isFriend(name) {
            FriendProfileDetailView(nickname: name)
        } else {
            CommunityAuthorProfileView(name: name)
        }
    }

    private func isFriend(_ name: String) -> Bool {
        messages.conversations.contains {
            $0.isFriendChat
                && $0.isFriend
                && !$0.isMessageRequest
                && $0.title.caseInsensitiveCompare(name) == .orderedSame
        }
    }
}

private struct ProfileSocialGraphRow: View {
    let nickname: String
    let displayName: String
    var photoRef: CommunityPhotoRef? = nil

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if displayName.caseInsensitiveCompare(nickname) != .orderedSame {
                    Text(nickname)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        } icon: {
            PlatformListAvatarView(
                name: displayName,
                photoRef: photoRef,
                side: PlatformConversationListRow.imageSide
            )
        }
        .accessibilityElement(children: .combine)
    }
}
