//
//  CommunityPostCard.swift
//  坐标系
//
//  信息流卡：点正文进详情；配图看大图；底栏唯一赞 / 评 / 分享 / 收藏。
//

import SwiftUI

struct CommunityPostCard: View {
    let post: CommunityPost

    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies

    @State private var authorDestination: CommunityAuthorDestination?
    @State private var photoDestination: CommunityPhotoDestination?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CommunityPostAuthorHeader(post: post) {
                authorDestination = buddies.authorDestination(for: post.author)
            }

            if !post.messageText.isEmpty {
                NavigationLink(value: post) {
                    CommunityPostFeedText(post: post)
                }
                .buttonStyle(.plain)
                .communityRowToContentSpacing()
            }

            if !post.displayPhotos.isEmpty {
                CommunityMediaPager(pageCount: post.displayPhotos.count) { index in
                    Button {
                        photoDestination = CommunityPhotoDestination(
                            photos: post.displayPhotos,
                            startIndex: index
                        )
                    } label: {
                        CommunityRemotePhoto(ref: post.displayPhotos[index])
                    }
                    .buttonStyle(.plain)
                }
                .communityRowToContentSpacing()
            } else if post.messageText.isEmpty {
                // 无正文无图时仍可进详情
                NavigationLink(value: post) {
                    Text("查看分享")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .communityRowToContentSpacing()
            }

            CommunityPostActionBar(post: post)
                .communityRowToContentSpacing()

            if let relatedActivity {
                CommunityRelatedActivityLink(activity: relatedActivity)
                    .communityRowToContentSpacing()
            }
        }
        .communityFeedCardTailSpacing()
        .communityAuthorSheet($authorDestination)
        .communityPhotoCover($photoDestination)
    }

    private var relatedActivity: Activity? {
        activities.activity(relatedTo: post)
    }
}
