//
//  HostInsightsView.swift
//  坐标系
//
//  主办表现：仅展示主办活动域的报名与评论指标。
//  从「我的活动 > 我发起的」进入。
//

import SwiftUI

struct HostInsightsView: View {
    @Environment(ActivitiesModel.self) private var activities

    private var snapshot: CreatorInsightsSnapshot {
        CreatorInsightsService.activityOnlySnapshot(activities: activities)
    }

    var body: some View {
        List {
            Section {
                LabeledContent("发起活动", value: "\(snapshot.activities.count)")
                LabeledContent("总报名", value: "\(snapshot.totalJoined)")
                LabeledContent("总评论", value: "\(snapshot.totalActivityComments)")
            } header: {
                Text("主办表现")
            } footer: {
                Text("基于本机报名与评论统计，正式版将接入云端数据。")
            }

            if !snapshot.activities.isEmpty {
                Section("活动明细") {
                    ForEach(snapshot.activities) { item in
                        NavigationLink(value: item.activity) {
                            PlatformListTextColumn(
                                primary: item.activity.title,
                                secondary: Formatters.activityEventTime(from: item.activity.date),
                                footnote: item.metricLine
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .navigationTitle("主办表现")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .navigationDestination(for: Activity.self) { activity in
            ActivityDetailView(activity: activity)
        }
    }
}
