//
//  BookingCredentialExpandedView+Fulfillment.swift
//  坐标系
//
//  陪玩凭证：履约 / 票面 / 联系与订单操作（商务条见 +Commerce）。
//

import SwiftUI
import CoordinateFeatureFlags
import CoordinateModels

extension BookingCredentialExpandedView {

    @ViewBuilder
    func credentialForm(_ record: BuddyBookingRecord) -> some View {
        let schedule = WalletPassFaceFactory.scheduleFields(from: record.scheduledAt)
        let isVoided = relatedPass?.voided == true
        let statusText = isVoided ? "已作废" : record.statusLabel
        let _ = reviewRefreshToken

        Form {
            commerceSections(for: record)

            if record.canComplete || record.canMarkInProgress {
                Section {
                    if record.canComplete {
                        Button {
                            buddies.completeBooking(record.id)
                        } label: {
                            Label(
                                BuddyBookingFlowCopy.confirmServiceCompleted,
                                systemImage: "checkmark.circle"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .listRowInsets(EdgeInsets())
                    }
                    if record.canMarkInProgress {
                        Button {
                            buddies.markInProgress(record.id)
                        } label: {
                            Label(
                                BuddyBookingFlowCopy.markServiceStarted,
                                systemImage: "play.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                } footer: {
                    Text(BuddyBookingFlowCopy.fulfillmentSectionFooter)
                }
            }

            Section {
                ProfileBookingCredentialCard(
                    record: record,
                    photo: coverPhoto,
                    voided: isVoided,
                    embedsNotes: false,
                    embedsHeader: false
                )
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                    Text(record.companionNickname)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            isVoided ? Color.secondary : bookingStatusColor(record.status)
                        )
                }
                .accessibilityElement(children: .combine)

                LabeledContent("费用", value: record.priceText)
                LabeledContent("时间", value: schedule.label)
                LabeledContent("日期", value: schedule.value)
                LabeledContent("时长", value: "\(record.hours) 小时")
                if let slot = record.selectedSlotLabel, !slot.isEmpty {
                    LabeledContent("档期", value: slot)
                }
            }

            Section("订单记录") {
                LabeledContent(
                    "下单",
                    value: Formatters.activityDate.string(from: record.bookedAt)
                )
                if let paidAt = record.paidAt {
                    LabeledContent(
                        "支付",
                        value: Formatters.activityDate.string(from: paidAt)
                    )
                }
                if let completedAt = record.completedAt {
                    LabeledContent(
                        "完成",
                        value: Formatters.activityDate.string(from: completedAt)
                    )
                }
            }

            Section {
                if !record.canPay {
                    Button("联系陪玩", systemImage: "message") {
                        contact(record.companionNickname)
                    }
                }
                if let item = buddies.item(for: record.companionNickname) {
                    NavigationLink {
                        BuddyDetailRouteView(item: item)
                    } label: {
                        Label("查看资料", systemImage: "person.crop.circle")
                    }
                }
                if shouldOfferReissue(record) {
                    Button("补发预约凭证", systemImage: "ticket") {
                        _ = passStore.issueBookingTicket(for: record)
                    }
                } else if record.status == .pendingConfirm || record.status == .awaitingPayment {
                    Text("支付完成后将生成预约凭证")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if hasPrimaryActions(record) {
                Section("订单操作") {
                    bookingActions(record)
                }
            }

            #if DEBUG
            if record.canSimulateCounterpart, showsCompanionDebugControls {
                Section {
                    Button(BuddyBookingFlowCopy.debugAdvanceAccept, systemImage: "hand.thumbsup") {
                        buddies.acceptBooking(record.id)
                    }
                    Button(BuddyBookingFlowCopy.debugAdvanceDecline, systemImage: "hand.thumbsdown", role: .destructive) {
                        buddies.declineBooking(record.id)
                    }
                } header: {
                    Text(BuddyBookingFlowCopy.debugAdvanceHeader)
                } footer: {
                    Text(BuddyBookingFlowCopy.debugAdvanceFooter)
                }
            }
            #endif

            Section {
                Button("删除记录", systemImage: "trash", role: .destructive) {
                    confirmDelete = true
                }
            }
        }
        .profileSecondaryListChrome(flushTop: true, compactSections: true)
    }

    func shouldOfferReissue(_ record: BuddyBookingRecord) -> Bool {
        let eligibleStatus =
            record.status == .paid
            || record.status == .inProgress
            || record.status == .completed
        guard eligibleStatus else { return false }
        guard let pass = relatedPass else { return true }
        return pass.voided
    }

    func hasPrimaryActions(_ record: BuddyBookingRecord) -> Bool {
        record.canWithdraw
            || (record.canRefund && RefundPolicy.evaluateBooking(record: record).allowed)
            || record.canReschedule
            || (record.status == .completed && !trust.hasCheckedIn(bookingID: record.id))
            || buddies.canWriteCompanionReview(for: record)
    }

    @ViewBuilder
    func bookingActions(_ record: BuddyBookingRecord) -> some View {
        if record.status == .completed, !trust.hasCheckedIn(bookingID: record.id) {
            Button("履约确认", systemImage: "checkmark.shield") {
                buddies.presentation.pendingSafetyCheckInBookingID = record.id
            }
        }
        if buddies.canWriteCompanionReview(for: record) {
            PlatformReviewsWriteEntryRow(title: PlatformReviewsCopy.writeReviewTitle) {
                showWriteReview = true
            }
        }
        if record.canReschedule {
            Button("改期", systemImage: "calendar") {
                showReschedule = true
            }
        }
        if record.canRefund,
           !refunds.isRefunding(orderID: record.id),
           RefundPolicy.evaluateBooking(record: record).allowed {
            Button(BuddyBookingFlowCopy.refundCTA, systemImage: "arrow.uturn.backward", role: .destructive) {
                refundTarget = record
            }
        }
        if record.canWithdraw {
            Button(BuddyBookingFlowCopy.withdrawBooking, systemImage: "xmark.circle", role: .destructive) {
                confirmCancel = true
            }
        }
    }

    @discardableResult
    func submitBookingRefund(
        _ record: BuddyBookingRecord,
        reason: String,
        detail: String
    ) -> Bool {
        switch buddies.refundBooking(record.id, reason: reason, detail: detail) {
        case .success(let requestID):
            presentedRefundRequestID = requestID
            return true
        case .failure(let error):
            refundError = error.localizedDescription
            return false
        }
    }

    func contact(_ nickname: String) {
        guard let record else { return }
        peerContactRoute = app.openPeerContact(
            with: nickname,
            context: .forBooking(record)
        )
    }

    var showsCompanionDebugControls: Bool {
        #if DEBUG
        FeatureFlags.simulateBookingCompanionAcceptance
        #else
        false
        #endif
    }

    func navigationTitle(for record: BuddyBookingRecord?) -> String {
        guard let record else { return BuddyBookingFlowCopy.orderDetailTitle }
        switch record.status {
        case .awaitingPayment:
            return BuddyBookingFlowCopy.awaitingPaymentTitle
        case .pendingConfirm:
            return BuddyBookingFlowCopy.orderDetailTitle
        default:
            return "陪玩凭证"
        }
    }
}
