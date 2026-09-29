//
//  BuddyPaidQuickEntry.swift
//  坐标系
//
//  陪玩发现：快捷入口类型与系统级长条。
//

import SwiftUI
import CoordinateModels

// MARK: - Quick entry

enum BuddyPaidQuickEntry: String, Identifiable {
    case voiceParty
    case quickMatch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickMatch: BuddyPaidBrowseCopy.quickMatchTitle
        case .voiceParty: BuddyPaidBrowseCopy.voicePartyTitle
        }
    }

    var subtitle: String {
        switch self {
        case .quickMatch: BuddyPaidBrowseCopy.quickMatchSubtitle
        case .voiceParty: BuddyPaidBrowseCopy.voicePartySubtitle
        }
    }

    var systemImage: String {
        switch self {
        case .quickMatch: "bolt.fill"
        case .voiceParty: "speaker.wave.2.fill"
        }
    }

    var tint: Color {
        switch self {
        case .quickMatch: .indigo
        case .voiceParty: .purple
        }
    }
}

/// 系统级列表长条：与排行榜行同高，全宽一条一行动作
struct BuddyPaidQuickEntryBar: View {
    let entry: BuddyPaidQuickEntry
    var action: () -> Void

    @Environment(\.platformChromeMeasurements) private var chromeMeasurements

    var body: some View {
        Button(action: action) {
            HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                Image(systemName: entry.systemImage)
                    .font(PlatformListTypography.body)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(entry.tint)
                    .frame(
                        width: chromeMeasurements.navigationBarButtonSide,
                        height: chromeMeasurements.navigationBarButtonSide
                    )
                    .background(
                        entry.tint.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous)
                    )
                    .accessibilityHidden(true)

                PlatformListTextColumn(
                    primary: entry.title,
                    secondary: entry.subtitle,
                    primaryLineLimit: 1,
                    secondaryLineLimit: 1
                )

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, PlatformMetrics.cardInfoSpacing)
            .padding(.vertical, PlatformConversationListRow.verticalInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
            .contentShape(PlatformMetrics.cardShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.title)，\(entry.subtitle)")
        .accessibilityHint("打开\(entry.title)")
    }
}

