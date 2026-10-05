//
//  PhotoVerificationView.swift
//  坐标系
//
//  防欺诈认证：摄像头采集人脸 ↔ 认证照；本机通过后二次复核。
//

import CoordinateFeatureFlags
import CoordinateModels
import SwiftUI
import UIKit

struct PhotoVerificationView: View {
    @Environment(AppModel.self) var app
    @Environment(TrustService.self) var trust
    @Environment(YouthModeStore.self) var youthMode
    @Environment(\.dismiss) var dismiss
    @Environment(PhotoVerificationStore.self) var photoVerification

    @State var capture: UIImage?
    @State var showCamera = false
    @State var isAnalyzing = false
    @State var outcome: PhotoVerificationEngine.Outcome?
    @State var remoteNote: String?
    @State var appealFeedback: String?
    @State var showCameraAccessAlert = false
    @State var cameraAccessOffersSettings = false
    @State var cameraAccessTitle = ""
    @State var cameraAccessMessage = ""
    @State var showPhotosEditor = false

    var store: PhotoVerificationStore { photoVerification }

    var photosReady: Bool {
        app.user.hasVerificationPhotosReady
    }

    var alreadyVerified: Bool {
        store.isVerified(for: app.user)
    }

    var body: some View {
        Form {
            if alreadyVerified {
                verifiedSections
            } else {
                unverifiedSections
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle(EditProfileCopy.photoVerificationLabel)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            PhotoVerificationCameraPicker(
                onImage: { image in
                    capture = image
                    outcome = nil
                    remoteNote = nil
                    showCamera = false
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotosEditor) {
            NavigationStack {
                PhotoVerificationPhotosEditorView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(EditProfileCopy.photosEditorDone) {
                                showPhotosEditor = false
                            }
                            .fontWeight(.semibold)
                        }
                    }
            }
            .platformSheet(.form)
            .environment(app)
            .environment(photoVerification)
        }
        .platformFeedbackAlert($appealFeedback)
        .alert(cameraAccessTitle, isPresented: $showCameraAccessAlert) {
            if cameraAccessOffersSettings {
                Button(PhotoVerificationCameraCopy.openSettings) {
                    PhotoVerificationCameraAccess.openSystemSettings()
                }
            }
            Button(PhotoVerificationCameraCopy.dismiss, role: .cancel) {}
        } message: {
            Text(cameraAccessMessage)
        }
    }

    @ViewBuilder
    private var verifiedSections: some View {
        Section {
            LabeledContent("状态", value: "已通过")
            if let at = store.verifiedAt {
                LabeledContent("通过时间", value: Formatters.conversationListTime(from: at))
            }
            LabeledContent(
                "相似度",
                value: String(format: "%.0f%%", store.lastSimilarity * 100)
            )
            LabeledContent("二次复核", value: remoteVerificationLabel)
        } header: {
            Text(EditProfileCopy.photoVerificationLabel)
        } footer: {
            Text(EditProfileCopy.photoVerificationPageFooter + "\n" + remoteVerificationFooter)
        }

        Section {
            Button {
                showPhotosEditor = true
            } label: {
                Label(EditProfileCopy.manageVerificationPhotos, systemImage: "person.crop.rectangle.stack")
            }
        } header: {
            Text(EditProfileCopy.verificationPhotosHeader)
        } footer: {
            Text("更换认证照后需重新核验；仅改「对外展示」不需重验。")
        }

        Section {
            Button("撤销防欺诈认证", role: .destructive) {
                store.clear()
                outcome = nil
                capture = nil
                remoteNote = nil
            }
        }
    }

    var remoteVerificationLabel: String {
        if store.remoteVerified {
            return "服务端已确认"
        }
        #if DEBUG
        if FeatureFlags.useDemoIdentityReverifyProxy {
            return "演示代理（本机）"
        }
        #endif
        return "本机结果"
    }

    var remoteVerificationFooter: String {
        if store.remoteVerified {
            return "二次复核已由服务端确认。认证投影保存在本机；更换认证照后需重新核验。"
        }
        return "当前为本地核验结果（未记服务端确认）。更换认证照后需重新核验；仅改「对外展示」不需重验。"
    }
}

/// 门禁触发时的导航包装，便于 Sheet 呈现。
struct IdentityVerificationSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PhotoVerificationView()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") { dismiss() }
                    }
                }
        }
        .platformSheet(.browser)
    }
}
