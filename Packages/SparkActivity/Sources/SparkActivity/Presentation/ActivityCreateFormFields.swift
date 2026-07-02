// Module: SparkActivity — Shared create / edit activity form (orient → decide → understand).

import PhotosUI
import SparkDesignSystem
import SwiftUI

/// Form module order: templates → progress → orient → decide → understand.
struct ActivityCreateFormFields: View {
    @Binding var draft: CreateActivityDraft
    @Binding var selectedCoverItems: [PhotosPickerItem]
    let coverPreviewImage: Image?
    let coverIsVideo: Bool
    let submitErrorMessage: String?
    let showsValidationGuidance: Bool
    var showsQuickTemplates: Bool = true
    var showsCoverPicker: Bool = true
    var showsProgress: Bool = true
    var savedTemplates: [ActivityCreateSavedTemplate] = []
    var canSaveAsTemplate: Bool = false
    var onQuickTemplateSelected: ((ActivityCreateQuickTemplate) -> Void)?
    var onSavedTemplateSelected: ((ActivityCreateSavedTemplate) -> Void)?
    var onSaveCurrentAsTemplate: (() -> Void)?
    var onRemoveSavedTemplate: ((String) -> Void)?

    @State private var showsOptionalDescription = false

    var body: some View {
        if showsQuickTemplates {
            ActivityCreateTemplateSection(
                savedTemplates: savedTemplates,
                canSaveCurrent: canSaveAsTemplate,
                onSelectBuiltin: { template in
                    onQuickTemplateSelected?(template)
                    showsOptionalDescription = true
                },
                onSelectSaved: { template in
                    onSavedTemplateSelected?(template)
                    showsOptionalDescription = !template.description.isEmpty
                },
                onSaveCurrent: {
                    onSaveCurrentAsTemplate?()
                },
                onRemoveSaved: { id in
                    onRemoveSavedTemplate?(id)
                }
            )
        }

        if showsProgress, showsCoverPicker {
            ActivityCreateProgressSection(
                draft: draft,
                hasCover: !selectedCoverItems.isEmpty
            )
        }

        if showsCoverPicker {
            ActivityCreateOrientSection(
                draft: $draft,
                selectedCoverItems: $selectedCoverItems,
                coverPreviewImage: coverPreviewImage,
                coverIsVideo: coverIsVideo
            )
        } else {
            orientFieldsOnly
        }

        ActivityCreateDecideSection(draft: $draft)

        ActivityCreateUnderstandSection(
            draft: $draft,
            showsOptionalDescription: $showsOptionalDescription
        )

        if showsValidationGuidance, let guidance = validationGuidanceMessage {
            Section {
                Text(guidance)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        if let submitErrorMessage {
            Section {
                Text(submitErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var orientFieldsOnly: some View {
        Section {
            TextField(
                String(
                    localized: "activity.create.title.placeholder",
                    defaultValue: "如：周末咖啡小局",
                    comment: "Create title placeholder"
                ),
                text: $draft.title
            )
            .textInputAutocapitalization(.sentences)
        } header: {
            Text(
                String(
                    localized: "activity.create.section.orient",
                    defaultValue: "这是什么局",
                    comment: "Orient section"
                )
            )
        }
    }

    private var validationGuidanceMessage: String? {
        if selectedCoverItems.isEmpty, showsCoverPicker {
            return String(
                localized: "activity.create.cover.required",
                defaultValue: "请先上传局封面",
                comment: "Cover required guidance"
            )
        }
        return draft.validationError?.errorDescription
    }
}

#Preview {
    @Previewable @State var draft = CreateActivityDraft()
    @Previewable @State var coverItems: [PhotosPickerItem] = []
    Form {
        ActivityCreateFormFields(
            draft: $draft,
            selectedCoverItems: $coverItems,
            coverPreviewImage: nil,
            coverIsVideo: false,
            submitErrorMessage: nil,
            showsValidationGuidance: false,
            onQuickTemplateSelected: { template in
                template.apply(to: &draft)
            }
        )
    }
}
