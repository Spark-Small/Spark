// Module: SparkActivity — Activity detail sheets (announce, report).

import SparkDesignSystem
import SwiftUI

extension ActivityDetailView {
    var announceSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(
                            localized: "activity.host.announce.placeholder",
                            defaultValue: "通知内容",
                            comment: "Announce placeholder"
                        ),
                        text: $announceMessage,
                        axis: .vertical
                    )
                    .lineLimit(3 ... 6)
                }
            }
            .sparkDismissesKeyboardOnScroll()
            .navigationTitle(
                String(localized: "activity.host.announce.title", defaultValue: "通知报名者", comment: "Announce title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                        showAnnounceSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "activity.host.announce.send", defaultValue: "发送", comment: "Send announce")) {
                        Task {
                            guard let activity = viewModel.activity else { return }
                            await viewModel.announceToAttendees(message: announceMessage)
                            await onHostAnnouncePosted?(activity, announceMessage)
                            showAnnounceSheet = false
                            announceMessage = ""
                        }
                    }
                    .disabled(announceMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    var reportSheet: some View {
        NavigationStack {
            Form {
                Picker(
                    String(localized: "activity.report.reason", defaultValue: "举报原因", comment: "Report picker"),
                    selection: $selectedReportReason
                ) {
                    ForEach(ActivityReportReason.allCases) { reason in
                        Text(reason.localizedLabel).tag(reason)
                    }
                }
                if viewModel.activity?.hostID != nil {
                    Toggle(
                        String(
                            localized: "activity.report.blockHost",
                            defaultValue: "同时不再看到该主办的活动",
                            comment: "Block host toggle"
                        ),
                        isOn: $blockHostOnReport
                    )
                }
                if let message = viewModel.reportFeedbackMessage {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sparkDismissesKeyboardOnScroll()
            .navigationTitle(
                String(localized: "activity.report.title", defaultValue: "举报活动", comment: "Report title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                        showReportSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "activity.report.submit", defaultValue: "提交", comment: "Submit report")) {
                        Task {
                            await viewModel.submitReport(selectedReportReason, blockHost: blockHostOnReport)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
