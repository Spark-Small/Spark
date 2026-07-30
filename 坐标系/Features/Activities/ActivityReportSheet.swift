//
//  ActivityReportSheet.swift
//  坐标系
//
//  活动举报：Form 填写原因、说明与材料；提交后 Alert 收尾确认。
//

import PhotosUI
import SwiftUI
import UIKit

struct ActivityReportSheet: View {
    let activity: Activity
    var onSubmit: (_ reason: String, _ detail: String, _ evidenceCount: Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var reason = ActivityDetailCopy.reportReasons[0]
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
                    LabeledContent(ActivityDetailCopy.reportTargetLabel) {
                        Text(activity.title)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("发起人", value: activity.hostName)
                }

                Section {
                    Picker(ActivityDetailCopy.reportReasonLabel, selection: $reason) {
                        ForEach(ActivityDetailCopy.reportReasons, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text(ActivityDetailCopy.reportReasonLabel)
                }

                Section {
                    TextField(ActivityDetailCopy.reportDetailPlaceholder, text: $detail, axis: .vertical)
                        .lineLimit(4...8)
                } header: {
                    Text(ActivityDetailCopy.reportDetailLabel)
                } footer: {
                    Text(ActivityDetailCopy.reportDetailFooter)
                }

                Section {
                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: maxEvidence,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(
                            previewImages.isEmpty
                                ? ActivityDetailCopy.reportEvidenceAdd
                                : ActivityDetailCopy.reportEvidenceSelected(previewImages.count),
                            systemImage: "photo.on.rectangle.angled"
                        )
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
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .accessibilityLabel("证据 \(index + 1)")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                } header: {
                    Text(ActivityDetailCopy.reportEvidenceLabel)
                } footer: {
                    Text(ActivityDetailCopy.reportEvidenceFooter)
                }

                Section {
                    Button(ActivityDetailCopy.reportSubmit, role: .destructive) {
                        onSubmit(reason, trimmedDetail, previewImages.count)
                        dismiss()
                    }
                    .disabled(!canSubmit)
                } footer: {
                    Text(ActivityDetailCopy.reportSubmitFooter)
                }
            }
            .navigationTitle(ActivityDetailCopy.reportAction)
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
