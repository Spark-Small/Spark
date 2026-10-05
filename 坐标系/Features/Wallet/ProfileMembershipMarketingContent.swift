//
//  ProfileMembershipMarketingContent.swift
//  坐标系
//
//  SubscriptionStoreView 营销头：系统排版；水平页边交给 StoreKit，勿再叠 contentInset。
//

import SwiftUI

struct ProfileMembershipMarketingContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(ProfileMembershipCopy.brandTitle)
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text(ProfileMembershipCopy.tagline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                ForEach(ProfileMembershipCopy.marketingBenefits, id: \.title) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .font(.body)
                        .platformContentSymbolStyle()
                }
            }
            .padding(.top, PlatformMetrics.sectionHeaderSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
    }
}
