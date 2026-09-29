//
//  ActivityDetailRelatedSections.swift
//  坐标系
//
//  活动详情：相关活动轨、俱乐部行、地点预览。
//

import MapKit
import SwiftUI
import CoordinateModels

// MARK: - 相关活动 / 凭证

/// Form 清单行：左 leading + 主副文（相关俱乐部入口等同构）
struct ActivityDetailFormLinkRow<Leading: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var leading: () -> Leading

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            leading()
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// 相关活动横滑轨：与「我的 · 最近浏览」同款跟进卡。
struct DetailRelatedActivitiesRail: View {
    let activities: [Activity]

    @Environment(ActivitiesModel.self) private var model
    @Environment(\.activityZoomNamespace) private var inheritedZoomNamespace
    @Namespace private var localZoomNamespace

    private var zoomNamespace: Namespace.ID {
        inheritedZoomNamespace ?? localZoomNamespace
    }

    var body: some View {
        DiscoverHorizontalRail {
            ForEach(activities) { activity in
                PlatformContinueCard(
                    activityID: activity.id,
                    zoomNamespace: zoomNamespace,
                    photo: activity.coverPhoto,
                    title: activity.title,
                    timeLine: Formatters.activityEventTime(from: activity.date),
                    metaLine: activity.districtLabel,
                    isJoined: model.isJoined(activity.id),
                    isFull: activity.isFull
                )
                .platformContinueRailFrame()
            }
        }
        .scrollClipDisabled()
        .platformFormRelatedRailRow()
    }
}

/// 活动详情 → 相关俱乐部推荐入口
struct ActivityDetailRelatedCircleRow: View {
    let circle: InterestCircle

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var subtitle: String {
        "\(circle.city) · \(circle.topic) · \(circle.memberCount) 人"
    }

    var body: some View {
        NavigationLink(value: CircleBrowseRoute.circle(circle)) {
            ActivityDetailFormLinkRow(title: circle.name, subtitle: subtitle) {
                Image(systemName: circle.systemImage)
                    .font(.title2)
                    .platformContentSymbolStyle()
                    .frame(
                        width: dynamicTypeSize.listAvatarSide,
                        height: dynamicTypeSize.listAvatarSide
                    )
                    .background(Color.accentColor.opacity(0.14), in: Circle())
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(circle.name)，\(subtitle)")
    }
}

struct ActivityDetailLocationPreview: View {
    let activity: Activity

    @ViewBuilder
    var body: some View {
        if let lat = activity.latitude, let lon = activity.longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            Map(initialPosition: .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
            ))) {
                Marker(activity.location, coordinate: coordinate)
            }
            .platformDetailMapPreview()
            .mapStyle(.standard(elevation: .realistic))
            .allowsHitTesting(false)
        }
    }
}

