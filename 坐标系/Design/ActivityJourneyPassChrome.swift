//
//  ActivityJourneyPassChrome.swift
//  坐标系
//
//  行程凭证作废 overlay（票面见 ActivityJourneyCredentialFace）。
//

import SwiftUI

struct ActivityJourneyPassVoidedOverlay: View {
    var body: some View {
        Color.black.opacity(0.48)
        Text(ActivityJourneyCopy.voided)
            .font(WalletPassTypography.headerLabel.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
            .platformThinMaterialBackground(in: Capsule())
    }
}
