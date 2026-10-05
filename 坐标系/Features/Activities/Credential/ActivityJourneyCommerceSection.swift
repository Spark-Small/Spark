//
//  ActivityJourneyCommerceSection.swift
//  坐标系
//
//  活动行程商务条 UI：Discover Section + LabeledContent（无 elevated 卡）。
//

import SwiftUI
import CoordinateModels

@MainActor
struct ActivityJourneyCommerceSection: View {
    let model: ActivityJourneyCommerceModel
    let onAction: (ActivityJourneyCommerceAction) -> Void

    var body: some View {
        DiscoverBrowseSection {
            DiscoverSectionTitleRow(
                title: ActivityJourneyCopy.commerceSectionTitle,
                showsHorizontalInset: false
            )
        } content: {
            VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
                LabeledContent(model.statusLine, value: model.amountLine)

                if !model.actions.isEmpty {
                    HStack(spacing: PlatformMetrics.cardFooterSpacing) {
                        ForEach(Array(model.actions.enumerated()), id: \.offset) { _, item in
                            Button(item.title, systemImage: item.systemImage) {
                                onAction(item.action)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
