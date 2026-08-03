//
//  EditProfileSheet.swift
//  坐标系
//
//  Apple 账户式个人资料编辑 + 环形完整度头像。
//

import PhotosUI
import SwiftUI
import UIKit

struct ProfileAvatarView: View {
    let user: AppUser
    var completion: Double? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ProfileCompletionAvatar(
            name: user.name,
            photo: user.localAvatarImage,
            side: dynamicTypeSize.detailRelatedThumbSide,
            completion: completion
        )
    }
}

struct ProfileCompletionAvatar: View {
    var name: String
    var photo: UIImage?
    var side: CGFloat
    var completion: Double?

    private let ringStart = 0.10
    private let ringEnd = 0.90

    private var normalizedCompletion: Double? {
        completion.map { min(max($0, 0), 1) }
    }

    private var percentage: Int? {
        normalizedCompletion.map { Int(($0 * 100).rounded()) }
    }

    private var ringLineWidth: CGFloat { PlatformMetrics.avatarBadgeStroke }
    private var progressLineWidth: CGFloat { PlatformMetrics.avatarBadgeStroke * 2 }
    private var avatarInset: CGFloat { PlatformMetrics.avatarBadgeStroke * 3 }

    var body: some View {
        ZStack {
            if let normalizedCompletion {
                Circle()
                    .trim(from: ringStart, to: ringEnd)
                    .stroke(
                        .quaternary,
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-135))

                Circle()
                    .trim(
                        from: ringStart,
                        to: ringStart + (ringEnd - ringStart) * normalizedCompletion
                    )
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: progressLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-135))
            }

            PlatformListAvatarView(name: name, photo: photo, side: side)
                .padding(avatarInset)
        }
        .frame(width: side + avatarInset * 2, height: side + avatarInset * 2)
        .overlay(alignment: .topLeading) {
            if let percentage {
                Text("\(percentage)%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(percentage == 100 ? PlatformStatus.success : .secondary)
                    .monospacedDigit()
                    .background(PlatformSurface.elevated, in: Capsule())
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("头像")
        .accessibilityValue(percentage.map { "资料完整度 \($0)%" } ?? "")
    }
}

struct EditProfileSheet: View {
    @Binding var user: AppUser
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var name = ""
    @State private var handle = ""
    @State private var city = ""
    @State private var bio = ""
    @State private var selectedInterests: Set<String> = []
    @State private var pickerItem: PhotosPickerItem?
    @State private var avatarPreview: UIImage?
    @State private var avatarLocalName: String?
    @State private var isPreparingAvatar = false

    private var completion: Double {
        ProfileCompletion.ratio(
            hasAvatar: avatarLocalName != nil,
            name: name,
            handle: handle,
            city: city,
            bio: bio,
            interestsCount: selectedInterests.count
        )
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isPreparingAvatar
            && InterestSelectionLimits.meetsMinimum(selectedInterests.count)
    }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                personalInfoSection
                locationSection
                favoritesSection
                bioSection
                identityIDSection
            }
            .navigationTitle("个人资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadDraft)
        }
        .platformSheet(.browser)
    }

    private var identitySection: some View {
        Section {
            VStack {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    ProfileCompletionAvatar(
                        name: name,
                        photo: avatarPreview,
                        side: dynamicTypeSize.detailRelatedThumbSide,
                        completion: completion
                    )
                }
                .buttonStyle(.plain)

                Text(name.isEmpty ? "坐标系用户" : name)
                    .font(.title3.weight(.semibold))

                if !handle.isEmpty {
                    Text(handle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                PhotosPicker(
                    avatarLocalName == nil ? "添加照片" : "更改照片",
                    selection: $pickerItem,
                    matching: .images
                )
                .font(.subheadline)

                if isPreparingAvatar {
                    ProgressView("正在处理头像…")
                }
            }
            .frame(maxWidth: .infinity)
            .onChange(of: pickerItem) { _, item in
                Task { await loadAvatar(item) }
            }
            .listRowBackground(Color.clear)
        } footer: {
            Text("头像、昵称和账号会展示在活动、社区和消息中。")
        }
    }

    private var personalInfoSection: some View {
        Section {
            LabeledContent("昵称") {
                TextField("你的昵称", text: $name)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("账号") {
                TextField("@username", text: $handle)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        } header: {
            Text("个人信息")
        }
    }

    private var locationSection: some View {
        Section {
            LabeledContent("常驻城市") {
                TextField("城市", text: $city)
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text("定位")
        } footer: {
            Text("城市仅保存在个人资料中，用于活动推荐与附近匹配，不在「我的」首页展示。")
        }
    }

    private var favoritesSection: some View {
        Section {
            InterestTaxonomyPicker(selected: $selectedInterests)
        } header: {
            Text("最喜欢")
        } footer: {
            Text(InterestSelectionLimits.progressText(count: selectedInterests.count)
                 + "。用于活动推荐与搭子匹配。")
        }
    }

    private var bioSection: some View {
        Section("简介") {
            TextField("介绍一下自己…", text: $bio, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var identityIDSection: some View {
        Section {
            LabeledContent("UID", value: user.publicUIDDisplay)
                .textSelection(.enabled)
            Button(MessagesCopy.copyUID) {
                UIPasteboard.general.string = user.publicUID
            }
        } header: {
            Text("对外 UID")
        } footer: {
            Text("9 位数字账号，可分享给朋友添加。登录或登出不会更换；注销账号后会重新分配。")
        }
    }

    private func loadDraft() {
        name = user.name
        handle = user.handle
        city = user.city
        bio = user.bio
        selectedInterests = Set(user.interests)
        avatarLocalName = user.avatarLocalName
        avatarPreview = user.localAvatarImage
    }

    private func save() {
        user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        user.handle = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        user.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        user.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        user.interests = Array(selectedInterests)
        if let avatarLocalName {
            if let old = user.avatarLocalName, old != avatarLocalName {
                CommunityPhotoStore.delete(named: old)
                PhotoVerificationStore.shared.clear()
            } else if user.avatarLocalName == nil {
                PhotoVerificationStore.shared.clear()
            }
            user.avatarLocalName = avatarLocalName
        }
        dismiss()
    }

    @MainActor
    private func loadAvatar(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isPreparingAvatar = true
        defer { isPreparingAvatar = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let saved = CommunityPhotoStore.saveJPEG(data)
        else { return }
        avatarPreview = image
        avatarLocalName = saved
    }
}
