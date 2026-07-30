//
//  BuddySharedViews.swift
//  坐标系
//

import SwiftUI

struct TagFlow: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PlatformMetrics.minContentGap) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .platformGlassTag()
                }
            }
        }
    }
}

struct BuddyReviewRow: View {
    let review: BuddyReview

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(review.author)
                    .font(.body)
                Spacer(minLength: 0)
                Label {
                    Text("\(review.rating)")
                } icon: {
                    Image(systemName: "star.fill")
                        .platformSymbolStyle(.status(PlatformStatus.warning))
                }
                    .font(.subheadline)
                Text(review.dateText)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            Text(review.comment)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct BuddyDetailActionBar: View {
    var inviteEnabled = true
    var inviteTitle = BuddyDetailCopy.invite
    /// 工会 / 语音厅入口：预约按钮带系统图标，强调转化
    var emphasizeInvite = false
    var onGreet: () -> Void
    var onInvite: () -> Void

    var body: some View {
        HStack {
            Button(BuddyDetailCopy.greet, action: onGreet)
                .activityDetailBottomSecondaryCTA()

            if emphasizeInvite {
                Button(action: onInvite) {
                    Label(inviteTitle, systemImage: "calendar.badge.clock")
                }
                .activityDetailBottomPrimaryCTA()
                .disabled(!inviteEnabled)
            } else {
                Button(inviteTitle, action: onInvite)
                    .activityDetailBottomPrimaryCTA()
                    .disabled(!inviteEnabled)
            }
        }
        .activityDetailBottomBarChrome()
    }
}
