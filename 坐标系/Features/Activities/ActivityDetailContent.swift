//
//  ActivityDetailContent.swift
//  坐标系
//
//  活动详情页壳：Form + 转场 / Sheet / 底栏挂载（分区见 +FormSections，顶栏底栏见 +Chrome）。
//

import SwiftUI
import CoordinateModels

extension ActivityDetailView {
    // MARK: - Content

    func detailContent(_ live: Activity) -> some View {
        let blueprint = ActivityDetailBlueprint.make(for: live)

        return Form {
            Section {
                hero(live)
                    .id(contentRevision)
                    .platformFullBleedMediaFormRow()
            }

            detailFormSections(live, blueprint: blueprint)
        }
        // 分区间距 / 顶边距交给系统语义，不叠自定义 pt
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationTitle(live.title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: live.id) {
            guard !revealsSecondaryContent else { return }
            await Task.yield()
            try? await Task.sleep(for: ActivityZoomEngagement.postTransitionDelay)
            guard !Task.isCancelled else { return }
            revealsSecondaryContent = true
        }
        .toolbar {
            activityDetailToolbar(for: live)
        }
        // Form 头图落在系统顶栏下方；边缘过渡交给 scrollEdgeEffect
        .toolbarBackground(.hidden, for: .navigationBar)
        .inspector(isPresented: $showDetailInspector) {
            ActivityDetailSideInspector(
                activity: live,
                related: ActivityRelatedRecommender.related(to: live, from: model.activities),
                onOpenPeople: { showPeopleSheet = true }
            )
        }
        .inspectorColumnWidth(min: 280, ideal: 320, max: 400)
        .onAppear {
            if horizontalSizeClass == .regular {
                showDetailInspector = true
            }
        }
        .onChange(of: horizontalSizeClass) { _, sizeClass in
            showDetailInspector = sizeClass == .regular
        }
        .onChange(of: model.joinedIDs) { _, _ in
            contentRevision += 1
        }
        .onChange(of: model.isWaitlisted(live.id)) { _, _ in
            contentRevision += 1
        }
        .peerContactDestination(route: $activityContactRoute)
        .sheet(isPresented: $showPeopleSheet) {
            ActivityDetailPeopleSheet(activity: live)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showJoinConfirm) {
            ActivityJoinConfirmSheet(
                activity: live,
                conflicts: model.scheduleConflicts(with: live),
                promotionMode: joinConfirmWaitlistPromotion ? .waitlist : .standard
            ) { note in
                completeJoin(for: live, note: note)
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .onChange(of: showJoinConfirm) { _, isPresented in
            if !isPresented {
                joinConfirmWaitlistPromotion = false
            }
        }
        .sheet(isPresented: $showContentEditor) {
            ActivityDetailContentEditorSheet(activity: live) {
                contentRevision += 1
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showOrders) {
            ActivityOrdersSheet(activityID: live.id) {
                ordersRevision += 1
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .alert(
            ActivityDetailCopy.cancelWithRefundTitle,
            isPresented: Binding(
                get: { cancelRefundActivityID != nil },
                set: { if !$0 { cancelRefundActivityID = nil } }
            )
        ) {
            Button("暂不取消", role: .cancel) {
                cancelRefundActivityID = nil
            }
            Button(ActivityDetailCopy.cancelOnly) {
                if let id = cancelRefundActivityID,
                   app.cancelActivityRegistration(id, refundIfPaid: false) {
                    cancelFeedbackMessage = ActivityFeedbackCopy.unjoined
                }
                cancelRefundActivityID = nil
            }
            Button(ActivityDetailCopy.cancelWithRefundConfirm, role: .destructive) {
                if let id = cancelRefundActivityID,
                   let order = ActivityPaymentStore.paidOrder(for: id) {
                    cancelAndRefundOrder = order
                }
                cancelRefundActivityID = nil
            }
        } message: {
            Text(ActivityDetailCopy.cancelWithRefundMessage)
        }
        .alert(
            ActivityDetailCopy.cancelUnpaidTitle,
            isPresented: Binding(
                get: { cancelUnpaidActivityID != nil },
                set: { if !$0 { cancelUnpaidActivityID = nil } }
            )
        ) {
            Button(ActivityDetailCopy.cancelUnpaidKeep, role: .cancel) {
                cancelUnpaidActivityID = nil
            }
            Button(ActivityDetailCopy.cancelUnpaidConfirm, role: .destructive) {
                if let id = cancelUnpaidActivityID,
                   app.cancelActivityRegistration(id) {
                    cancelFeedbackMessage = ActivityFeedbackCopy.unjoined
                }
                cancelUnpaidActivityID = nil
            }
        } message: {
            Text(ActivityDetailCopy.cancelUnpaidMessage)
        }
        .sheet(item: $cancelAndRefundOrder) { order in
            let activity = model.activity(id: order.activityID)
            let notes = activity.map { ActivityDetailBlueprint.make(for: $0).refundNotes } ?? []
            RefundRequestSheet.activityOrder(order, activity: activity, refundNotes: notes) { reason, detail, _ in
                submitCancelAndRefund(order: order, reason: reason, detail: detail)
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: Binding(
            get: { presentedRefundRequestID != nil },
            set: { if !$0 { presentedRefundRequestID = nil } }
        )) {
            if let requestID = presentedRefundRequestID {
                RefundStatusSheet(requestID: requestID)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .platformDetailBottomBar {
            bottomBar(live)
        }
        .sheet(isPresented: $showCommentsSheet) {
            ActivityCommentsSheet(
                activityID: live.id,
                hostName: live.hostName,
                currentUserName: model.currentUserName,
                onChanged: {
                    commentsRevision += 1
                }
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
    }
}
