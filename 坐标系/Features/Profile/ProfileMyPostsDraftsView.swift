//
//  ProfileMyPostsDraftsView.swift
//  坐标系
//
//  「我的发帖 · 草稿箱」：本机草稿列表，点开续写，滑动删除。
//

import SwiftUI
import UIKit

@MainActor
struct ProfileMyPostsDraftsView: View {
    @Environment(CommunityModel.self) private var community
    @State private var feedback: String?

    private var drafts: [CommunityPostDraft] {
        community.postDrafts
    }

    var body: some View {
        Group {
            if drafts.isEmpty {
                ProfileLibraryEmptyView(
                    title: ProfileMyPostsCopy.Drafts.emptyTitle,
                    systemImage: ProfileMyPostsCopy.Drafts.emptySystemImage,
                    description: ProfileMyPostsCopy.Drafts.emptyDescription
                ) {
                    Button(ProfileMyPostsCopy.composeAction) {
                        community.beginCompose()
                    }
                }
            } else {
                List {
                    ForEach(drafts) { draft in
                        Button {
                            // Sheet 挂在「我的发帖」父页，避免双 present。
                            community.beginCompose(draftID: draft.id)
                        } label: {
                            ProfileMyPostsDraftRow(draft: draft)
                        }
                        .accessibilityHint(ProfileMyPostsCopy.Drafts.openHint)
                    }
                    .onDelete(perform: deleteDrafts)
                }
                .profileSecondaryListChrome()
            }
        }
        .navigationTitle(ProfileMyPostsCopy.Drafts.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !drafts.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
        .onAppear {
            community.reloadPostDrafts()
        }
        .platformLightFeedback($feedback)
    }

    private func deleteDrafts(at offsets: IndexSet) {
        let ids = offsets.map { drafts[$0].id }
        for id in ids {
            community.deletePostDraft(id: id)
        }
        feedback = ProfileMyPostsCopy.Drafts.deletedFeedback
    }
}

private struct ProfileMyPostsDraftRow: View {
    let draft: CommunityPostDraft

    var body: some View {
        HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
            if let coverName = draft.localPhotoNames.first,
               let url = LocalMediaLibrary.fileURL(named: coverName) {
                draftCover(url: url)
            }

            PlatformListTextColumn(
                primary: draft.previewText,
                secondary: Formatters.conversationListTime(from: draft.updatedAt),
                footnote: footnote,
                primaryLineLimit: 2,
                secondaryLineLimit: 1,
                footnoteLineLimit: 1
            )
        }
        .accessibilityElement(children: .combine)
    }

    private var footnote: String? {
        var parts: [String] = []
        if !draft.localPhotoNames.isEmpty {
            parts.append(ProfileMyPostsCopy.Drafts.mediaCount(draft.localPhotoNames.count))
        }
        if let title = draft.relatedActivityTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
           !title.isEmpty {
            parts.append(title)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    @ViewBuilder
    private func draftCover(url: URL) -> some View {
        Group {
            if LocalMediaLibrary.isVideo(url: url) {
                ZStack {
                    Color.secondary.opacity(0.18)
                    Image(systemName: "play.circle.fill")
                        .font(PlatformListTypography.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
            } else if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary.opacity(0.12)
            }
        }
        .frame(
            width: PlatformConversationListRow.imageSide,
            height: PlatformConversationListRow.imageSide
        )
        .clipShape(RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous))
        .accessibilityHidden(true)
    }
}
