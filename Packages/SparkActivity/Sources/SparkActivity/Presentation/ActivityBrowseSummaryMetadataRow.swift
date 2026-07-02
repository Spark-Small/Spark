// Module: SparkActivity — Shared metadata row for browse hero + join sheet.

import SwiftUI

struct ActivityBrowseSummaryMetadataRow: View {
    enum Emphasis {
        case primary
        case secondary
    }

    let systemImage: String
    let text: String
    var emphasis: Emphasis = .secondary

    var body: some View {
        Label {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(textStyle)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(iconStyle)
                .frame(width: 22, alignment: .center)
        }
        .labelStyle(.titleAndIcon)
    }

    private var textStyle: AnyShapeStyle {
        switch emphasis {
        case .primary:
            return AnyShapeStyle(.primary)
        case .secondary:
            return AnyShapeStyle(.secondary)
        }
    }

    private var iconStyle: AnyShapeStyle {
        switch emphasis {
        case .primary:
            return AnyShapeStyle(.secondary)
        case .secondary:
            return AnyShapeStyle(.tertiary)
        }
    }
}
