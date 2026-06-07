// Module: SparkCommunity — Post-event recap publish sheet (Nexus W5).

import SwiftUI

public struct CommunityRecapDraftSheet: View {
    let activityID: String
    let activityTitle: String
    let scheduleLine: String
    let onPublish: (CommunityRecapDraft) async throws -> CommunityPostDetail
    let onDismiss: () -> Void

    @State private var draftText: String
    @State private var isPublishing = false
    @State private var errorMessage: String?

    public init(
        activityID: String,
        activityTitle: String,
        scheduleLine: String,
        onPublish: @escaping (CommunityRecapDraft) async throws -> CommunityPostDetail,
        onDismiss: @escaping () -> Void
    ) {
        self.activityID = activityID
        self.activityTitle = activityTitle
        self.scheduleLine = scheduleLine
        self.onPublish = onPublish
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
                        .disabled(isPublishing)
                } footer: {
                    Text(
                        String(
                            localized: "community.recap.footer.publish",
                            defaultValue: "发布后会在社区展示，并关联这场活动。",
                            comment: "Recap publish footer"
                        )
                    )
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
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
                    .disabled(isPublishing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isPublishing {
                        ProgressView()
                    } else {
                        Button(String(localized: "community.recap.publish", defaultValue: "发布", comment: "Publish recap")) {
                            Task { await publishRecap() }
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(isPublishing)
    }

    private func publishRecap() async {
        isPublishing = true
        errorMessage = nil
        let draft = CommunityRecapDraft(
            activityID: activityID,
            activityTitle: activityTitle,
            scheduleLine: scheduleLine,
            body: draftText
        )
        do {
            _ = try await onPublish(draft)
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isPublishing = false
    }
}

#Preview {
    CommunityRecapDraftSheet(
        activityID: "act_browse_2",
        activityTitle: "玉林咖啡聊天局",
        scheduleLine: "周六 · 玉林西路",
        onPublish: { draft in
            CommunityPostDetail(
                id: "preview",
                title: draft.postTitle,
                body: draft.normalizedBody,
                authorDisplayName: "Preview",
                replyCount: 0,
                linkedActivity: LinkedActivityContext(id: draft.activityID, name: draft.activityTitle)
            )
        },
        onDismiss: {}
    )
}
