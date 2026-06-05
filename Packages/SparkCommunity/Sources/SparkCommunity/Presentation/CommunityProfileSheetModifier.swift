// Module: SparkCommunity — Shared profile sheet presentation.

import SwiftUI

extension View {
    func communityProfileSheet(
        preview: Binding<CommunityProfilePreview?>,
        likedPersonIDs: Set<String>,
        onLike: @escaping (String) -> Void
    ) -> some View {
        sheet(item: preview) { item in
            CommunityMemberProfileSheet(
                profile: item,
                isLiked: likedPersonIDs.contains(item.id) || item.relationship == .liked,
                onLike: { onLike(item.id) }
            )
        }
    }
}
