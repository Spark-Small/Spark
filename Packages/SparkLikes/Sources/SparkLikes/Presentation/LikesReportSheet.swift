// Module: SparkLikes — Report + block confirmation.

import SparkDesignSystem
import SwiftUI

struct LikesReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let peerName: String
    let onSubmit: (LikesReportReason, String?) -> Void

    @State private var reason: LikesReportReason = .spam
    @State private var detail = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        String(
                            localized: "likes.report.reason.section",
                            defaultValue: "举报原因",
                            comment: "Report reason section"
                        ),
                        selection: $reason
                    ) {
                        ForEach(LikesReportReason.allCases) { item in
                            Text(item.localizedTitle).tag(item)
                        }
                    }
                } footer: {
                    Text(reportFooter(for: peerName))
                }

                if reason == .other {
                    Section {
                        TextField(
                            String(
                                localized: "likes.report.detail.placeholder",
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
                String(localized: "likes.report.title", defaultValue: "举报并屏蔽", comment: "Report title")
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
                        String(localized: "likes.report.submit", defaultValue: "提交", comment: "Submit report"),
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

    private func reportFooter(for peerName: String) -> String {
        let format = String(
            localized: "likes.report.footer.format",
            defaultValue: "将同时屏蔽 %@，不再出现在推荐中",
            comment: "Report footer; %@ is name"
        )
        return String(format: format, locale: .current, peerName)
    }
}

#Preview {
    LikesReportSheet(peerName: "小雨") { _, _ in }
}
