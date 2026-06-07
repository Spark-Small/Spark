// Module: SparkActivity — Activity inbox list row.

import SparkDesignSystem
import SwiftUI

struct ActivityInboxListRow: View {
    let item: ActivityItem
    let isLocked: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.category.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if !isLocked {
                        statusCapsule(item.rsvpStatus.localizedLabel)
                        if let badge = item.lifecycleBadge {
                            statusCapsule(badge)
                        }
                    }
                }
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(isLocked ? .secondary : .primary)
                Text(item.scheduleLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if !item.hostDisplayName.isEmpty, !isLocked {
                    Text(hostLine(for: item.hostDisplayName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }

    private func statusCapsule(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .sparkGlassControl(Capsule())
    }

    private func hostLine(for name: String) -> String {
        let format = String(
            localized: "activity.row.host.format",
            defaultValue: "主办 %@",
            comment: "Host line; %@ is name"
        )
        return String(format: format, locale: .current, name)
    }

    private var accessibilityLabelText: String {
        if isLocked {
            let format = String(
                localized: "activity.row.locked.format",
                defaultValue: "%@，需订阅",
                comment: "Locked row; %@ is title"
            )
            return String(format: format, locale: .current, item.title)
        }
        return "\(item.title), \(item.scheduleLine), \(item.rsvpStatus.localizedLabel)"
    }
}

#Preview {
    if let detail = MockActivityCatalog.detail(id: "act_1") {
        List {
            ActivityInboxListRow(item: detail.asListItem(), isLocked: false)
            ActivityInboxListRow(item: detail.asListItem(), isLocked: true)
        }
    }
}
