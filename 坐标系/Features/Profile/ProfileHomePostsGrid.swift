//
//  ProfileHomePostsGrid.swift
//  坐标系
//
//  「我的」发帖档：一帖一格三列（mediaShape 圆角，格缝 minContentGap）；点格进帖详情。空态见 ProfileHomeTabEmptyRegion。
//

import CoordinateModels
import SwiftUI

struct ProfileHomePostsGrid: View {
    @Environment(CommunityModel.self) private var community

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: PlatformMetrics.minContentGap),
        count: 3
    )

    private var posts: [CommunityPost] {
        ProfileHomeTabContent.posts(from: community)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: PlatformMetrics.minContentGap) {
            ForEach(posts) { post in
                NavigationLink(value: post) {
                    cell(for: post)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel(for: post))
            }
        }
        .discoverBrowseContentInset()
        .padding(.vertical, PlatformMetrics.minContentGap)
    }

    private func accessibilityLabel(for post: CommunityPost) -> String {
        let body = post.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        return body.isEmpty ? ProfileHomeContentCopy.postsTab : String(body.prefix(40))
    }

    private func cell(for post: CommunityPost) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let cover = post.coverPhoto {
                    CommunityRemotePhoto(ref: cover)
                } else {
                    textFallback(post)
                }
            }
            .clipShape(PlatformMetrics.mediaShape)
            .contentShape(PlatformMetrics.mediaShape)
            .overlay(alignment: .topTrailing) {
                if post.displayPhotos.count > 1 {
                    Image(systemName: "square.on.square")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(PlatformMetrics.profileMediaGlyphShadowOpacity),
                            radius: PlatformMetrics.profileMediaGlyphShadowRadius
                        )
                        .padding(PlatformMetrics.profileMediaGlyphInset)
                        .accessibilityHidden(true)
                }
            }
    }

    private func textFallback(_ post: CommunityPost) -> some View {
        let text = post.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        return ZStack {
            Rectangle().fill(PlatformSurface.tertiaryFill)
            Text(text.isEmpty ? ProfileHomeContentCopy.textPostPlaceholder : text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .padding(PlatformMetrics.minContentGap)
        }
    }
}
