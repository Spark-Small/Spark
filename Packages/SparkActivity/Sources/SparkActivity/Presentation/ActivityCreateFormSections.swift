// Module: SparkActivity — Create form sections (orient · decide · understand).

import PhotosUI
import SparkCore
import SparkDesignSystem
import SwiftUI

// MARK: - Progress

struct ActivityCreateProgressRing: View {
    let percent: Int

    private var progress: Double {
        Double(min(max(percent, 0), 100)) / 100
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 7)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: percent)

            VStack(spacing: 0) {
                Text("\(percent)")
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(
                    String(
                        localized: "activity.create.progress.percent.symbol",
                        defaultValue: "%",
                        comment: "Percent symbol"
                    )
                )
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
        .frame(width: 76, height: 76)
        .accessibilityHidden(true)
    }
}

struct ActivityCreateProgressSection: View {
    let draft: CreateActivityDraft
    let hasCover: Bool

    private var snapshot: ActivityCreateProgressSnapshot {
        ActivityCreateProgressSnapshot.make(draft: draft, hasCover: hasCover)
    }

    private var understandBonusFilled: Bool {
        ActivityCreateStep.understand.isComplete(draft: draft, hasCover: hasCover)
    }

    var body: some View {
        Section {
            HStack(alignment: .center, spacing: 16) {
                ActivityCreateProgressRing(percent: snapshot.requiredPercent)

                VStack(alignment: .leading, spacing: 6) {
                    Text(snapshot.percentLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())

                    Text(snapshot.nextActionHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if understandBonusFilled {
                        Label(
                            String(
                                localized: "activity.create.progress.bonus.filled",
                                defaultValue: "说明已补充，更容易被信任",
                                comment: "Understand bonus filled"
                            ),
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.22), value: snapshot.requiredPercent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(progressAccessibilityLabel)
    }

    private var progressAccessibilityLabel: String {
        var parts = [snapshot.percentLabel, snapshot.nextActionHint]
        if understandBonusFilled {
            parts.append(
                String(
                    localized: "activity.create.progress.bonus.filled",
                    defaultValue: "说明已补充，更容易被信任",
                    comment: "Understand bonus filled"
                )
            )
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Templates

struct ActivityCreateTemplateSection: View {
    let savedTemplates: [ActivityCreateSavedTemplate]
    let canSaveCurrent: Bool
    let onSelectBuiltin: (ActivityCreateQuickTemplate) -> Void
    let onSelectSaved: (ActivityCreateSavedTemplate) -> Void
    let onSaveCurrent: () -> Void
    let onRemoveSaved: (String) -> Void

    private let templateColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        Section {
            LazyVGrid(columns: templateColumns, spacing: 8) {
                ForEach(ActivityCreateQuickTemplate.allCases) { template in
                    Button {
                        onSelectBuiltin(template)
                    } label: {
                        Label(template.label, systemImage: template.systemImage)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                    }
                    .buttonStyle(.bordered)
                }
            }

            if !savedTemplates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        String(
                            localized: "activity.create.section.myTemplates",
                            defaultValue: "我的模版",
                            comment: "My templates subsection"
                        )
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                    ForEach(savedTemplates) { template in
                        HStack(spacing: 8) {
                            Button {
                                onSelectSaved(template)
                            } label: {
                                Label(template.name, systemImage: template.systemImage)
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)

                            Button(role: .destructive) {
                                onRemoveSaved(template.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.body)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(
                                String(
                                    localized: "activity.create.template.delete.a11y",
                                    defaultValue: "删除模版",
                                    comment: "Delete template a11y"
                                )
                            )
                        }
                    }
                }
            }

            if canSaveCurrent {
                Button {
                    onSaveCurrent()
                } label: {
                    Label(
                        String(
                            localized: "activity.create.template.saveCurrent",
                            defaultValue: "将当前内容存为模版",
                            comment: "Save current as template"
                        ),
                        systemImage: "square.and.arrow.down"
                    )
                }
            }
        } header: {
            Text(
                String(
                    localized: "activity.create.section.quickStart",
                    defaultValue: "从模版发起",
                    comment: "Quick start section"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "activity.create.section.templates.footer",
                    defaultValue: "可保存自己的模版，或在活动详情中收藏他人的局作为模版。",
                    comment: "Templates footer"
                )
            )
        }
    }
}

// MARK: - Orient (cover + title)

struct ActivityCreateOrientSection: View {
    @Binding var draft: CreateActivityDraft
    @Binding var selectedCoverItems: [PhotosPickerItem]
    let coverPreviewImage: Image?
    let coverIsVideo: Bool

    var body: some View {
        Section {
            PhotosPicker(
                selection: $selectedCoverItems,
                maxSelectionCount: 1,
                matching: .any(of: [.images, .videos]),
                photoLibrary: .shared()
            ) {
                coverPickerLabel
            }
            .onAppear {
                SparkPermissionTelemetry.trackPhotoLibraryAccess(source: .activityCreateCover)
            }

            TextField(
                String(
                    localized: "activity.create.title.placeholder",
                    defaultValue: "如：周末咖啡小局",
                    comment: "Create title placeholder"
                ),
                text: $draft.title
            )
            .textInputAutocapitalization(.sentences)
            .accessibilityLabel(
                String(localized: "activity.create.title", defaultValue: "局名", comment: "Create field")
            )

            if !draft.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(draft.category)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: Capsule())
                    .accessibilityLabel(
                        String(
                            format: String(
                                localized: "activity.create.category.a11y.format",
                                defaultValue: "分类：%@",
                                comment: "Category a11y; %@ is category name"
                            ),
                            locale: .current,
                            draft.category
                        )
                    )
            }
        } header: {
            Text(
                String(
                    localized: "activity.create.section.orient",
                    defaultValue: "这是什么局",
                    comment: "Orient section"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "activity.create.section.orient.footer",
                    defaultValue: "一张封面、一句局名，让人愿意点进你的线下局。",
                    comment: "Orient footer"
                )
            )
        }
    }

    @ViewBuilder
    private var coverPickerLabel: some View {
        if let coverPreviewImage {
            coverPreviewImage
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: SparkLayoutMetrics.activityCardHeroCornerRadius,
                        style: .continuous
                    )
                )
                .overlay {
                    if coverIsVideo {
                        Image(systemName: "play.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityHidden(true)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    changeCoverBadge
                }
        } else if coverIsVideo {
            RoundedRectangle(
                cornerRadius: SparkLayoutMetrics.activityCardHeroCornerRadius,
                style: .continuous
            )
            .fill(.quaternary)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .overlay {
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
            .overlay(alignment: .bottomTrailing) {
                changeCoverBadge
            }
        } else {
            Label(
                String(
                    localized: "activity.create.cover.add",
                    defaultValue: "上传局封面",
                    comment: "Add cover media"
                ),
                systemImage: "photo.on.rectangle"
            )
        }
    }

    private var changeCoverBadge: some View {
        Text(
            String(
                localized: "activity.create.cover.change",
                defaultValue: "更换封面",
                comment: "Change cover"
            )
        )
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .sparkGlassControl(Capsule())
        .padding(8)
    }
}

// MARK: - Decide (schedule · location · capacity)

private enum ActivityCreateCapacityChoice: Hashable {
    case preset(Int)
    case custom
}

struct ActivityCreateDecideSection: View {
    @Binding var draft: CreateActivityDraft
    @State private var capacityChoice: ActivityCreateCapacityChoice = .preset(CreateActivityDraft.defaultCapacity)
    @State private var customCapacityText = String(CreateActivityDraft.defaultCapacity)

    var body: some View {
        Section {
            ActivityCreateLocationField(locationName: $draft.locationName)

            ActivityCreateMeetupIconField(
                systemImage: "calendar",
                label: String(localized: "activity.create.startsAt", defaultValue: "见面时间", comment: "Create field")
            ) {
                DatePicker(
                    String(localized: "activity.create.startsAt", defaultValue: "见面时间", comment: "Create field"),
                    selection: $draft.startsAt,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(
                    String(localized: "activity.create.capacity", defaultValue: "几人局", comment: "Capacity picker")
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Picker(
                    String(localized: "activity.create.capacity", defaultValue: "几人局", comment: "Capacity picker"),
                    selection: $capacityChoice
                ) {
                    ForEach(CreateActivityDraft.smallGroupCapacityPresets, id: \.self) { count in
                        Text(capacityPresetLabel(count))
                            .tag(ActivityCreateCapacityChoice.preset(count))
                    }
                    Text(
                        String(
                            localized: "activity.create.capacity.custom",
                            defaultValue: "自定义",
                            comment: "Custom capacity"
                        )
                    )
                    .tag(ActivityCreateCapacityChoice.custom)
                }
                .pickerStyle(.segmented)
                .onChange(of: capacityChoice) { _, newValue in
                    applyCapacityChoice(newValue)
                }

                if case .custom = capacityChoice {
                    HStack(spacing: 8) {
                        TextField(
                            String(
                                localized: "activity.create.capacity.custom.placeholder",
                                defaultValue: "输入人数",
                                comment: "Custom capacity placeholder"
                            ),
                            text: $customCapacityText
                        )
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                        .onChange(of: customCapacityText) { _, newValue in
                            applyCustomCapacityText(newValue)
                        }
                        .accessibilityLabel(
                            String(
                                localized: "activity.create.capacity.custom.input.a11y",
                                defaultValue: "自定义人数",
                                comment: "Custom capacity input a11y"
                            )
                        )

                        Text(
                            String(
                                localized: "activity.create.capacity.unit",
                                defaultValue: "人",
                                comment: "Capacity unit"
                            )
                        )
                        .font(.body)
                        .foregroundStyle(.secondary)

                        Spacer(minLength: 0)
                    }
                }
            }
            .accessibilityElement(children: .contain)
        } header: {
            Text(
                String(
                    localized: "activity.create.section.decide",
                    defaultValue: "何时何地见",
                    comment: "Decide section"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "activity.create.section.decide.footer",
                    defaultValue: "选具体地点、定好时间，报名的人更放心。",
                    comment: "Decide footer"
                )
            )
        }
        .onAppear {
            syncCapacityStateFromDraft()
        }
        .onChange(of: draft.capacity) { _, _ in
            syncCapacityStateFromDraft()
        }
    }

    private func syncCapacityStateFromDraft() {
        let value = draft.capacity ?? CreateActivityDraft.defaultCapacity
        if CreateActivityDraft.smallGroupCapacityPresets.contains(value) {
            capacityChoice = .preset(value)
        } else {
            capacityChoice = .custom
            let clamped = min(
                max(value, CreateActivityDraft.minCapacity),
                CreateActivityDraft.maxCapacity
            )
            customCapacityText = String(clamped)
            draft.capacity = clamped
        }
    }

    private func applyCapacityChoice(_ choice: ActivityCreateCapacityChoice) {
        switch choice {
        case let .preset(count):
            draft.capacity = count
        case .custom:
            let seed = draft.capacity ?? CreateActivityDraft.defaultCapacity
            let clamped = min(
                max(seed, CreateActivityDraft.minCapacity),
                CreateActivityDraft.maxCapacity
            )
            customCapacityText = String(clamped)
            applyCustomCapacityText(customCapacityText)
        }
    }

    private func applyCustomCapacityText(_ text: String) {
        let filtered = String(text.filter(\.isWholeNumber))
        if filtered != text {
            customCapacityText = filtered
            return
        }
        guard !filtered.isEmpty, let value = Int(filtered) else { return }

        let clamped = min(
            max(value, CreateActivityDraft.minCapacity),
            CreateActivityDraft.maxCapacity
        )
        if String(clamped) != filtered {
            customCapacityText = String(clamped)
        }
        draft.capacity = clamped
    }

    private func capacityPresetLabel(_ count: Int) -> String {
        String(
            format: String(
                localized: "activity.create.capacity.preset.format",
                defaultValue: "%lld 人",
                comment: "Capacity preset; %lld is count"
            ),
            locale: .current,
            count
        )
    }
}

// MARK: - Understand (description)

struct ActivityCreateUnderstandSection: View {
    @Binding var draft: CreateActivityDraft
    @Binding var showsOptionalDescription: Bool

    var body: some View {
        Section {
            if showsOptionalDescription {
                TextField(
                    String(
                        localized: "activity.create.description.placeholder",
                        defaultValue: "集合方式、费用分摊、装备要求等",
                        comment: "Create description placeholder"
                    ),
                    text: $draft.description,
                    axis: .vertical
                )
                .lineLimit(3 ... 8)
                .textInputAutocapitalization(.sentences)

                if draft.description.count > CreateActivityDraft.maxDescriptionLength - 100 {
                    Text(descriptionCharacterCountLine)
                        .font(.caption)
                        .foregroundStyle(descriptionOverLimit ? .red : .secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                Button {
                    showsOptionalDescription = true
                } label: {
                    Label(
                        String(
                            localized: "activity.create.description.add",
                            defaultValue: "写几句详细说明（选填）",
                            comment: "Add optional description"
                        ),
                        systemImage: "text.alignleft"
                    )
                }
            }
        } header: {
            Text(
                String(
                    localized: "activity.create.section.understand",
                    defaultValue: "更多说明（选填）",
                    comment: "Understand section"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "activity.create.section.understand.footer",
                    defaultValue: "写清楚细节，见面时更省心；不填也能发布。",
                    comment: "Understand footer"
                )
            )
        }
        .onAppear {
            if !draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showsOptionalDescription = true
            }
        }
    }

    private var descriptionCharacterCountLine: String {
        String(
            format: String(
                localized: "activity.create.description.count.format",
                defaultValue: "%lld / %lld",
                comment: "Description char count"
            ),
            locale: .current,
            draft.description.count,
            CreateActivityDraft.maxDescriptionLength
        )
    }

    private var descriptionOverLimit: Bool {
        draft.description.count > CreateActivityDraft.maxDescriptionLength
    }
}

// MARK: - Shared icon row (detail schedule/location parity)

struct ActivityCreateMeetupIconField<Content: View>: View {
    let systemImage: String
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}
