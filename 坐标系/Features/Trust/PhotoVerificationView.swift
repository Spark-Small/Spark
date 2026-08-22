//
//  PhotoVerificationView.swift
//  坐标系
//
//  形象认证流程：自拍 / 选图 → 本机 Vision 与头像比对（Bumble 式防冒用）。
//

import PhotosUI
import SwiftUI
import UIKit

struct PhotoVerificationView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var selfie: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isAnalyzing = false
    @State private var outcome: PhotoVerificationEngine.Outcome?
    @State private var showEditProfile = false

    private var store: PhotoVerificationStore { .shared }

    private var hasCustomAvatar: Bool {
        app.user.avatarLocalName != nil && app.user.localAvatarImage != nil
    }

    private var alreadyVerified: Bool {
        store.isVerified(for: app.user.name)
    }

    var body: some View {
        Form {
            if alreadyVerified {
                Section {
                    LabeledContent("状态", value: "已通过")
                    if let at = store.verifiedAt {
                        LabeledContent("通过时间", value: Formatters.conversationListTime(from: at))
                    }
                    LabeledContent(
                        "相似度",
                        value: String(format: "%.0f%%", store.lastSimilarity * 100)
                    )
                } header: {
                    Text("形象认证")
                } footer: {
                    Text("认证结果仅保存在本机；更换头像后建议重新核验。")
                }

                Section {
                    Button("撤销形象认证", role: .destructive) {
                        store.clear()
                        outcome = nil
                        selfie = nil
                    }
                }
            } else {
                Section {
                    Text("拍摄一张正脸自拍，系统会在本机与你的头像比对。通过后点亮「形象认证」，降低冒用、盗图风险。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    if let photo = app.user.localAvatarImage, hasCustomAvatar {
                        HStack {
                            Text("当前头像")
                            Spacer()
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                                .accessibilityHidden(true)
                        }
                    } else {
                        Text("请先在个人资料中上传本人正脸头像。")
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
                    if let selfie {
                        HStack {
                            Text("待核验自拍")
                            Spacer()
                            Image(uiImage: selfie)
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
                        Label("拍摄自拍", systemImage: "camera.viewfinder")
                            .platformContentSymbolStyle()
                    }
                    .disabled(!hasCustomAvatar || isAnalyzing || app.auth.isGuest)

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("从相册选择", systemImage: "photo.on.rectangle")
                            .platformContentSymbolStyle()
                    }
                    .disabled(!hasCustomAvatar || isAnalyzing || app.auth.isGuest)
                } header: {
                    Text("自拍")
                } footer: {
                    Text("请本人出镜、正对镜头、光线充足；影像只在本机分析，不会上传。")
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
                    } header: {
                        Text("未通过原因")
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
                    .disabled(selfie == nil || !hasCustomAvatar || isAnalyzing || app.auth.isGuest)
                } footer: {
                    if app.auth.isGuest {
                        Text(GuestAccessGate.identityReason)
                    } else {
                        Text("基于 Apple Vision 本机人脸检测与特征点比对；正式版可再叠加活体检测。")
                    }
                }
            }
        }
        .navigationTitle("形象认证")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: pickerItem) { _, item in
            Task { await loadPicker(item) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            PhotoVerificationCameraPicker(
                onImage: { image in
                    selfie = image
                    outcome = nil
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
    }

    private func loadPicker(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else { return }
        selfie = image
        outcome = nil
    }

    private func runVerification() async {
        guard let selfie,
              let profile = app.user.localAvatarImage,
              hasCustomAvatar
        else { return }
        isAnalyzing = true
        defer { isAnalyzing = false }
        let result = await PhotoVerificationEngine.verify(profile: profile, selfie: selfie)
        outcome = result
        if result.passed {
            store.markVerified(userKey: app.user.name, similarity: result.similarity)
            TrustService.shared.record(
                .profileCompletionChanged,
                domain: .account,
                actorKey: app.user.name,
                note: "photo_verified"
            )
        }
    }
}
