//
//  EditProfileSheet+Prompts.swift
//  坐标系
//
//  Prompt 问答分区。
//

import CoordinateModels
import SwiftUI

extension EditProfileSheet {
    var promptsSection: some View {
        Section {
            ForEach(Array(draftPrompts.enumerated()), id: \.element.id) { index, prompt in
                NavigationLink {
                    ProfilePromptEditorView(
                        prompt: bindingPrompt(at: index),
                        usedKeys: Set(draftPrompts.map(\.promptKey)),
                        galleryLocalNames: user.galleryLocalNames
                    )
                } label: {
                    VStack(
                        alignment: .leading,
                        spacing: PlatformConversationListRow.textToSecondarySpacing
                    ) {
                        Text(ProfilePromptCatalog.title(for: prompt.promptKey))
                            .font(.body)
                        Text(prompt.answer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(EditProfileCopy.promptRemove, role: .destructive) {
                        draftPrompts.remove(at: index)
                    }
                }
            }

            if draftPrompts.count < ProfilePromptLimits.maxCount {
                NavigationLink {
                    ProfilePromptEditorView(
                        prompt: $pendingPromptDraft,
                        usedKeys: Set(draftPrompts.map(\.promptKey)),
                        galleryLocalNames: user.galleryLocalNames,
                        onCommitNew: { prompt in
                            draftPrompts = ProfilePromptLimits.clamped(draftPrompts + [prompt])
                            pendingPromptDraft = ProfilePrompt(
                                promptKey: ProfilePromptCatalog.keys.first ?? "weekPlan",
                                answer: ""
                            )
                        }
                    )
                } label: {
                    Label(EditProfileCopy.promptAdd, systemImage: "plus.circle")
                }
            }
        } header: {
            Text(EditProfileCopy.promptsHeader)
        }
    }

    private func bindingPrompt(at index: Int) -> Binding<ProfilePrompt> {
        Binding(
            get: { draftPrompts[index] },
            set: { draftPrompts[index] = $0 }
        )
    }
}
