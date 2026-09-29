//
//  InterestTaxonomyFormEditor.swift
//  坐标系
//
//  编辑资料：Form 内按分类 Toggle 多选兴趣。
//

import SwiftUI
import CoordinateModels

// MARK: - Form editor（编辑资料等 Settings 风格）

/// Form 内兴趣多选：分类 Section + Toggle，不嵌入 chip 流。
struct InterestTaxonomyFormEditor: View {
    @Binding var selected: Set<String>

    @State private var draftByScope: [String: String] = [:]
    @State private var customPlacement: [String: String] = [:]

    private var catalog: Set<String> { Set(ActivityTaxonomy.allSubtypes) }

    var body: some View {
        Form {
            Section {
                LabeledContent(
                    "已选",
                    value: "\(selected.count)/\(InterestSelectionLimits.maximum)"
                )
            } footer: {
                Text(InterestSelectionLimits.progressText(count: selected.count))
            }

            ForEach(ActivityTaxonomy.groups) { group in
                categorySection(group)
            }

            freeformSection
        }
        .navigationTitle("兴趣标签")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: hydratePlacement)
        .onChange(of: selected) { _, _ in
            prunePlacement()
        }
    }

    private func categorySection(_ group: ActivityTaxonomy.Group) -> some View {
        let scope = group.category.rawValue
        let extras = customTags(in: scope)

        return Section {
            ForEach(group.subtypes, id: \.self) { tag in
                Toggle(isOn: binding(for: tag)) {
                    Label(tag, systemImage: ActivityTaxonomy.systemImage(forSubtype: tag))
                }
            }
            ForEach(extras, id: \.self) { tag in
                Toggle(isOn: binding(for: tag)) {
                    Label(tag, systemImage: "tag")
                }
            }
            customDraftRow(
                scope: scope,
                placeholder: "在\(group.category.title)下添加"
            )
        } header: {
            Label(group.category.title, systemImage: group.category.systemImage)
        }
    }

    private var freeformSection: some View {
        let extras = customTags(in: "freeform")
        return Section {
            ForEach(extras, id: \.self) { tag in
                Toggle(isOn: binding(for: tag)) {
                    Label(tag, systemImage: "tag")
                }
            }
            customDraftRow(scope: "freeform", placeholder: "例如：汉服、滑板")
        } header: {
            Label("自定义分类", systemImage: "plus.circle")
        } footer: {
            Text("不属于上面分类的标签可加在这里。")
        }
    }

    private func customDraftRow(scope: String, placeholder: String) -> some View {
        HStack {
            TextField(placeholder, text: draftBinding(scope))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { commitDraft(scope: scope) }
            Button("添加") {
                commitDraft(scope: scope)
            }
            .disabled(!canCommit(scope: scope))
        }
    }

    private func binding(for tag: String) -> Binding<Bool> {
        Binding(
            get: { selected.contains(tag) },
            set: { isOn in
                if isOn {
                    guard InterestSelectionLimits.canSelectMore(selected.count) || selected.contains(tag) else { return }
                    selected.insert(tag)
                } else {
                    selected.remove(tag)
                }
            }
        )
    }

    private func draftBinding(_ scope: String) -> Binding<String> {
        Binding(
            get: { draftByScope[scope] ?? "" },
            set: { draftByScope[scope] = $0 }
        )
    }

    private func normalizedDraft(scope: String) -> String {
        (draftByScope[scope] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "，", with: "")
            .replacingOccurrences(of: ",", with: "")
    }

    private func canCommit(scope: String) -> Bool {
        let tag = String(normalizedDraft(scope: scope).prefix(12))
        guard !tag.isEmpty else { return false }
        if selected.contains(tag) { return true }
        return InterestSelectionLimits.canSelectMore(selected.count)
    }

    private func commitDraft(scope: String) {
        let tag = String(normalizedDraft(scope: scope).prefix(12))
        guard !tag.isEmpty else { return }
        if selected.contains(tag) {
            draftByScope[scope] = ""
            return
        }
        guard InterestSelectionLimits.canSelectMore(selected.count) else { return }
        selected.insert(tag)
        if !catalog.contains(tag) {
            customPlacement[tag] = scope
        }
        draftByScope[scope] = ""
    }

    private func customTags(in scope: String) -> [String] {
        selected
            .filter { !catalog.contains($0) && customPlacement[$0] == scope }
            .sorted()
    }

    private func hydratePlacement() {
        for tag in selected where !catalog.contains(tag) {
            if customPlacement[tag] == nil {
                customPlacement[tag] = "freeform"
            }
        }
    }

    private func prunePlacement() {
        let orphanKeys = customPlacement.keys.filter { !selected.contains($0) }
        for key in orphanKeys {
            customPlacement.removeValue(forKey: key)
        }
        for tag in selected where !catalog.contains(tag) && customPlacement[tag] == nil {
            customPlacement[tag] = "freeform"
        }
    }
}
