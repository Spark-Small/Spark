//
//  EditProfileSheet.swift
//  坐标系
//
//  Apple 账户式个人资料编辑 + 环形完整度头像。
//

import PhotosUI
import SwiftUI
import UIKit
import CoordinateModels

struct ProfileAvatarView: View {
    let user: AppUser

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ProfileCompletionAvatar(
            name: user.name,
            photo: user.localAvatarImage,
            side: dynamicTypeSize.detailRelatedThumbSide,
            completion: ProfileCompletion.ratio(for: user)
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
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(percentage == 100 ? PlatformStatus.success : .secondary)
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(PlatformSurface.elevated, in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    .offset(x: -4, y: -4)
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
    @Environment(AppModel.self) private var app
    @Environment(PhotoVerificationStore.self) private var photoVerification

    @State private var name = ""
    @State private var handle = ""
    @State private var city = ""
    @State private var bio = ""
    @State private var lookingFor = ""
    @State private var selectedInterests: Set<String> = []
    @State private var pickerItem: PhotosPickerItem?
    @State private var avatarPreview: UIImage?
    @State private var avatarLocalName: String?
    @State private var isPreparingAvatar = false
    @State private var showVoiceIntroRecorder = false
    @State private var voiceIntroDuration: Double?
    @State private var voiceIntroCaption = ""
    @State private var draftVerificationPhotos: [VerificationPhoto] = []
    @State private var verificationPickerItem: PhotosPickerItem?
    @State private var isPreparingVerificationPhoto = false
    @State private var baselineFingerprintAtLoad = ""
    @State private var moderationAlert: String?

    private var completion: Double {
        ProfileCompletion.ratio(
            hasAvatar: avatarLocalName != nil,
            name: name,
            handle: handle,
            city: city,
            bio: bio,
            lookingFor: lookingFor,
            interestsCount: selectedInterests.count
        )
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isPreparingAvatar
            && !isPreparingVerificationPhoto
            && InterestSelectionLimits.meetsMinimum(selectedInterests.count)
    }

    private var canAddVerificationPhoto: Bool {
        draftVerificationPhotos.count < VerificationPhotoLimits.maxCount
    }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                verificationPhotosSection
                personalInfoSection
                locationSection
                favoritesSection
                voiceIntroSection
                bioSection
                lookingForSection
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
            .sheet(isPresented: $showVoiceIntroRecorder) {
                BuddyVoiceIntroRecorderSheet(
                    initialDuration: voiceIntroDuration,
                    initialCaption: voiceIntroCaption,
                    onSave: { duration, caption in
                        voiceIntroDuration = duration
                        voiceIntroCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
                    },
                    onRemove: {
                        voiceIntroDuration = nil
                        voiceIntroCaption = ""
                    }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .platformSheet(.browser)
        .platformFeedbackAlert($moderationAlert)
    }

    private var identitySection: some View {
        // Apple 账号头区：单行内 VStack（默认 spacing），勿拆成多行以免变成 List 行距。
        Section {
            VStack {
                ProfileCompletionAvatar(
                    name: name,
                    photo: avatarPreview,
                    side: dynamicTypeSize.accountHeaderAvatarSide,
                    completion: completion
                )

                let avatarActionTitle = avatarLocalName == nil ? "添加照片" : "更改照片"
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label(avatarActionTitle, systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.plain)

                Text(name.isEmpty ? "坐标系用户" : name)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                if isPreparingAvatar {
                    ProgressView()
                        .controlSize(.regular)
                }
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .onChange(of: pickerItem) { _, item in
                Task { await loadAvatar(item) }
            }
        }
    }

    private var verificationPhotosSection: some View {
        Section {
            ForEach(Array(draftVerificationPhotos.enumerated()), id: \.element.id) { index, photo in
                HStack(spacing: PlatformMetrics.cardInfoSpacing) {
                    if let image = verificationPreview(named: photo.localName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .accessibilityHidden(true)
                    }

                    VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                        Text("认证照 \(index + 1)")
                            .font(.subheadline.weight(.semibold))
                        Toggle("对外展示", isOn: bindingIsPublic(at: index))
                    }

                    Spacer(minLength: 0)

                    Button("删除", role: .destructive) {
                        removeVerificationPhoto(at: index)
                    }
                    .font(.footnote)
                }
            }

            if canAddVerificationPhoto {
                let verificationActionTitle = draftVerificationPhotos.isEmpty ? "添加认证照" : "再加一张"
                PhotosPicker(selection: $verificationPickerItem, matching: .images) {
                    Label(verificationActionTitle, systemImage: "plus.circle")
                }
                .disabled(isPreparingVerificationPhoto)
                .onChange(of: verificationPickerItem) { _, item in
                    Task { await loadVerificationPhoto(item) }
                }
            }

            if isPreparingVerificationPhoto {
                ProgressView()
            }
        } header: {
            Text("认证照片")
        } footer: {
            Text("上传 1–2 张本人正脸照，用于摄像头人脸核验。关闭「对外展示」后其他人看不到，但仍用于安全核验。头像可另行设置，不参与比对。")
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
        }
    }

    private var favoritesSection: some View {
        Section {
            NavigationLink {
                InterestTaxonomyFormEditor(selected: $selectedInterests)
            } label: {
                LabeledContent("兴趣标签") {
                    Text(
                        selectedInterests.isEmpty
                            ? "未选择"
                            : "\(selectedInterests.count) 项"
                    )
                    .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("最喜欢")
        }
    }

    private var voiceIntroSection: some View {
        Section {
            Button {
                showVoiceIntroRecorder = true
            } label: {
                LabeledContent(BuddyVoiceIntroCopy.editRowTitle) {
                    Text(
                        VoiceIntroPresentation.hasIntro(voiceIntroDuration)
                            ? VoiceIntroPresentation.durationText(voiceIntroDuration)
                            : BuddyVoiceIntroCopy.editEmptyValue
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .accessibilityHint(BuddyVoiceIntroCopy.editAddTitle)
        } header: {
            Text(BuddyVoiceIntroCopy.publicSectionTitle)
        }
    }

    private var bioSection: some View {
        Section {
            TextField("介绍一下自己…", text: $bio, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("简介")
        }
    }

    private var lookingForSection: some View {
        Section {
            TextField("找搭子一起玩什么…", text: $lookingFor)
        } header: {
            Text("搭子宣言")
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
        }
    }

    private func loadDraft() {
        name = user.name
        handle = user.handle
        city = user.city
        bio = user.bio
        lookingFor = user.lookingFor
        selectedInterests = Set(user.interests)
        avatarLocalName = user.avatarLocalName
        avatarPreview = user.localAvatarImage
        voiceIntroDuration = user.voiceIntroDuration
        voiceIntroCaption = user.voiceIntroCaption ?? ""
        draftVerificationPhotos = user.verificationPhotos
        baselineFingerprintAtLoad = user.verificationBaselineFingerprint
    }

    private func bindingIsPublic(at index: Int) -> Binding<Bool> {
        Binding(
            get: {
                guard draftVerificationPhotos.indices.contains(index) else { return false }
                return draftVerificationPhotos[index].isPublic
            },
            set: { newValue in
                guard draftVerificationPhotos.indices.contains(index) else { return }
                draftVerificationPhotos[index].isPublic = newValue
            }
        )
    }

    private func verificationPreview(named: String) -> UIImage? {
        guard let url = LocalMediaLibrary.fileURL(named: named),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }

    private func removeVerificationPhoto(at index: Int) {
        guard draftVerificationPhotos.indices.contains(index) else { return }
        let removed = draftVerificationPhotos.remove(at: index)
        let existedOnUser = user.verificationPhotos.contains { $0.id == removed.id }
        if !existedOnUser {
            LocalMediaLibrary.delete(named: removed.localName)
        }
    }

    private func save() {
        let combined = [name, handle, bio, lookingFor, voiceIntroCaption].joined(separator: "\n")
        if case .block(let reason) = ContentModeration.scanText(combined) {
            moderationAlert = reason
            return
        }
        user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        user.handle = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        user.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        user.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        user.lookingFor = lookingFor.trimmingCharacters(in: .whitespacesAndNewlines)
        user.interests = Array(selectedInterests)
        user.voiceIntroDuration = voiceIntroDuration
        let trimmedCaption = voiceIntroCaption.trimmingCharacters(in: .whitespacesAndNewlines)
        user.voiceIntroCaption = trimmedCaption.isEmpty ? nil : trimmedCaption
        if let avatarLocalName {
            if let old = user.avatarLocalName, old != avatarLocalName {
                LocalMediaLibrary.delete(named: old)
            }
            user.avatarLocalName = avatarLocalName
        }

        let previousNames = Set(user.verificationPhotos.map(\.localName))
        let nextPhotos = Array(draftVerificationPhotos.prefix(VerificationPhotoLimits.maxCount))
        let nextNames = Set(nextPhotos.map(\.localName))
        for name in previousNames where !nextNames.contains(name) {
            LocalMediaLibrary.delete(named: name)
        }
        user.verificationPhotos = nextPhotos

        let nextFingerprint = VerificationPhotoLimits.baselineFingerprint(for: nextPhotos)
        if nextFingerprint != baselineFingerprintAtLoad {
            photoVerification.invalidateIfBaselineChanged(photos: nextPhotos)
            if nextPhotos.isEmpty {
                photoVerification.clear()
            } else if !photoVerification.isVerified(for: user.name, photos: nextPhotos) {
                app.pendingIdentityVerification = true
            }
        }

        dismiss()
    }

    @MainActor
    private func loadAvatar(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isPreparingAvatar = true
        defer { isPreparingAvatar = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else { return }
        let decision = await MediaModerationService.moderateImageData(
            data,
            context: .avatar,
            actorKey: user.name
        )
        if case .block(let reason) = decision {
            moderationAlert = reason
            return
        }
        guard let saved = LocalMediaLibrary.saveJPEG(data) else { return }
        avatarPreview = image
        avatarLocalName = saved
    }

    @MainActor
    private func loadVerificationPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard canAddVerificationPhoto else { return }
        isPreparingVerificationPhoto = true
        defer {
            isPreparingVerificationPhoto = false
            verificationPickerItem = nil
        }
        guard let data = try? await item.loadTransferable(type: Data.self),
              UIImage(data: data) != nil
        else { return }
        let decision = await MediaModerationService.moderateImageData(
            data,
            context: .verificationPhoto,
            actorKey: user.name
        )
        if case .block(let reason) = decision {
            moderationAlert = reason
            return
        }
        guard let saved = LocalMediaLibrary.saveJPEG(data) else { return }
        draftVerificationPhotos.append(
            VerificationPhoto(localName: saved, isPublic: false)
        )
    }
}
