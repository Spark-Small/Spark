//
//  InterestTaxonomyFormEditor.swift
//  坐标系
//
//  喜好多选：品牌紫 glass 胶囊 + 内容分类多色 SF Symbol；流式换行。
//

import SwiftUI
import UIKit
import CoordinateModels

/// 喜好多选：分类标题 + glass 胶囊流；编辑资料与登录后喜好页共用。
struct InterestTaxonomyFormEditor: View {
    @Binding var selected: Set<String>
    /// 登录引导把进度放在底栏时关掉页内进度条。
    var showsSelectionProgress = true
    /// 满选后再点未选项时回调（父级可发轻反馈 / 埋点）。
    var onLimitReached: (() -> Void)? = nil

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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                if showsSelectionProgress { progressHeader }

                ForEach(ActivityTaxonomy.groups) { group in
                    tagSection(
                        title: group.category.title,
                        systemImage: group.category.systemImage,
                        tags: group.subtypes,
                        scope: group.category.rawValue,
                        addPlaceholder: "在\(group.category.title)下添加"
                    )
                }

                tagSection(
                    title: "创建独属于你的爱好",
                    systemImage: "sparkles",
                    tags: [],
                    scope: Self.freeformScope,
                    addPlaceholder: "例如：汉服、滑板"
                )
            }
            .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentMargins(.horizontal, PlatformMetrics.contentInset, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .background(PlatformSurface.groupedPage.ignoresSafeArea())
        .navigationTitle("选择喜好")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: hydratePlacement)
        .onChange(of: selected) { _, _ in prunePlacement() }
        .sensoryFeedback(.warning, trigger: limitFeedbackPulse)
        .alert("添加爱好", isPresented: isAddingTag) {
            TextField(addPrompt?.placeholder ?? "爱好", text: addDraftBinding)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("添加") {
                if let prompt = addPrompt {
                    commitDraft(scope: prompt.scope, raw: prompt.draft)
                }
                addPrompt = nil
            }
            .disabled(!canCommitCurrentPrompt)
            Button("取消", role: .cancel) { addPrompt = nil }
        } message: {
            Text("最多 12 个字")
        }
    }

    // MARK: - Sections

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
            Text("\(selected.count)/\(InterestSelectionLimits.maximum)")
                .font(.headline)
            Text(InterestSelectionLimits.progressText(count: selected.count))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func tagSection(
        title: String,
        systemImage: String,
        tags: [String],
        scope: String,
        addPlaceholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .platformContentSymbolStyle()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)

            InterestChipFlowLayout(spacing: PlatformMetrics.inlineControlSpacing) {
                ForEach(tags, id: \.self) { tag in
                    chip(tag, systemImage: ActivityTaxonomy.systemImage(forSubtype: tag))
                }
                ForEach(customTags(in: scope), id: \.self) { tag in
                    chip(tag, systemImage: "tag.fill")
                }
                Button {
                    guard canSelectMore else {
                        announceLimitReached()
                        return
                    }
                    addPrompt = AddTagPrompt(scope: scope, placeholder: addPlaceholder, draft: "")
                } label: {
                    InterestChipLabel(title: "添加", systemImage: "plus.circle.fill")
                }
                .interestGlassCapsuleStyle(isSelected: false)
                .disabled(!canSelectMore)
                .accessibilityLabel("添加爱好")
                .accessibilityHint(
                    canSelectMore
                        ? "添加自定义爱好"
                        : InterestSelectionLimits.limitReachedFeedback
                )
            }
        }
    }

    private func chip(_ tag: String, systemImage: String) -> some View {
        let isSelected = selected.contains(tag)
        let isEnabled = isSelected || canSelectMore
        return InterestGlassCapsuleChip(
            title: tag,
            systemImage: systemImage,
            isSelected: isSelected,
            isEnabled: isEnabled,
            action: { toggle(tag) }
        )
        .accessibilityHint(
            isEnabled
                ? (isSelected ? "再次轻点可取消" : "轻点选择")
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
        return canCommit(raw: prompt.draft)
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

    private func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "，", with: "")
            .replacingOccurrences(of: ",", with: "")
    }

    private func canCommit(raw: String) -> Bool {
        let tag = String(normalized(raw).prefix(12))
        guard !tag.isEmpty else { return false }
        return selected.contains(tag) || canSelectMore
    }

    private func commitDraft(scope: String, raw: String) {
        let tag = String(normalized(raw).prefix(12))
        guard !tag.isEmpty, !selected.contains(tag) else { return }
        guard canSelectMore else {
            announceLimitReached()
            return
        }
        selected.insert(tag)
        if !catalog.contains(tag) {
            customPlacement[tag] = scope
        }
    }

    private func customTags(in scope: String) -> [String] {
        selected
            .filter { !catalog.contains($0) && customPlacement[$0] == scope }
            .sorted()
    }

    private func hydratePlacement() {
        for tag in selected where !catalog.contains(tag) && customPlacement[tag] == nil {
            customPlacement[tag] = Self.freeformScope
        }
    }

    private func prunePlacement() {
        customPlacement = customPlacement.filter { selected.contains($0.key) }
        for tag in selected where !catalog.contains(tag) && customPlacement[tag] == nil {
            customPlacement[tag] = Self.freeformScope
        }
    }

    private static let freeformScope = "freeform"

    private struct AddTagPrompt: Equatable {
        var scope: String
        var placeholder: String
        var draft: String
    }
}

// MARK: - Glass capsule

struct InterestGlassCapsuleChip: View {
    let title: String
    let systemImage: String
    var isSelected: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            InterestChipLabel(title: title, systemImage: systemImage)
        }
        .interestGlassCapsuleStyle(isSelected: isSelected)
        .disabled(!isEnabled)
        .opacity(isEnabled || isSelected ? 1 : 0.45)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct InterestChipLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label {
            Text(title)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        } icon: {
            Image(systemName: systemImage)
                .platformContentSymbolStyle()
        }
        .font(.subheadline.weight(.medium))
        .labelStyle(.titleAndIcon)
    }
}

extension View {
    fileprivate func interestGlassCapsuleStyle(isSelected: Bool) -> some View {
        modifier(InterestGlassCapsuleStyle(isSelected: isSelected))
    }
}

private struct InterestGlassCapsuleStyle: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var isSelected: Bool

    func body(content: Content) -> some View {
        Group {
            if reduceTransparency {
                if isSelected {
                    content
                        .buttonStyle(.borderedProminent)
                } else {
                    content
                        .buttonStyle(.bordered)
                }
            } else if isSelected {
                content
                    .buttonStyle(.glassProminent)
            } else {
                content
                    .buttonStyle(.glass)
            }
        }
        .controlSize(.regular)
        .buttonBorderShape(.capsule)
        .tint(isSelected ? Color.accentColor : .primary)
    }
}

// MARK: - Flow layout

private struct InterestChipFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = arrange(proposal: proposal, subviews: subviews).frames
        for index in subviews.indices {
            let frame = frames[index]
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        var frames: [CGRect] = []
        frames.reserveCapacity(subviews.count)

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

        return (
            CGSize(width: usedWidth, height: subviews.isEmpty ? 0 : y + rowHeight),
            frames
        )
    }
}

#Preview {
    NavigationStack {
        InterestTaxonomyFormEditor(selected: .constant(["徒步", "探店"]))
    }
}
