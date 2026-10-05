//
//  InterestTaxonomyFormEditor.swift
//  坐标系
//
//  喜好多选：Form Section + 系统 capsule + PlatformFlowLayout（按内容折行）。
//  数量：编辑资料走 toolbar trailing；登录引导走底栏（showsSelectionProgress = false）。
//

import SwiftUI
import UIKit
import CoordinateModels

struct InterestTaxonomyFormEditor: View {
    @Binding var selected: Set<String>
    /// 登录引导已有底栏进度时关掉顶栏计数（避免双处重复）。
    var showsSelectionProgress = true
    /// 满选后再点未选项时回调（父级可发轻反馈 / 埋点）。
    var onLimitReached: (() -> Void)? = nil

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var customPlacement: [String: String] = [:]
    @State private var addPrompt: AddTagPrompt?
    @State private var limitFeedbackPulse = 0

    private var catalog: Set<String> { Set(ActivityTaxonomy.allSubtypes) }
    private var canSelectMore: Bool { InterestSelectionLimits.canSelectMore(selected.count) }

    private var isAddingTag: Binding<Bool> {
        Binding(
            get: { addPrompt != nil },
            set: { if !$0 { addPrompt = nil } }
        )
    }

    var body: some View {
        Form {
            ForEach(ActivityTaxonomy.groups) { group in
                tagSection(
                    title: group.category.title,
                    systemImage: group.category.systemImage,
                    tags: group.subtypes,
                    scope: group.category.rawValue,
                    addPlaceholder: InterestTaxonomyCopy.categoryAddPlaceholder(
                        categoryTitle: group.category.title
                    )
                )
            }

            tagSection(
                title: InterestTaxonomyCopy.freeformSectionTitle,
                systemImage: InterestTaxonomyCopy.freeformSectionSymbol,
                tags: [],
                scope: Self.freeformScope,
                addPlaceholder: InterestTaxonomyCopy.freeformAddPlaceholder
            )
        }
        .platformTextInputScrollChrome()
        .navigationTitle(InterestTaxonomyCopy.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { selectionCountToolbar }
        .onAppear(perform: restorePlacement)
        .onChange(of: selected) { _, _ in
            prunePlacement()
            persistPlacement()
        }
        .sensoryFeedback(.warning, trigger: limitFeedbackPulse)
        .alert(InterestTaxonomyCopy.addAlertTitle, isPresented: isAddingTag) {
            TextField(
                addPrompt?.placeholder ?? InterestTaxonomyCopy.addFieldFallbackPlaceholder,
                text: addDraftBinding
            )
            .platformFormTextInput(.identifier)
            Button(InterestTaxonomyCopy.addAlertConfirm) {
                if let prompt = addPrompt {
                    commitDraft(scope: prompt.scope, raw: prompt.draft)
                }
                addPrompt = nil
            }
            .disabled(!canCommitCurrentPrompt)
            Button(InterestTaxonomyCopy.addAlertCancel, role: .cancel) { addPrompt = nil }
        } message: {
            Text(InterestTaxonomyCopy.addAlertMessage)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var selectionCountToolbar: some ToolbarContent {
        if showsSelectionProgress {
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(selected.count)/\(InterestSelectionLimits.maximum)")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(
                        InterestSelectionLimits.progressText(count: selected.count)
                    )
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func tagSection(
        title: String,
        systemImage: String,
        tags: [String],
        scope: String,
        addPlaceholder: String
    ) -> some View {
        Section {
            PlatformFlowLayout(spacing: PlatformMetrics.inlineControlSpacing) {
                ForEach(tags, id: \.self) { tag in
                    chip(tag)
                }
                ForEach(customTags(in: scope), id: \.self) { tag in
                    chip(tag)
                }
                addChip(scope: scope, placeholder: addPlaceholder)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .contain)
        } header: {
            Label(title, systemImage: systemImage)
                .platformContentSymbolStyle()
        }
    }

    private func chip(_ tag: String) -> some View {
        let isSelected = selected.contains(tag)
        let isEnabled = isSelected || canSelectMore
        return InterestCapsuleChip(
            title: tag,
            isSelected: isSelected,
            isEnabled: isEnabled,
            action: { toggle(tag) }
        )
        .accessibilityHint(
            isEnabled
                ? (isSelected
                    ? InterestTaxonomyCopy.chipHintDeselect
                    : InterestTaxonomyCopy.chipHintSelect)
                : InterestSelectionLimits.limitReachedFeedback
        )
    }

    private func addChip(scope: String, placeholder: String) -> some View {
        Button {
            guard canSelectMore else {
                announceLimitReached()
                return
            }
            addPrompt = AddTagPrompt(scope: scope, placeholder: placeholder, draft: "")
        } label: {
            Label(InterestTaxonomyCopy.addChipTitle, systemImage: "plus")
                .labelStyle(.titleAndIcon)
                .font(.subheadline.weight(.medium))
        }
        .interestCapsuleChrome(isSelected: false, reduceTransparency: reduceTransparency)
        .disabled(!canSelectMore)
        .accessibilityLabel(InterestTaxonomyCopy.addChipAccessibility)
        .accessibilityHint(
            canSelectMore
                ? InterestTaxonomyCopy.addChipHint
                : InterestSelectionLimits.limitReachedFeedback
        )
    }

    // MARK: - Selection

    private var addDraftBinding: Binding<String> {
        Binding(
            get: { addPrompt?.draft ?? "" },
            set: { newValue in
                guard var prompt = addPrompt else { return }
                prompt.draft = newValue
                addPrompt = prompt
            }
        )
    }

    private var canCommitCurrentPrompt: Bool {
        guard let prompt = addPrompt else { return false }
        let tag = InterestSelectionLimits.normalizedCustomTag(prompt.draft)
        guard !tag.isEmpty else { return false }
        return selected.contains(tag) || canSelectMore
    }

    private func toggle(_ tag: String) {
        if selected.contains(tag) {
            selected.remove(tag)
            return
        }
        guard canSelectMore else {
            announceLimitReached()
            return
        }
        selected.insert(tag)
    }

    private func announceLimitReached() {
        limitFeedbackPulse += 1
        onLimitReached?()
        UIAccessibility.post(
            notification: .announcement,
            argument: InterestSelectionLimits.limitReachedFeedback
        )
    }

    private func commitDraft(scope: String, raw: String) {
        let tag = InterestSelectionLimits.normalizedCustomTag(raw)
        guard !tag.isEmpty, !selected.contains(tag) else { return }
        guard canSelectMore else {
            announceLimitReached()
            return
        }
        if !catalog.contains(tag) {
            customPlacement[tag] = scope
        }
        selected.insert(tag)
    }

    private func customTags(in scope: String) -> [String] {
        selected
            .filter { !catalog.contains($0) && customPlacement[$0] == scope }
            .sorted()
    }

    private func restorePlacement() {
        customPlacement = InterestCustomTagPlacementStore.load()
        hydratePlacement()
        persistPlacement()
    }

    private func hydratePlacement() {
        for tag in selected where !catalog.contains(tag) && customPlacement[tag] == nil {
            customPlacement[tag] = Self.freeformScope
        }
    }

    private func prunePlacement() {
        customPlacement = customPlacement.filter { selected.contains($0.key) }
        hydratePlacement()
    }

    private func persistPlacement() {
        InterestCustomTagPlacementStore.save(customPlacement)
    }

    private static let freeformScope = "freeform"

    private struct AddTagPrompt: Equatable {
        var scope: String
        var placeholder: String
        var draft: String
    }
}

#Preview {
    NavigationStack {
        InterestTaxonomyFormEditor(selected: .constant(["徒步", "探店"]))
    }
}
