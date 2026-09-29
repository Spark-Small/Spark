//
//  ActivityWaitlistPromotionBanner.swift
//  坐标系
//
//  候补名额开放时的详情内引导行（Form 原生，无 Card 壳）。
//

import SwiftUI
import CoordinateModels

struct ActivityWaitlistPromotionBanner: View {
    let activity: Activity
    let onPromote: () -> Void

    var body: some View {
        Text(
            activity.isFree
                ? ActivityDetailCopy.waitlistPromotionFreeDetail
                : ActivityDetailCopy.waitlistPromotionPaidDetail
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

        Button(action: onPromote) {
            Label(promoteTitle, systemImage: promoteSymbol)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private var promoteTitle: String {
        if activity.isFree {
            return ActivityCardStatus.joinConfirm
        }
        if ActivityPaymentStore.hasPaid(for: activity.id) {
            return ActivityDetailCopy.waitlistPromotePaidAction
        }
        return ActivityDetailCopy.waitlistPromotePayAction
    }

    private var promoteSymbol: String {
        activity.isFree || ActivityPaymentStore.hasPaid(for: activity.id)
            ? "checkmark.circle.fill"
            : "bolt.fill"
    }
}
