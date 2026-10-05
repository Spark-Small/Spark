//
//  PhotoVerificationView+Unverified.swift
//  坐标系
//

import CoordinateModels
import SwiftUI

extension PhotoVerificationView {
    @ViewBuilder
    var unverifiedSections: some View {
        Section {
            Text(IdentityAccessGate.needCaptureReason(for: app.pendingIdentityGateSource))
                .font(.subheadline)
                .foregroundStyle(.primary)
            Text(IdentityAccessGate.captureMissingNextStep(for: app.pendingIdentityGateSource))
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text(IdentityAccessGate.captureSectionHeader(for: app.pendingIdentityGateSource))
        } footer: {
            Text(EditProfileCopy.photoVerificationPageFooter)
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
                Text("请先添加 1–2 张本人正脸认证照。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                showPhotosEditor = true
            } label: {
                Label(
                    photosReady
                        ? EditProfileCopy.manageVerificationPhotos
                        : EditProfileCopy.addVerificationPhoto,
                    systemImage: "person.crop.rectangle.stack"
                )
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
                Task { await presentCameraIfAllowed() }
            } label: {
                Label(
                    capture == nil ? "打开摄像头采集" : "重新采集",
                    systemImage: "camera.viewfinder"
                )
                .platformContentSymbolStyle()
            }
            .disabled(isAnalyzing || store.isInCooldown)
        } header: {
            Text("摄像头采集")
        } footer: {
            Text(
                photosReady
                    ? "须使用摄像头现场采集，不可从相册选择。影像优先本机分析；二次复核在青少年模式下不上云。"
                    : PhotoVerificationCameraCopy.photosMissingMessage
            )
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
                    || store.isInCooldown
            )
        } footer: {
            if !photosReady {
                Text(IdentityAccessGate.needPhotosReason(for: app.pendingIdentityGateSource))
            } else {
                Text("本机 Vision 比对通过后，将进行二次复核（演示代理或远程服务）。")
            }
        }
    }
}
