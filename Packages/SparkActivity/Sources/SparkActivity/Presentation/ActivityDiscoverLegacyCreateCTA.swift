// Module: SparkActivity — Pre-iOS 26.1 discover create CTA (tab bottom accessory fallback).

import SparkDesignSystem
import SwiftUI

/// Mirrors discover create action when `tabViewBottomAccessory` is unavailable.
struct ActivityDiscoverLegacyCreateCTA: View {
    let isGuest: Bool
    let action: () -> Void

    private var kind: ActivityTabBottomAccessoryKind {
        .createActivity(guest: isGuest)
    }

    var body: some View {
        ActivityTabBottomFallbackCTA(
            kind: kind,
            isLoading: false,
            action: action
        )
    }
}

#Preview("Legacy create CTA") {
    ActivityDiscoverLegacyCreateCTA(isGuest: false, action: {})
        .padding()
}
