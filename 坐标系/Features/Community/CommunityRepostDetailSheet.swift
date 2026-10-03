//
//  CommunityRepostDetailSheet.swift
//  坐标系
//

import SwiftUI
import CoordinateModels

struct CommunityRepostDetailSheet: View {
    let originalID: CommunityPost.ID
    @Environment(CommunityModel.self) private var model

    private var original: CommunityPost? { model.post(id: originalID) }
    private var myReposts: [CommunityPost] {
        model.posts.filter { $0.repostedFromID == originalID && $0.author == model.currentUserName }
    }

    var body: some View {
        MessagesFormSheet(title: CommunitySheetCopy.repostDetailTitle) {
            List {
                if let original {
                    Section(CommunitySheetCopy.originalSection) {
                        Text(original.messageText).font(PlatformListTypography.body)
                        Text(Formatters.conversationListTime(from: original.postedAt))
                            .font(PlatformListTypography.footnote)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .accessibilityLabel(
                                CommunityEngagementCopy.postedAtAccessibility(
                                    Formatters.conversationListTime(from: original.postedAt)
                                )
                            )
                    }
                }
                Section(CommunitySheetCopy.myRepostsSection) {
                    if myReposts.isEmpty {
                        Text(CommunitySheetCopy.myRepostsEmpty).foregroundStyle(.secondary)
                    } else {
                        ForEach(myReposts) { post in
                            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                                Text(post.messageText).font(PlatformListTypography.secondary)
                                Text(Formatters.conversationListTime(from: post.postedAt))
                                    .font(PlatformListTypography.footnote)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                    .accessibilityLabel(
                                        CommunityEngagementCopy.postedAtAccessibility(
                                            Formatters.conversationListTime(from: post.postedAt)
                                        )
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
}
