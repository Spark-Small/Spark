//
//  InterestTaxonomyPicker.swift
//  坐标系
//
//  按一级分类多选；每类末尾可自定义；另有独立「自定义分类」。
//

import SwiftUI

private extension ActivityCategory {
    /// Apple 系统语义色，随显示模式自动适配。
    var interestSymbolColor: Color {
        switch self {
        case .all: .secondary
        case .outdoorSports: .green
        case .interestSocial: .blue
        case .food: .orange
        case .entertainment: .purple
        case .cityExplore: .indigo
        case .handmade: .pink
        case .learning: .cyan
        }
    }
}

struct InterestTaxonomyPicker: View {
    @Binding var selected: Set<String>
    var sectionSpacing: CGFloat = 18
    var usesGroupedSections = false

    /// 当前展开输入框的分区：某个一级分类，或末尾自定义分类。
    @State private var draftingScope: DraftScope?
    @State private var draft = ""
    @FocusState private var isDraftFocused: Bool
    /// 自定义标签归属哪个分区（目录内标签不入此表）。
    @State private var customPlacement: [String: DraftScope] = [:]

    private enum DraftScope: Hashable, Identifiable {
        case category(ActivityCategory)
        case freeform

        var id: String {
            switch self {
            case .category(let category): category.rawValue
            case .freeform: "freeform"
            }
        }
    }

    private var catalog: Set<String> { Set(ActivityTaxonomy.allSubtypes) }

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            ForEach(ActivityTaxonomy.groups) { group in
                categorySection(group)
            }

            freeformSection
        }
        .onAppear(perform: hydratePlacement)
        .onChange(of: selected) { _, _ in
            prunePlacement()
        }
    }

    // MARK: - Sections

    private func categorySection(_ group: ActivityTaxonomy.Group) -> some View {
        let scope = DraftScope.category(group.category)
        let extras = customTags(in: scope)

        return VStack(alignment: .leading, spacing: 12) {
            categoryHeader(
                title: group.category.title,
                systemImage: group.category.systemImage,
                symbolColor: group.category.interestSymbolColor
            )

            FlowInterestChips(
                items: group.subtypes + extras,
                selected: $selected,
                symbolColor: group.category.interestSymbolColor,
                trailingCustom: true,
                isCustomActive: draftingScope == scope,
                onCustomTap: { toggleDraft(scope) },
                systemImageProvider: { item in
                    if group.subtypes.contains(item) {
                        ActivityTaxonomy.systemImage(forSubtype: item)
                    } else {
                        "tag"
                    }
                }
            )

            if draftingScope == scope {
                inlineEditor(
                    placeholder: "在\(group.category.title)下添加，例如：飞盘局",
                    onSubmit: { commitDraft(to: scope) }
                )
            }
        }
        .padding(usesGroupedSections ? 16 : 0)
        .background {
            if usesGroupedSections {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
        }
    }

    private var freeformSection: some View {
        let extras = customTags(in: .freeform)

        return VStack(alignment: .leading, spacing: 12) {
            categoryHeader(
                title: "自定义分类",
                systemImage: "plus.circle.fill",
                symbolColor: .teal
            )

            Text("不属于上面分类的，也可以单独加在这里。")
                .font(.caption)
                .foregroundStyle(.secondary)

            FlowInterestChips(
                items: extras,
                selected: $selected,
                symbolColor: .teal,
                trailingCustom: true,
                isCustomActive: draftingScope == .freeform,
                onCustomTap: { toggleDraft(.freeform) },
                systemImageProvider: { _ in "tag" }
            )

            if draftingScope == .freeform {
                inlineEditor(
                    placeholder: "例如：汉服、滑板、剧本杀房主",
                    onSubmit: { commitDraft(to: .freeform) }
                )
            }
        }
        .padding(usesGroupedSections ? 16 : 0)
        .background {
            if usesGroupedSections {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
        }
    }

    private func inlineEditor(placeholder: String, onSubmit: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            TextField(placeholder, text: $draft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isDraftFocused)
                .submitLabel(.done)
                .onSubmit(onSubmit)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    PlatformSurface.groupedBlock,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )

            Button("添加", action: onSubmit)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(normalizedDraft.isEmpty || !InterestSelectionLimits.canSelectMore(selected.count))
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func categoryHeader(
        title: String,
        systemImage: String,
        symbolColor: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(symbolColor, symbolColor.opacity(0.55))
                .frame(width: 32, height: 32)
                .background(symbolColor.opacity(0.12), in: Circle())

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Draft

    private var normalizedDraft: String {
        draft
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "，", with: "")
            .replacingOccurrences(of: ",", with: "")
    }

    private func toggleDraft(_ scope: DraftScope) {
        withAnimation(.easeOut(duration: 0.2)) {
            if draftingScope == scope {
                draftingScope = nil
                isDraftFocused = false
                draft = ""
            } else {
                draftingScope = scope
                draft = ""
                isDraftFocused = true
            }
        }
    }

    private func commitDraft(to scope: DraftScope) {
        let tag = String(normalizedDraft.prefix(12))
        guard !tag.isEmpty else { return }

        if selected.contains(tag) {
            draft = ""
            withAnimation(.easeOut(duration: 0.2)) { draftingScope = nil }
            isDraftFocused = false
            return
        }

        guard InterestSelectionLimits.canSelectMore(selected.count) else { return }

        if catalog.contains(tag) {
            selected.insert(tag)
            customPlacement.removeValue(forKey: tag)
        } else {
            selected.insert(tag)
            customPlacement[tag] = scope
        }

        draft = ""
        withAnimation(.easeOut(duration: 0.2)) {
            draftingScope = nil
        }
        isDraftFocused = false
    }

    private func customTags(in scope: DraftScope) -> [String] {
        selected
            .filter { !catalog.contains($0) && customPlacement[$0] == scope }
            .sorted()
    }

    private func hydratePlacement() {
        for tag in selected where !catalog.contains(tag) {
            if customPlacement[tag] == nil {
                customPlacement[tag] = .freeform
            }
        }
    }

    private func prunePlacement() {
        let orphanKeys = customPlacement.keys.filter { !selected.contains($0) }
        for key in orphanKeys {
            customPlacement.removeValue(forKey: key)
        }
        for tag in selected where !catalog.contains(tag) && customPlacement[tag] == nil {
            customPlacement[tag] = .freeform
        }
    }
}

// MARK: - Chips

private struct FlowInterestChips: View {
    let items: [String]
    @Binding var selected: Set<String>
    var symbolColor: Color
    var trailingCustom: Bool = false
    var isCustomActive: Bool = false
    var onCustomTap: (() -> Void)?
    var systemImageProvider: (String) -> String = { ActivityTaxonomy.systemImage(forSubtype: $0) }

    var body: some View {
        // FlexibleChipWrap 内使用材质 chip，避免 GlassEffectContainer 初始化失败。
        FlexibleChipWrap(spacing: 8) {
            ForEach(items, id: \.self) { item in
                PlatformFilterChipButton(
                    title: item,
                    systemImage: systemImageProvider(item),
                    isSelected: selected.contains(item),
                    symbolColor: symbolColor
                ) {
                    toggle(item)
                }
            }

            if trailingCustom, let onCustomTap {
                PlatformFilterChipButton(
                    title: "自定义",
                    systemImage: isCustomActive ? "xmark" : "plus",
                    isSelected: isCustomActive,
                    symbolColor: symbolColor,
                    action: onCustomTap
                )
            }
        }
        .labelStyle(.titleAndIcon)
    }

    private func toggle(_ item: String) {
        if selected.contains(item) {
            selected.remove(item)
        } else if InterestSelectionLimits.canSelectMore(selected.count) {
            selected.insert(item)
        }
    }
}

private struct FlexibleChipWrap: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal: proposal, subviews: subviews)
        let width = proposal.width ?? rows.maxWidth
        return CGSize(width: width, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, frame) in rows.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private struct Arrangement {
        var frames: [CGRect]
        var height: CGFloat
        var maxWidth: CGFloat
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> Arrangement {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
        }

        return Arrangement(
            frames: frames,
            height: y + rowHeight,
            maxWidth: usedWidth
        )
    }
}
