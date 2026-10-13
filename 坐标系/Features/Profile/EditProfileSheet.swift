//
//  EditProfileSheet.swift
//  坐标系
//
//  个人资料编辑：系统 / Sheet 返回；Trailing 保存；本机写入。
//

import PhotosUI
import SwiftUI
import UIKit
import CoordinateModels

struct EditProfileSheet: View {
    @Binding var user: AppUser
    /// `true`：自带 NavigationStack + sheet chrome（门闸 / 设置入口）；`false`：嵌入现有 NavigationStack（「我的」根 disclosure）。
    var embedsOwnNavigationChrome = true

    @Environment(\.dismiss) var dismiss
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    /// 跨文件扩展需 internal。
    @Environment(AppModel.self) var app
    @Environment(PhotoVerificationStore.self) var photoVerification

    @State var name = ""
    @State var handle = ""
    @State var city = ""
    @State var bio = ""
    @State var gender: ProfileGender?
    @State var age: Int?
    /// 身高/体重：Form 右侧数字 TextField；保存时解析为 Int?。
    @State var heightText = ""
    @State var weightText = ""
    @State var availability = ""
    @State var draftPrompts: [ProfilePrompt] = []
    @State var occupation: ProfileOccupation?
    @State var meetRadius: ProfileMeetRadius?
    @State var mbti: ProfileMBTI?
    @State var zodiac: ProfileZodiac?
    @State var pendingPromptDraft = ProfilePrompt(
        promptKey: ProfilePromptCatalog.keys.first ?? "weekPlan",
        answer: ""
    )
    @State var selectedInterests: Set<String> = []
    @State var pickerItem: PhotosPickerItem?
    @State var avatarPreview: UIImage?
    @State var avatarLocalName: String?
    @State var isPreparingAvatar = false
    /// 编辑页不再提供自定义录音 UI；保存时原样写回，避免误清已有语音介绍。
    @State var voiceIntroDuration: Double?
    @State var voiceIntroCaption = ""
    @State var moderationAlert: String?
    @State var showBindPhoneSheet = false
    @State private var didLoadDraft = false
    @State private var didSaveSuccessfully = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isPreparingAvatar
            && InterestSelectionLimits.meetsMinimum(selectedInterests.count)
            && ProfileEditLimits.isHandleFormatOK(handle)
    }

    private var identityGateBanner: some View {
        Section {
            Text(IdentityAccessGate.needPhotosReason(for: app.pendingIdentityGateSource))
                .font(.body)
                .foregroundStyle(.primary)
        } header: {
            Text(IdentityAccessGate.editProfileSectionHeader(for: app.pendingIdentityGateSource))
        }
    }

    var body: some View {
        Group {
            if embedsOwnNavigationChrome {
                NavigationStack {
                    formChrome
                }
                .platformSheet(.form)
            } else {
                formChrome
            }
        }
        .platformFeedbackAlert($moderationAlert)
    }

    private var formChrome: some View {
        Form {
            if app.pendingIdentityEditProfile {
                identityGateBanner
            }
            // Settings 序：身份头 → 介绍 → 基本事实 → 问答 → 兴趣 → 安全。
            identityHeroSection
            aboutYouSection
            demographicsSection
            promptsSection
            favoritesSection
            verificationSection
        }
        // 去掉 Form 默认 top contentMargins（否则头像离顶栏偏高）；分节距仍系统默认。
        .profileSecondaryListChrome(flushTop: true)
        .navigationTitle(EditProfileCopy.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if embedsOwnNavigationChrome {
                ToolbarItem(placement: .topBarLeading) {
                    Button(EditProfileCopy.back, systemImage: "chevron.backward") {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(EditProfileCopy.save, action: save)
                    .fontWeight(.semibold)
                    .disabled(!canSave)
            }
        }
        .sheet(isPresented: $showBindPhoneSheet) {
            BindPhoneSheet()
                .environment(app)
        }
        .onAppear {
            guard !didLoadDraft else { return }
            loadDraft()
            didLoadDraft = true
        }
        .onChange(of: user.isRealNameVerified) { _, _ in
            gender = user.gender
            age = user.age
        }
        .onChange(of: user.gender) { _, value in
            gender = value
        }
        .onChange(of: user.age) { _, value in
            age = value
        }
        .onDisappear {
            // 系统返回 / 下滑关闭：未保存则清会话新头像（push 子页时父视图通常仍存活）。
            guard !didSaveSuccessfully else { return }
            discardAvatarDraftIfNeeded()
        }
    }

    private func loadDraft() {
        name = user.name
        handle = ProfileEditLimits.normalizeHandle(user.handle)
        city = user.city
        bio = user.bio
        gender = user.gender
        age = user.age
        heightText = user.heightCM.map(String.init) ?? ""
        weightText = user.weightKG.map(String.init) ?? ""
        availability = user.availability
        draftPrompts = user.prompts
        occupation = user.occupation
        meetRadius = user.meetRadius
        mbti = user.mbti
        zodiac = user.displayZodiac ?? user.zodiac
        selectedInterests = Set(user.interests)
        avatarLocalName = user.avatarLocalName
        avatarPreview = user.localAvatarImage
        voiceIntroDuration = user.voiceIntroDuration
        voiceIntroCaption = user.voiceIntroCaption ?? ""
    }

    private func save() {
        let combined = [name, handle, bio, voiceIntroCaption].joined(separator: "\n")
        if case .block(let reason) = ContentModeration.scanText(combined) {
            moderationAlert = reason
            return
        }
        user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        user.handle = ProfileEditLimits.normalizeHandle(handle)
        user.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        user.bio = ProfileEditLimits.clamped(
            bio.trimmingCharacters(in: .whitespacesAndNewlines),
            max: ProfileEditLimits.bioMax
        )
        // 性别 / 年龄仅实名流程写入；保存时不手改。
        if user.isRealNameVerified, let birthDate = user.birthDate {
            user.age = AppUser.normalizedAge(AppUser.ageYears(from: birthDate))
            gender = user.gender
            age = user.age
        } else {
            user.gender = nil
            user.age = nil
            user.birthDate = nil
            gender = nil
            age = nil
        }
        user.heightCM = ProfileEditLimits.parsedHeightCM(heightText)
        user.weightKG = ProfileEditLimits.parsedWeightKG(weightText)
        user.availability = ProfileEditLimits.clamped(
            availability.trimmingCharacters(in: .whitespacesAndNewlines),
            max: ProfileDemographicsLimits.availabilityMax
        )
        // 意图不在个人资料编辑；保存时不改写 `user.intents`。
        user.prompts = ProfilePromptLimits.clamped(draftPrompts)
        user.occupation = occupation
        user.meetRadius = meetRadius
        user.mbti = mbti
        // 有生日则星座以推导为准，不另存手选冲突值。
        if let birthDate = user.birthDate {
            user.zodiac = ProfileZodiac.from(birthDate: birthDate)
        } else {
            user.zodiac = zodiac
        }
        user.interests = Array(selectedInterests)
        user.voiceIntroDuration = voiceIntroDuration
        let trimmedCaption = voiceIntroCaption.trimmingCharacters(in: .whitespacesAndNewlines)
        user.voiceIntroCaption = trimmedCaption.isEmpty ? nil : trimmedCaption

        if avatarLocalName != user.avatarLocalName {
            if let old = user.avatarLocalName {
                LocalMediaLibrary.delete(named: old)
            }
            user.avatarLocalName = avatarLocalName
        }

        didSaveSuccessfully = true
        dismiss()
    }

    private func discardAvatarDraftIfNeeded() {
        if let avatarLocalName,
           avatarLocalName != user.avatarLocalName {
            LocalMediaLibrary.delete(named: avatarLocalName)
        }
    }
}
