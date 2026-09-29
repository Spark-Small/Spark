//
//  PlatformReviewsHeaderFilter.swift
//  坐标系
//
//  评价区标题与筛选条。
//

import SwiftUI

// MARK: - Header / Filter

struct PlatformReviewsHeader: View {
    let count: Int
    var title: (Int) -> String = BuddyDetailCopy.reviewsTitleCount

    var body: some View {
        Text(title(count))
            .textCase(nil)
            .accessibilityAddTraits(.isHeader)
    }
}

struct PlatformReviewFilterBar: View {
    @Binding var filter: PlatformReviewFilter
    let stats: PlatformReviewStats

    var body: some View {
        Picker("筛选", selection: $filter) {
            Text("全部 \(stats.total)").tag(PlatformReviewFilter.all)
            Text("好评 \(stats.positive)").tag(PlatformReviewFilter.positive)
            Text("有图 \(stats.withPhotos)").tag(PlatformReviewFilter.withPhotos)
            Text(PlatformReviewFilter.latest.rawValue).tag(PlatformReviewFilter.latest)
        }
        .pickerStyle(.menu)
        .accessibilityLabel("评价筛选")
    }
}
