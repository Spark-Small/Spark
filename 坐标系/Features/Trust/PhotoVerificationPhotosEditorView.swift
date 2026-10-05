//
//  PhotoVerificationPhotosEditorView.swift
//  坐标系
//
//  防欺诈认证：Sheet 内添加 / 管理比对用认证照（即时写入 app.user）。
//

import CoordinateModels
import PhotosUI
import SwiftUI
import UIKit

struct PhotoVerificationPhotosEditorView: View {
    @Environment(AppModel.self) private var app
    @Environment(PhotoVerificationStore.self) private var photoVerification

    @State private var draftPhotos: [VerificationPhoto] = []
    @State private var pickerItem: PhotosPickerItem?
    @State private var isPreparing = false
    @State private var baselineFingerprintAtLoad = ""
    @State private var moderationAlert: String?

    private var canAdd: Bool {
        draftPhotos.count < VerificationPhotoLimits.maxCount
    }

    var body: some View {
        Form {
            Section {
                ForEach(Array(draftPhotos.enumerated()), id: \.element.id) { index, photo in
                    HStack(spacing: PlatformMetrics.cardInfoSpacing) {
                        if let image = preview(named: photo.localName) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: PlatformConversationListRow.imageSide,
                                    height: PlatformConversationListRow.imageSide
                                )
                                .clipShape(PlatformMetrics.mediaShape)
                                .accessibilityHidden(true)
                        }

                        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                            Text("\(EditProfileCopy.verificationPhotoTitlePrefix) \(index + 1)")
                                .font(.subheadline.weight(.semibold))
                            Toggle(
                                EditProfileCopy.verificationPhotoPublic,
                                isOn: bindingIsPublic(at: index)
                            )
                        }

                        Spacer(minLength: 0)

                        Button(EditProfileCopy.verificationPhotoDelete, role: .destructive) {
                            remove(at: index)
                        }
                        .font(.footnote)
                    }
                }

                if canAdd {
                    // PhotosPicker label 为 Sendable 闭包：标题先落到局部常量。
                    let addTitle = draftPhotos.isEmpty
                        ? EditProfileCopy.addVerificationPhoto
                        : EditProfileCopy.addAnotherVerificationPhoto
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(addTitle, systemImage: "plus.circle")
                    }
                    .disabled(isPreparing)
                    .onChange(of: pickerItem) { _, item in
                        Task { await load(item) }
                    }
                }

                if isPreparing {
                    ProgressView()
                }
            } header: {
                Text(EditProfileCopy.verificationPhotosHeader)
            } footer: {
                Text(EditProfileCopy.verificationPhotosEditorFooter)
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle(EditProfileCopy.verificationPhotosHeader)
        .navigationBarTitleDisplayMode(.inline)
        .platformFeedbackAlert($moderationAlert)
        .onAppear {
            draftPhotos = app.user.verificationPhotos
            baselineFingerprintAtLoad = app.user.verificationBaselineFingerprint
        }
    }

    private func bindingIsPublic(at index: Int) -> Binding<Bool> {
        Binding(
            get: {
                guard draftPhotos.indices.contains(index) else { return false }
                return draftPhotos[index].isPublic
            },
            set: { newValue in
                guard draftPhotos.indices.contains(index) else { return }
                draftPhotos[index].isPublic = newValue
                commit()
            }
        )
    }

    private func preview(named: String) -> UIImage? {
        guard let url = LocalMediaLibrary.fileURL(named: named),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }

    private func remove(at index: Int) {
        guard draftPhotos.indices.contains(index) else { return }
        draftPhotos.remove(at: index)
        commit()
    }

    private func commit() {
        let previousNames = Set(app.user.verificationPhotos.map(\.localName))
        let nextPhotos = Array(draftPhotos.prefix(VerificationPhotoLimits.maxCount))
        let nextNames = Set(nextPhotos.map(\.localName))
        for name in previousNames where !nextNames.contains(name) {
            LocalMediaLibrary.delete(named: name)
        }

        var updated = app.user
        updated.verificationPhotos = nextPhotos
        app.updateProfile(updated)
        draftPhotos = nextPhotos

        let nextFingerprint = VerificationPhotoLimits.baselineFingerprint(for: nextPhotos)
        if nextFingerprint != baselineFingerprintAtLoad {
            photoVerification.invalidateIfBaselineChanged(photos: nextPhotos)
            if nextPhotos.isEmpty {
                photoVerification.clear()
            } else if !photoVerification.isVerified(for: updated.name, photos: nextPhotos) {
                app.pendingIdentityVerification = true
            }
            baselineFingerprintAtLoad = nextFingerprint
        }
    }

    @MainActor
    private func load(_ item: PhotosPickerItem?) async {
        guard let item, canAdd else { return }
        isPreparing = true
        defer {
            isPreparing = false
            pickerItem = nil
        }
        guard let data = try? await item.loadTransferable(type: Data.self),
              UIImage(data: data) != nil
        else { return }
        let decision = await MediaModerationService.moderateImageData(
            data,
            context: .verificationPhoto,
            actorKey: app.user.name
        )
        if case .block(let reason) = decision {
            moderationAlert = reason
            return
        }
        guard let saved = LocalMediaLibrary.saveJPEG(data) else { return }
        draftPhotos.append(VerificationPhoto(localName: saved, isPublic: false))
        commit()
    }
}
