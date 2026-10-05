//
//  BookingCredentialExpandedView.swift
//  坐标系
//
//  「我的」陪玩凭证展开页：票面头图 + 预约信息 / 联系 / 订单操作（原「管理预约」并入本页）。
//

import SwiftUI
import CoordinateFeatureFlags
import CoordinateModels

struct BookingCredentialExpandedView: View {
    let recordID: BuddyBookingRecord.ID

    // 跨文件 extension（+Fulfillment）需 internal，勿用 private。
    @Environment(BuddiesModel.self) var buddies
    @Environment(AppModel.self) var app
    @Environment(RefundFlowService.self) var refunds
    @Environment(WalletPassStore.self) var passStore
    @Environment(TrustService.self) var trust
    @Environment(\.dismiss) var dismiss

    @State var showReschedule = false
    @State var refundTarget: BuddyBookingRecord?
    @State var presentedRefundRequestID: UUID?
    @State var refundError: String?
    @State var confirmCancel = false
    @State var confirmDelete = false
    @State var peerContactRoute: PeerContactRoute?
    @State var showWriteReview = false
    @State var reviewDraft = ""
    @State var reviewRefreshToken = 0

    var record: BuddyBookingRecord? {
        buddies.bookingRecords.first { $0.id == recordID }
    }

    var relatedPass: PassRecord? {
        guard let record else { return nil }
        return passStore.resolvedBookingPass(for: record.id)
    }

    var coverPhoto: CommunityPhotoRef? {
        guard let record else { return nil }
        return buddies.item(for: record.companionNickname)?.profile.coverPhoto
    }

    var body: some View {
        Group {
            if let record {
                credentialForm(record)
            } else {
                ContentUnavailableView(
                    "预约不可用",
                    systemImage: "ticket",
                    description: Text("这张凭证关联的预约已无法加载。")
                )
                .onAppear { dismiss() }
            }
        }
        .navigationTitle(navigationTitle(for: record))
        .navigationBarTitleDisplayMode(.inline)
        .peerContactDestination(route: $peerContactRoute)
        .sheet(isPresented: $showReschedule) {
            if let record {
                BookingRescheduleSheet(record: record) { scheduledAt, hours in
                    buddies.rescheduleBooking(record.id, scheduledAt: scheduledAt, hours: hours)
                    showReschedule = false
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .sheet(item: $refundTarget) { target in
            RefundRequestSheet.booking(target) { reason, detail, _ in
                submitBookingRefund(target, reason: reason, detail: detail)
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .alert("无法退款", isPresented: Binding(
            get: { refundError != nil },
            set: { if !$0 { refundError = nil } }
        )) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(refundError ?? "")
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
        .alert("撤回预约？", isPresented: $confirmCancel) {
            Button(BuddyBookingFlowCopy.withdrawBooking, role: .destructive) {
                guard let record, record.canWithdraw else { return }
                buddies.withdrawPendingBooking(record.id)
            }
            Button("保留预约", role: .cancel) {}
        } message: {
            Text("撤回后无法恢复；已支付订单请通过「申请退款」处理。")
        }
        .alert("删除这条预约记录？", isPresented: $confirmDelete) {
            Button("删除记录", role: .destructive) {
                if let record {
                    buddies.deleteBooking(record.id)
                    dismiss()
                }
            }
            Button("保留记录", role: .cancel) {}
        } message: {
            Text("删除后无法恢复。")
        }
        .sheet(isPresented: $showWriteReview) {
            if let record,
               let target = buddies.companionReviewTarget(for: record) {
                PlatformReviewsWriteSheet(
                    target: target,
                    currentUserName: app.user.name,
                    draft: $reviewDraft,
                    replyTarget: .constant(nil),
                    title: PlatformReviewsCopy.writeReviewTitle,
                    placeholder: BuddyDetailCopy.reviewsComposerPlaceholder,
                    bookingID: record.id,
                    serviceTitle: buddies.companionReviewServiceTitle(for: record),
                    priceText: record.priceText,
                    showsIdentityPicker: true,
                    showsRatingPicker: true,
                    onChanged: { reviewRefreshToken += 1 }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
    }
}
