//
//  ActivityDetailOrderBanner.swift
//  坐标系
//
//  详情支付横幅：待支付 / 已支付 / 退款态入口。
//

import SwiftUI

struct ActivityDetailOrderBanner: View {
    let order: ActivityOrder
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: order.status == .pending ? "yensign.circle.fill" : "doc.text.fill")
                    .foregroundStyle(PlatformStatus.accent)
                VStack(alignment: .leading) {
                    Text(
                        order.status == .pending
                            ? ActivityDetailCopy.orderBannerPendingTitle
                            : ActivityDetailCopy.orderBannerTitle
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    Text(
                        "\(ActivityPaymentStore.statusLabel(for: order.status)) · \(ActivityFeeParser.formattedPrice(cents: order.amountCents))"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.borderless)
        .accessibilityHint(
            order.status == .pending
                ? ActivityDetailCopy.orderBannerPendingHint
                : ActivityDetailCopy.orderBannerHint
        )
    }
}
