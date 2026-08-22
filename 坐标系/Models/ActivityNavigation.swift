//
//  ActivityNavigation.swift
//  坐标系
//
//  一键调起系统 / 第三方导航到活动地点。
//

import MapKit
import SwiftUI
import UIKit

enum ActivityNavigation {
    /// 在系统地图中打开驾车路线；无坐标时用地址搜索。
    static func openInAppleMaps(_ activity: Activity) {
        if let lat = activity.latitude, let lon = activity.longitude {
            let destination = MKMapItem(
                location: CLLocation(latitude: lat, longitude: lon),
                address: nil
            )
            destination.name = activity.location
            destination.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = activity.location
        Task {
            guard let item = try? await MKLocalSearch(request: request).start().mapItems.first else {
                openAppleMapsSearchURL(activity.location)
                return
            }
            item.name = activity.location
            item.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        }
    }

    /// 高德地图（未安装则回退苹果地图）
    static func openInAmap(_ activity: Activity) {
        var components = URLComponents(string: "iosamap://path")
        components?.queryItems = [
            .init(name: "sourceApplication", value: "坐标系"),
            .init(name: "dname", value: activity.location),
            .init(name: "dev", value: "0"),
            .init(name: "t", value: "0")
        ]
        if let lat = activity.latitude, let lon = activity.longitude {
            components?.queryItems?.append(contentsOf: [
                .init(name: "dlat", value: String(lat)),
                .init(name: "dlon", value: String(lon))
            ])
        }
        open(components?.url, fallback: activity)
    }

    /// 百度地图（未安装则回退苹果地图）
    static func openInBaiduMaps(_ activity: Activity) {
        var destination = "name:\(activity.location)"
        if let lat = activity.latitude, let lon = activity.longitude {
            destination = "latlng:\(lat),\(lon)|\(destination)"
        }
        var components = URLComponents(string: "baidumap://map/direction")
        components?.queryItems = [
            .init(name: "destination", value: destination),
            .init(name: "mode", value: "driving"),
            .init(name: "coord_type", value: "gcj02")
        ]
        open(components?.url, fallback: activity)
    }

    private static func open(_ url: URL?, fallback activity: Activity) {
        guard let url else {
            openInAppleMaps(activity)
            return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                openInAppleMaps(activity)
            }
        }
    }

    private static func openAppleMapsSearchURL(_ query: String) {
        var components = URLComponents(string: "http://maps.apple.com/")
        components?.queryItems = [
            .init(name: "daddr", value: query),
            .init(name: "dirflg", value: "d")
        ]
        guard let url = components?.url else { return }
        UIApplication.shared.open(url)
    }
}

/// 底部 Sheet：选择 Apple / 高德 / 百度地图导航到活动地点。
/// 呈现遵循 `PlatformSheetKind.navigationPicker`（系统 `.medium` 单档 + inset 列表）。
struct ActivityNavigationPickerSheet: View {
    let activity: Activity

    @Environment(\.dismiss) private var dismiss

    private struct MapApp: Identifiable {
        let id: String
        let title: String
        let systemImage: String
        let open: (Activity) -> Void
    }

    private var apps: [MapApp] {
        [
            MapApp(id: "apple", title: "Apple 地图", systemImage: "map", open: ActivityNavigation.openInAppleMaps),
            MapApp(id: "amap", title: "高德地图", systemImage: "map.fill", open: ActivityNavigation.openInAmap),
            MapApp(id: "baidu", title: "百度地图", systemImage: "map.fill", open: ActivityNavigation.openInBaiduMaps),
        ]
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent(ActivityDetailCopy.navigationAddressField) {
                        Text(activity.location)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    ForEach(apps) { app in
                        Button {
                            dismiss()
                            app.open(activity)
                        } label: {
                            Label(app.title, systemImage: app.systemImage)
                                .labelStyle(.titleAndIcon)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(ActivityDetailCopy.navigationSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .platformSheet(.navigationPicker)
    }
}

extension View {
    /// 底部 Sheet：选择地图 App 导航到活动地点。
    func activityMapNavigationSheet(activity: Binding<Activity?>) -> some View {
        sheet(item: activity) { target in
            ActivityNavigationPickerSheet(activity: target)
        }
    }
}
