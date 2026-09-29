//
//  BuddyOrgReportSheet.swift
//  坐标系
//
//  圈子 / 工会投诉：Form 填写原因、说明与材料；提交后写入举报工单。
//

import CoordinateModels
import PhotosUI
import SwiftUI
import UIKit

nonisolated enum BuddyOrgReportCopy {
    static let targetLabel = "投诉对象"
    static let reasonLabel = "投诉原因"
    static let detailLabel = "情况说明"
    static let detailPlaceholder = "请描述问题，便于核查"
    static let detailFooter = "请尽量写清时间、场景与具体行为，避免仅写笼统评价。"
    static let evidenceLabel = "证明材料"
    static let evidenceAdd = "添加截图或照片"
    static func evidenceSelected(_ count: Int) -> String { "已选 \(count) 张，点击更换" }
    static let evidenceFooter = "可选；建议上传聊天记录、资料页截图等，最多 4 张。"
    static let submit = "提交投诉"
    static let submitFooter = "恶意投诉可能影响账号权限。提交前请确认材料与说明属实。"

    static func title(kind: OrgMembershipKind) -> String {
        kind == .circle ? "投诉俱乐部" : "投诉工会"
    }

    static func receivedMessage(kind: OrgMembershipKind) -> String {
        kind == .circle
            ? "我们已收到对该俱乐部的反馈，将尽快核查。可在「设置 → 举报记录」查看进度。"
            : "我们已收到对该工会的反馈，将尽快核查。可在「设置 → 举报记录」查看进度。"
    }
}

struct BuddyOrgReportSheet: View {
    let targetName: String
    let kind: OrgMembershipKind
    var onSubmit: (_ reason: String, _ detail: String, _ evidenceCount: Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var reason = MessagesCopy.reportReasons[0]
    @State private var detail = ""
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var previewImages: [UIImage] = []

    private let maxEvidence = 4

    private var trimmedDetail: String {
        detail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !trimmedDetail.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent(BuddyOrgReportCopy.targetLabel, value: targetName)
                }

                Section {
                    Picker(BuddyOrgReportCopy.reasonLabel, selection: $reason) {
                        ForEach(MessagesCopy.reportReasons, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text(BuddyOrgReportCopy.reasonLabel)
                }

                Section {
                    TextField(BuddyOrgReportCopy.detailPlaceholder, text: $detail, axis: .vertical)
                        .lineLimit(4...8)
                } header: {
                    Text(BuddyOrgReportCopy.detailLabel)
                } footer: {
                    Text(BuddyOrgReportCopy.detailFooter)
                }

                Section {
                    let evidencePickerTitle = PlatformPhotosPickerCopy.evidenceLabel(
                        count: previewImages.count,
                        emptyTitle: BuddyOrgReportCopy.evidenceAdd,
                        selectedTitle: BuddyOrgReportCopy.evidenceSelected
                    )
                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: maxEvidence,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(evidencePickerTitle, systemImage: "photo.on.rectangle.angled")
                    }
                    .onChange(of: pickerItems) { _, items in
                        Task { await loadEvidence(items) }
                    }

                    if !previewImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: PlatformMetrics.hairlineSpacing) {
                                ForEach(Array(previewImages.enumerated()), id: \.offset) { index, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(
                                            width: PlatformMetrics.detailRelatedThumb,
                                            height: PlatformMetrics.detailRelatedThumb
                                        )
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: PlatformMetrics.radiusMedia,
                                                style: .continuous
                                            )
                                        )
                                        .accessibilityLabel("证据 \(index + 1)")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                } header: {
                    Text(BuddyOrgReportCopy.evidenceLabel)
                } footer: {
                    Text(BuddyOrgReportCopy.evidenceFooter)
                }

                Section {
                    Button(BuddyOrgReportCopy.submit, role: .destructive) {
                        onSubmit(reason, trimmedDetail, previewImages.count)
                        dismiss()
                    }
                    .disabled(!canSubmit)
                } footer: {
                    Text(BuddyOrgReportCopy.submitFooter)
                }
            }
            .navigationTitle(BuddyOrgReportCopy.title(kind: kind))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .platformSheet(.form)
    }

    @MainActor
    private func loadEvidence(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items.prefix(maxEvidence) {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else { continue }
            images.append(image)
        }
        previewImages = images
    }
}
