//
//  WalletPassRecordFace.swift
//  坐标系
//
//  通行证详情票面：自动挂活动封面或搭子照片。
//

import SwiftUI
import CoordinateModels

/// 通行证详情用：自动挂活动封面或搭子照片。
struct WalletPassRecordFace: View {
    let pass: PassRecord

    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies
    @State private var showNavigationPicker = false
    @State private var showActivityDetail = false

    private var relatedActivity: Activity? {
        guard let related = pass.relatedID else { return nil }
        if let activity = activities.activity(id: related) { return activity }
        if let order = ActivityPaymentStore.order(id: related) {
            return activities.activity(id: order.activityID)
        }
        return nil
    }

    var body: some View {
        let content = enrichedContent
        WalletPassFace(
            content: content,
            photo: WalletPassFaceFactory.stripPhoto(
                for: pass,
                activities: activities,
                buddies: buddies
            ),
            fallbackSymbol: pass.style.systemImage,
            onNavigate: content.showsNavigateButton ? { showNavigationPicker = true } : nil,
            onOpenDetail: content.showsDetailButton && relatedActivity != nil
                ? { showActivityDetail = true }
                : nil
        )
        .navigationDestination(isPresented: $showActivityDetail) {
            if let activity = relatedActivity {
                ActivityDetailView(activityID: activity.id)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .activityMapNavigationSheet(
            activity: Binding(
                get: { showNavigationPicker ? relatedActivity : nil },
                set: { showNavigationPicker = $0 != nil }
            )
        )
    }

    /// 有关联活动时用实体日程格式覆盖 Pass 文案，保证「日期/星期/时间」一致。
    private var enrichedContent: WalletPassFaceContent {
        var content = WalletPassFaceFactory.fromPassRecord(pass)
        if let activity = relatedActivity {
            let blueprint = ActivityDetailBlueprint.make(for: activity)
            content.logoText = activity.title
            content.subtitleText = WalletPassFaceFactory.attendanceHint(for: activity)
            let schedule = WalletPassFaceFactory.scheduleFields(from: activity.date)
            content.headerLabel = schedule.label
            content.headerValue = schedule.value
            content.locationText = activity.location
            content.showsNavigateButton = !activity.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            content.showsDetailButton = true
            content.arrangementLines = WalletPassFaceFactory.arrangementLines(from: blueprint.timeline)
            content.detailNotes = WalletPassFaceFactory.detailNotes(from: blueprint)
            content.stripColor = WalletPassFaceFactory.stripColor(for: activity.category)
        }
        return content
    }
}

#Preview("Wallet pass faces") {
    ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 16) {
            WalletPassFace(
                content: WalletPassFaceFactory.activity(SampleData.activities[0]),
                photo: SampleData.activities[0].coverPhoto,
                onNavigate: {}
            )
            .frame(width: 220)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .platformChromeMeasurementsEnvironment()
}
