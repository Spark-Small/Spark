//
//  RealNameVerificationSheet.swift
//  坐标系
//
//  实名认证：滚轮选证件 → 本机 OCR → 写入性别/年龄（只读）。
//

import CoordinateModels
import PhotosUI
import SwiftUI
import UIKit

struct RealNameVerificationSheet: View {
    @Binding var user: AppUser
    var embedsOwnNavigationChrome = true

    @Environment(\.dismiss) var dismiss
    @Environment(TrustService.self) var trust

    @State var documentKind: RealNameDocumentKind = .chineseResidentID
    @State var frontItem: PhotosPickerItem?
    @State var backItem: PhotosPickerItem?
    @State var passportItem: PhotosPickerItem?
    @State var frontImage: UIImage?
    @State var backImage: UIImage?
    @State var passportImage: UIImage?
    @State var frontLocalName: String?
    @State var backLocalName: String?
    @State var passportLocalName: String?
    @State var isRecognizing = false
    @State var alertMessage: String?
    @State var previewResult: RealNameDemographicsResult?

    var body: some View {
        Group {
            if embedsOwnNavigationChrome {
                NavigationStack { formBody }
                    .platformSheet(.form)
            } else {
                formBody
            }
        }
        .platformFeedbackAlert($alertMessage)
    }

    private var formBody: some View {
        Form {
            if user.isRealNameVerified {
                verifiedSections
            } else {
                documentKindSection
                captureSections
                if let previewResult {
                    previewSection(previewResult)
                }
                submitSection
            }
        }
        .navigationTitle(RealNameVerificationCopy.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if embedsOwnNavigationChrome {
                ToolbarItem(placement: .cancellationAction) {
                    Button(EditProfileCopy.back) { dismiss() }
                }
            }
        }
        .onAppear(perform: restorePersistedMedia)
        .onChange(of: documentKind) { _, _ in
            previewResult = nil
        }
    }

    private var verifiedSections: some View {
        Section {
            if let kind = user.realNameDocumentKind {
                LabeledContent(RealNameVerificationCopy.documentKindLabel, value: kind.displayName)
            }
            LabeledContent(
                RealNameVerificationCopy.genderFromID,
                value: user.gender?.rawValue ?? "—"
            )
            if let age = user.age {
                LabeledContent(
                    RealNameVerificationCopy.ageFromID,
                    value: RealNameVerificationCopy.ageValue(age)
                )
            }
            if let masked = user.idNumberMasked {
                LabeledContent(RealNameVerificationCopy.maskedLabel, value: masked)
                    .textSelection(.enabled)
            }
        } header: {
            Text(RealNameVerificationCopy.verifiedBadge)
        } footer: {
            Text(footerCopy(for: user.realNameDocumentKind ?? .chineseResidentID))
        }
    }

    private var documentKindSection: some View {
        Section {
            Picker(RealNameVerificationCopy.documentKindHeader, selection: $documentKind) {
                ForEach(RealNameDocumentKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
            .accessibilityLabel(RealNameVerificationCopy.documentKindHeader)
        } header: {
            Text(RealNameVerificationCopy.documentKindHeader)
        } footer: {
            Text(RealNameVerificationCopy.documentKindFooter)
        }
    }

    @ViewBuilder
    private var captureSections: some View {
        switch documentKind {
        case .chineseResidentID:
            Section {
                idFaceRow(
                    title: RealNameVerificationCopy.frontTitle,
                    image: frontImage,
                    pickerItem: $frontItem,
                    emptyLabel: RealNameVerificationCopy.addFront,
                    changeLabel: RealNameVerificationCopy.changeFront,
                    onPick: { await loadFront($0) }
                )
                idFaceRow(
                    title: RealNameVerificationCopy.backTitle,
                    image: backImage,
                    pickerItem: $backItem,
                    emptyLabel: RealNameVerificationCopy.addBack,
                    changeLabel: RealNameVerificationCopy.changeBack,
                    onPick: { await loadBack($0) }
                )
            } header: {
                Text(RealNameVerificationCopy.idSectionHeader)
            } footer: {
                Text(RealNameVerificationCopy.idFooter)
            }
        case .passport:
            Section {
                idFaceRow(
                    title: RealNameVerificationCopy.passportPageTitle,
                    image: passportImage,
                    pickerItem: $passportItem,
                    emptyLabel: RealNameVerificationCopy.addPassportPage,
                    changeLabel: RealNameVerificationCopy.changePassportPage,
                    onPick: { await loadPassport($0) }
                )
            } header: {
                Text(RealNameVerificationCopy.passportSectionHeader)
            } footer: {
                Text(RealNameVerificationCopy.passportFooter)
            }
        }
    }

    private func previewSection(_ result: RealNameDemographicsResult) -> some View {
        Section(RealNameVerificationCopy.previewHeader) {
            LabeledContent(
                RealNameVerificationCopy.documentKindLabel,
                value: result.documentKind.displayName
            )
            LabeledContent(
                RealNameVerificationCopy.genderFromID,
                value: result.gender.rawValue
            )
            LabeledContent(
                RealNameVerificationCopy.ageFromID,
                value: RealNameVerificationCopy.ageValue(result.age)
            )
            LabeledContent(
                RealNameVerificationCopy.maskedLabel,
                value: result.idNumberMasked
            )
        }
    }

    private var submitSection: some View {
        Section {
            Button {
                Task { await recognizeAndApply() }
            } label: {
                if isRecognizing {
                    Label(RealNameVerificationCopy.submitting, systemImage: "ellipsis")
                } else {
                    Text(RealNameVerificationCopy.submit)
                }
            }
            .disabled(!canSubmit || isRecognizing)
        }
    }

    private var canSubmit: Bool {
        switch documentKind {
        case .chineseResidentID:
            frontImage != nil && backImage != nil
        case .passport:
            passportImage != nil
        }
    }

    func footerCopy(for kind: RealNameDocumentKind) -> String {
        switch kind {
        case .chineseResidentID: RealNameVerificationCopy.idFooter
        case .passport: RealNameVerificationCopy.passportFooter
        }
    }

    @ViewBuilder
    func idFaceRow(
        title: String,
        image: UIImage?,
        pickerItem: Binding<PhotosPickerItem?>,
        emptyLabel: String,
        changeLabel: String,
        onPick: @escaping (PhotosPickerItem?) async -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 160)
                    .clipShape(PlatformMetrics.mediaShape)
                    .accessibilityHidden(true)
            }
            PhotosPicker(
                selection: pickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(image == nil ? emptyLabel : changeLabel, systemImage: "doc.viewfinder")
            }
            .onChange(of: pickerItem.wrappedValue) { _, item in
                Task { await onPick(item) }
            }
        }
        .padding(.vertical, 4)
    }
}
