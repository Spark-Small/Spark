//
//  PhotoVerificationView.swift
//  坐标系
//
//  形象认证：摄像头采集人脸 ↔ 资料认证照；本机通过后二次复核。
//

import CoordinateModels
import SwiftUI
import UIKit

struct PhotoVerificationView: View {
    @Environment(AppModel.self) private var app
    @Environment(TrustService.self) private var trust
    @Environment(YouthModeStore.self) private var youthMode
    @Environment(\.dismiss) private var dismiss
    @Environment(PhotoVerificationStore.self) private var photoVerification

    @State private var capture: UIImage?
    @State private var showCamera = false
    @State private var isAnalyzing = false
    @State private var outcome: PhotoVerificationEngine.Outcome?
    @State private var remoteNote: String?
    @State private var showEditProfile = false
    @State private var appealFeedback: String?

    private var store: PhotoVerificationStore { photoVerification }

    private var photosReady: Bool {
        app.user.hasVerificationPhotosReady
    }

    private var alreadyVerified: Bool {
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
        .navigationTitle("形象认证")
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
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(user: Binding(
                get: { app.user },
                set: { updated in app.updateProfile(updated) }
            ))
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .platformFeedbackAlert($appealFeedback)
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
            LabeledContent("二次复核", value: store.remoteVerified ? "已确认" : "本机结果")
        } header: {
            Text("形象认证")
        } footer: {
            Text("认证结果仅保存在本机。更换认证照后需重新核验；仅改「对外展示」不需重验。")
        }

        Section {
            Button("撤销形象认证", role: .destructive) {
                store.clear()
                outcome = nil
                capture = nil
                remoteNote = nil
            }
        }
    }

    @ViewBuilder
    private var unverifiedSections: some View {
        Section {
            Text("调起摄像头采集人脸，与个人资料中的认证照比对。通过后解锁报名、预约与消息等能力。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        if store.isInCooldown {
            Section {
                Label(
                    store.cooldownRemainingText ?? "冷却中",
                    systemImage: "clock.badge.exclamationmark"
                )
                .foregroundStyle(PlatformStatus.warning)
                Button("申诉误拦") {
                    submitIdentityAppeal()
                }
            } header: {
                Text("暂时无法核验")
            } footer: {
                Text("连续失败过多已进入冷却。若为误判，可提交申诉工单。")
            }
        }

        Section {
            if photosReady {
                ForEach(Array(app.user.verificationPhotos.enumerated()), id: \.element.id) { index, photo in
                    HStack {
                        Text("认证照 \(index + 1)")
                        Spacer()
                        if let image = loadImage(named: photo.localName) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityHidden(true)
                        }
                        Text(photo.isPublic ? "对外展示" : "仅核验")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("请先上传 1–2 张本人正脸认证照。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("去编辑资料") {
                    showEditProfile = true
                }
            }
        } header: {
            Text("比对基准")
        }

        Section {
            if let capture {
                HStack {
                    Text("已采集")
                    Spacer()
                    Image(uiImage: capture)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .accessibilityHidden(true)
                }
            }

            Button {
                showCamera = true
            } label: {
                Label(
                    capture == nil ? "打开摄像头采集" : "重新采集",
                    systemImage: "camera.viewfinder"
                )
                .platformContentSymbolStyle()
            }
            .disabled(!photosReady || isAnalyzing || app.auth.isGuest || store.isInCooldown)
        } header: {
            Text("摄像头采集")
        } footer: {
            Text("须使用摄像头现场采集，不可从相册选择。影像优先本机分析；二次复核在青少年模式下不上云。")
        }

        if let outcome, !outcome.passed {
            Section {
                ForEach(outcome.reasons, id: \.self) { reason in
                    Label(reason, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
                LabeledContent(
                    "相似度",
                    value: String(format: "%.0f%%", outcome.similarity * 100)
                )
                Button("申诉误拦") {
                    submitIdentityAppeal()
                }
            } header: {
                Text("未通过原因")
            }
        }

        if let remoteNote {
            Section {
                Text(remoteNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("二次复核")
            }
        }

        Section {
            Button {
                Task { await runVerification() }
            } label: {
                if isAnalyzing {
                    ProgressView()
                } else {
                    Text("开始核验")
                        .fontWeight(.semibold)
                }
            }
            .disabled(
                capture == nil
                    || !photosReady
                    || isAnalyzing
                    || app.auth.isGuest
                    || store.isInCooldown
            )
        } footer: {
            if app.auth.isGuest {
                Text(GuestAccessGate.identityReason)
            } else if !photosReady {
                Text(IdentityAccessGate.needPhotosReason)
            } else {
                Text("本机 Vision 比对通过后，将进行二次复核（演示代理或远程服务）。")
            }
        }
    }

    private func loadImage(named: String) -> UIImage? {
        guard let url = LocalMediaLibrary.fileURL(named: named),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }

    private func runVerification() async {
        guard let capture else { return }
        guard !store.isInCooldown else { return }
        let references = app.user.localVerificationImages()
        guard !references.isEmpty else { return }
        isAnalyzing = true
        defer { isAnalyzing = false }
        remoteNote = nil

        let result = await PhotoVerificationEngine.verify(references: references, capture: capture)
        outcome = result
        guard result.passed else {
            store.recordFailure(userKey: app.user.name)
            return
        }

        let remote = await IdentityRemoteReverifyService.reverify(
            userKey: app.user.name,
            baselineFingerprint: app.user.verificationBaselineFingerprint,
            localSimilarity: result.similarity,
            capture: capture,
            youthMode: youthMode.isEnabled
        )
        if let reason = remote.reason {
            remoteNote = reason
        }
        guard remote.passed else {
            outcome = PhotoVerificationEngine.Outcome(
                passed: false,
                similarity: remote.remoteScore,
                reasons: [remote.reason ?? "二次复核未通过，请重试。"]
            )
            store.recordFailure(userKey: app.user.name)
            return
        }

        store.markVerified(
            userKey: app.user.name,
            similarity: max(result.similarity, remote.remoteScore),
            photos: app.user.verificationPhotos,
            remoteVerified: true
        )
        trust.record(
            .profileCompletionChanged,
            domain: .account,
            actorKey: app.user.name,
            note: "photo_verified"
        )
        if remote.usedNetwork || remote.passed {
            trust.record(
                .identityRemoteVerified,
                domain: .moderation,
                actorKey: app.user.name,
                note: remote.usedNetwork ? "network" : "demo_proxy"
            )
        }
        app.pendingIdentityVerification = false
    }

    private func submitIdentityAppeal() {
        app.addModerationTicket(
            postID: app.user.id,
            title: "形象认证申诉 · \(app.user.name)",
            reason: "用户认为形象认证误判，申请人工复核。连续失败 \(store.consecutiveFailures) 次。",
            targetKind: .identityAppeal
        )
        appealFeedback = "已提交形象认证申诉，可在设置 → 举报与申诉中查看进度。"
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
