// Module: SparkCommunity — Report post sheet (Guideline 1.2 UGC).

import SparkDesignSystem
import SwiftUI

struct CommunityReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSubmit: (CommunityReportReason, String?) -> Void

    @State private var reason: CommunityReportReason = .spam
    @State private var detail = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        String(
                            localized: "community.report.reason.section",
                            defaultValue: "举报原因",
                            comment: "Report reason section"
                        ),
                        selection: $reason
                    ) {
                        ForEach(CommunityReportReason.allCases) { item in
                            Text(item.localizedTitle).tag(item)
                        }
                    }
                } footer: {
                    Text(
                        String(
                            localized: "community.report.footer",
                            defaultValue: "举报将提交至审核队列，我们会在 24 小时内首次响应。",
                            comment: "Community report footer"
                        )
                    )
                }

                if reason == .other {
                    Section {
                        TextField(
                            String(
                                localized: "community.report.detail.placeholder",
                                defaultValue: "补充说明（可选）",
                                comment: "Report detail"
                            ),
                            text: $detail,
                            axis: .vertical
                        )
                        .lineLimit(3 ... 6)
                    }
                }
            }
            .sparkDismissesKeyboardOnScroll()
            .accessibilityElement(children: .contain)
            .navigationTitle(
                String(localized: "community.report.title", defaultValue: "举报帖子", comment: "Report title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        String(localized: "community.report.submit", defaultValue: "提交", comment: "Submit report"),
                        role: .destructive
                    ) {
                        let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSubmit(reason, trimmed.isEmpty ? nil : trimmed)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Report sheet") {
        CommunityReportSheet { _, _ in }
    }
}
