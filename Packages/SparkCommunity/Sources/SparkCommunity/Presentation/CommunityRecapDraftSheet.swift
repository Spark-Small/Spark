// Module: SparkCommunity — Share ended activity to Community (photo + caption).

import SparkCore
import SparkDesignSystem
import SwiftUI

public struct CommunityRecapDraftSheet: View {
    let context: ActivityShareContext
    let onPublish: (CommunityRecapDraft) async throws -> CommunityPostDetail
    let onDismiss: () -> Void

    @State private var draftText: String
    @State private var includesCoverImage: Bool
    @State private var isPublishing = false
    @State private var errorMessage: String?

    public init(
        context: ActivityShareContext,
        onPublish: @escaping (CommunityRecapDraft) async throws -> CommunityPostDetail,
        onDismiss: @escaping () -> Void
    ) {
        self.context = context
        self.onPublish = onPublish
        self.onDismiss = onDismiss
        _includesCoverImage = State(initialValue: context.coverImageURL != nil)
        let format = String(
            localized: "community.activityShare.draft.format",
            defaultValue: "刚参加了「%1$@」（%2$@），",
            comment: "Activity share draft opener; title + schedule"
        )
        _draftText = State(
            initialValue: String(format: format, locale: .current, context.title, context.scheduleLine)
        )
    }

    public init(
        activityID: String,
        activityTitle: String,
        scheduleLine: String,
        coverImageURL: URL? = nil,
        onPublish: @escaping (CommunityRecapDraft) async throws -> CommunityPostDetail,
        onDismiss: @escaping () -> Void
    ) {
        self.init(
            context: ActivityShareContext(
                activityID: activityID,
                title: activityTitle,
                scheduleLine: scheduleLine,
                coverImageURL: coverImageURL
            ),
            onPublish: onPublish,
            onDismiss: onDismiss
        )
    }

    public var body: some View {
        NavigationStack {
            Form {
                if !context.mediaGallery.isEmpty {
                    Section {
                        if includesCoverImage {
                            CommunityPostMediaPager(
                                mediaItems: context.mediaGallery,
                                usesInsetMedia: true,
                                horizontalPadding: 0,
                                onOpen: {}
                            )
                            .frame(height: SparkLayoutMetrics.communityRecapGalleryHeight)
                            .listRowInsets(EdgeInsets())
                            .allowsHitTesting(true)
                        }
                        Toggle(
                            String(
                                localized: "community.activityShare.includePhoto",
                                defaultValue: "附上活动照片",
                                comment: "Include activity photo toggle"
                            ),
                            isOn: $includesCoverImage
                        )
                        .disabled(isPublishing)
                    } header: {
                        Text(
                            String(
                                localized: "community.activityShare.photo.section",
                                defaultValue: "活动素材",
                                comment: "Activity media section"
                            )
                        )
                    }
                }

                Section {
                    TextEditor(text: $draftText)
                        .frame(minHeight: 120)
                        .disabled(isPublishing)
                        .accessibilityLabel(
                            String(
                                localized: "community.activityShare.caption.a11y",
                                defaultValue: "分享配文",
                                comment: "Share caption field"
                            )
                        )
                } footer: {
                    Text(
                        String(
                            localized: "community.activityShare.footer.publish",
                            defaultValue: "发布后会出现在社区动态，并关联这场活动。",
                            comment: "Activity share publish footer"
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
            .sparkDismissesKeyboardOnScroll()
            .navigationTitle(
                String(
                    localized: "community.activityShare.title",
                    defaultValue: "分享到社区",
                    comment: "Share to community sheet title"
                )
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
                            .accessibilityHidden(true)
                    } else {
                        Button(
                            String(
                                localized: "community.activityShare.publish",
                                defaultValue: "发布",
                                comment: "Publish activity share"
                            )
                        ) {
                            Task { await publishShare() }
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(isPublishing)
    }

    private func publishShare() async {
        isPublishing = true
        errorMessage = nil
        let draft = CommunityRecapDraft(
            activityID: context.activityID,
            activityTitle: context.title,
            scheduleLine: context.scheduleLine,
            body: draftText,
            mediaGallery: context.mediaGallery,
            includesCoverImage: includesCoverImage
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
    CommunityPreviewTraits.matrix("Recap draft") {
        CommunityRecapDraftSheet(
            context: ActivityShareContext(
                activityID: "act_browse_2",
                title: String(
                    localized: "community.mock.activity.book",
                    defaultValue: "咖啡聊天局",
                    comment: "Activity"
                ),
                scheduleLine: String(
                    localized: "community.mock.activity.schedule3",
                    defaultValue: "周五 19:00",
                    comment: "Schedule"
                ),
                coverImageURL: ActivityShareContext.mockCoverImageURL(activityID: "act_browse_2")
            ),
            onPublish: { draft in
                CommunityPostDetail(
                    id: "preview",
                    title: draft.postTitle,
                    body: draft.normalizedBody,
                    authorDisplayName: String(
                        localized: "community.reply.author.you",
                        defaultValue: "你",
                        comment: "Reply author"
                    ),
                    replyCount: 0,
                    linkedActivity: LinkedActivityContext(id: draft.activityID, name: draft.activityTitle)
                )
            },
            onDismiss: {}
        )
    }
}
