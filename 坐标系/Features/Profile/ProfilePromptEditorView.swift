//
//  ProfilePromptEditorView.swift
//  坐标系
//
//  单条 Prompt 编辑：选题 + 答文 + 可选生活墙配图。
//

import CoordinateModels
import SwiftUI

struct ProfilePromptEditorView: View {
    @Binding var prompt: ProfilePrompt
    var usedKeys: Set<String>
    /// 当前编辑中的生活墙文件名，供 Prompt 配图选用。
    var galleryLocalNames: [String] = []
    var onCommitNew: ((ProfilePrompt) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var answer: String = ""
    @State private var selectedKey: String = ""
    @State private var mediaName: String?

    private var availableKeys: [String] {
        ProfilePromptCatalog.keys.filter { key in
            key == prompt.promptKey || !usedKeys.contains(key)
        }
    }

    private var canSave: Bool {
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedKey.isEmpty
    }

    var body: some View {
        Form {
            Section {
                Picker(EditProfileCopy.promptPickLabel, selection: $selectedKey) {
                    ForEach(availableKeys, id: \.self) { key in
                        Text(ProfilePromptCatalog.title(for: key)).tag(key)
                    }
                }
            } header: {
                Text(EditProfileCopy.promptPickHeader)
            }

            Section {
                TextField(EditProfileCopy.promptAnswerPlaceholder, text: $answer, axis: .vertical)
                    .platformFormTextInput(.body)
                    .onChange(of: answer) { _, value in
                        let next = String(value.prefix(ProfilePromptLimits.answerMax))
                        if next != value { answer = next }
                    }
            } header: {
                Text(EditProfileCopy.promptAnswerHeader)
            }

            if !galleryLocalNames.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: PlatformMetrics.minContentGap) {
                            promptMediaChoice(nil)
                            ForEach(galleryLocalNames, id: \.self) { name in
                                promptMediaChoice(name)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(
                        top: 8,
                        leading: 16,
                        bottom: 8,
                        trailing: 16
                    ))
                } header: {
                    Text(EditProfileCopy.promptMediaHeader)
                }
            }
        }
        .navigationTitle(EditProfileCopy.promptEditorTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(EditProfileCopy.save) {
                    commit()
                }
                .fontWeight(.semibold)
                .disabled(!canSave)
            }
        }
        .onAppear {
            selectedKey = prompt.promptKey.isEmpty
                ? (availableKeys.first ?? ProfilePromptCatalog.keys.first ?? "")
                : prompt.promptKey
            answer = prompt.answer
            mediaName = prompt.mediaName
        }
    }

    @ViewBuilder
    private func promptMediaChoice(_ name: String?) -> some View {
        let selected = mediaName == name
        Button {
            mediaName = name
        } label: {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let name {
                        ProfileGalleryThumb(localName: name)
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "slash.circle")
                            Text(EditProfileCopy.promptMediaNone)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                        .frame(
                            width: PlatformMetrics.galleryEditorThumb,
                            height: PlatformMetrics.galleryEditorThumb
                        )
                        .background(.quaternary.opacity(0.5), in: PlatformMetrics.mediaShape)
                    }
                }
                .frame(
                    width: PlatformMetrics.galleryEditorThumb,
                    height: PlatformMetrics.galleryEditorThumb
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(
            name == nil
                ? EditProfileCopy.promptMediaNone
                : EditProfileCopy.promptMediaPick
        )
    }

    private func commit() {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let boundMedia: String? = {
            guard let mediaName, galleryLocalNames.contains(mediaName) else { return nil }
            return mediaName
        }()
        let next = ProfilePrompt(
            id: prompt.id,
            promptKey: selectedKey,
            answer: String(trimmed.prefix(ProfilePromptLimits.answerMax)),
            mediaName: boundMedia
        )
        if let onCommitNew {
            onCommitNew(next)
        } else {
            prompt = next
        }
        dismiss()
    }
}
