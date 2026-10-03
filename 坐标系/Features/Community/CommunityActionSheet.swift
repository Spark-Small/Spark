//
//  CommunityActionSheet.swift
//  坐标系
//
//  帖子互动 Sheet 路由枚举。
//

import SwiftUI
import CoordinateModels

enum CommunityActionSheet: String, Identifiable {
    case comments
    case share
    case bookmark

    var id: String { rawValue }

    @MainActor
    @ViewBuilder
    func sheet(postID: CommunityPost.ID) -> some View {
        switch self {
        case .comments:
            CommunityCommentsSheet(postID: postID)
        case .share:
            CommunityShareSheet(postID: postID)
        case .bookmark:
            CommunityBookmarkSheet(postID: postID)
        }
    }
}
