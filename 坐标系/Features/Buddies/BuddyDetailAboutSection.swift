//
//  BuddyDetailAboutSection.swift
//  坐标系
//
//  详情 Form：推荐理由（纯文）→ 兴趣爱好（纯胶囊）。
//

import SwiftUI
import CoordinateModels

struct BuddyDetailAboutSection: View {
    let profile: BuddyProfile

    private var reason: String { BuddyMatchScorer.reason(for: profile) }
    private var hobbies: [String] { profile.tags }

    var body: some View {
        Section {
            Text(reason)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } header: {
            Text(BuddyDetailCopy.reasonTitle)
        }

        if !hobbies.isEmpty {
            Section {
                PlatformFlowLayout(spacing: PlatformMetrics.inlineControlSpacing) {
                    ForEach(hobbies, id: \.self) { tag in
                        InterestCapsuleChip.readOnlyTag(tag)
                    }
                }
            } header: {
                Text(BuddyDetailCopy.interestsTitle)
            }
        }
    }
}
