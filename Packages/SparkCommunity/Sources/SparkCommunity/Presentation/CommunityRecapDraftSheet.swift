// Module: SparkCommunity — Post-event recap draft (Phase 24; copy-first until create API).

import SwiftUI
import UIKit

public struct CommunityRecapDraftSheet: View {
    let activityTitle: String
    let scheduleLine: String
    let onDismiss: () -> Void

    @State private var draftText: String

    public init(activityTitle: String, scheduleLine: String, onDismiss: @escaping () -> Void) {
        self.activityTitle = activityTitle
        self.scheduleLine = scheduleLine
        self.onDismiss = onDismiss
        let format = String(
            localized: "community.recap.draft.format",
            defaultValue: "刚参加了「%1$@」（%2$@），感受：",
            comment: "Recap draft; title + schedule"
        )
        _draftText = State(initialValue: String(format: format, locale: .current, activityTitle, scheduleLine))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $draftText)
                        .frame(minHeight: 120)
                } footer: {
                    Text(
                        String(
                            localized: "community.recap.footer",
                            defaultValue: "文案已可复制，前往社区发帖粘贴即可。",
                            comment: "Recap footer"
                        )
                    )
                }
            }
            .navigationTitle(
                String(localized: "community.recap.title", defaultValue: "分享感受", comment: "Recap title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "community.recap.copy", defaultValue: "复制", comment: "Copy recap")) {
                        UIPasteboard.general.string = draftText
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
