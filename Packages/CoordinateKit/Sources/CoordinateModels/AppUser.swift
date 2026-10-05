import Foundation

public struct AppUser: Codable, Hashable, Identifiable, Sendable {
    /// 本机稳定用户 UUID（游客与登录用户共用）
    public var id: UUID
    public var name: String
    public var handle: String
    public var city: String
    public var bio: String
    public var joinedCount: Int
    public var hostedCount: Int
    public var buddyCount: Int
    public var interests: [String]
    /// 遗留展示串：搭子卡 / 远程 DTO 仍可读；编辑页写入 `intents` 时同步镜像。
    public var lookingFor: String
    /// 「我想怎么玩」意图（≤2）
    public var intents: [ProfileIntent]
    /// Prompt 卡片（≤3）
    public var prompts: [ProfilePrompt]
    /// 轻量身份
    public var occupation: ProfileOccupation?
    /// 出行半径
    public var meetRadius: ProfileMeetRadius?
    /// MBTI 自填标签（非官方测评背书）
    public var mbti: ProfileMBTI? = nil
    /// 手选星座；有 `birthDate` 时展示优先用推导结果
    public var zodiac: ProfileZodiac? = nil
    /// Documents 下本地头像文件名（展示用，不作核验基准）
    public var avatarLocalName: String? = nil
    /// 生活照片墙：本机文件名列表（详情页展示；远程开启后可对他人投影文件名）
    public var galleryLocalNames: [String] = []
    /// 认证照 1–2 张：摄像头比对基准；`isPublic` 控制是否对外展示
    public var verificationPhotos: [VerificationPhoto] = []
    /// 语音介绍时长（秒）；nil 表示未录制
    public var voiceIntroDuration: Double? = nil
    /// 语音条副文案（可选）
    public var voiceIntroCaption: String? = nil
    /// 对外性别；nil = 未录入（详情不展示）
    public var gender: ProfileGender? = nil
    /// 对外年龄；nil / ≤0 = 未录入
    public var age: Int? = nil
    /// 身高 cm；nil / ≤0 = 未录入
    public var heightCM: Int? = nil
    /// 体重 kg；nil / ≤0 = 未录入
    public var weightKG: Int? = nil
    /// 档期 / 可约说明（与搭子详情「档期」同源）
    public var availability: String = ""
    /// 出生日期（实名证件解析后写入；年龄由此推算）
    public var birthDate: Date? = nil
    /// 本机实名是否已完成（证件识别；非公安库核验）
    public var isRealNameVerified: Bool = false
    public var realNameVerifiedAt: Date? = nil
    /// 证件号 SHA256（不存明文；身份证或护照号）
    public var idNumberFingerprint: String? = nil
    /// 脱敏展示如 **************1234
    public var idNumberMasked: String? = nil
    /// 实名所用证件类型
    public var realNameDocumentKind: RealNameDocumentKind? = nil
    public var idCardFrontLocalName: String? = nil
    public var idCardBackLocalName: String? = nil
    /// 护照资料页本机文件名
    public var passportDataPageLocalName: String? = nil

    public init(
        id: UUID = UUID(),
        name: String,
        handle: String,
        city: String,
        bio: String,
        joinedCount: Int,
        hostedCount: Int,
        buddyCount: Int,
        interests: [String] = [],
        lookingFor: String = "",
        intents: [ProfileIntent] = [],
        prompts: [ProfilePrompt] = [],
        occupation: ProfileOccupation? = nil,
        meetRadius: ProfileMeetRadius? = nil,
        mbti: ProfileMBTI? = nil,
        zodiac: ProfileZodiac? = nil,
        avatarLocalName: String? = nil,
        galleryLocalNames: [String] = [],
        verificationPhotos: [VerificationPhoto] = [],
        voiceIntroDuration: Double? = nil,
        voiceIntroCaption: String? = nil,
        gender: ProfileGender? = nil,
        age: Int? = nil,
        heightCM: Int? = nil,
        weightKG: Int? = nil,
        availability: String = "",
        birthDate: Date? = nil,
        isRealNameVerified: Bool = false,
        realNameVerifiedAt: Date? = nil,
        idNumberFingerprint: String? = nil,
        idNumberMasked: String? = nil,
        realNameDocumentKind: RealNameDocumentKind? = nil,
        idCardFrontLocalName: String? = nil,
        idCardBackLocalName: String? = nil,
        passportDataPageLocalName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.city = city
        self.bio = bio
        self.joinedCount = joinedCount
        self.hostedCount = hostedCount
        self.buddyCount = buddyCount
        self.interests = interests
        let clampedIntents = ProfileIntentLimits.clamped(intents)
        self.intents = clampedIntents
        self.lookingFor = Self.mirroredLookingFor(intents: clampedIntents, legacy: lookingFor)
        self.prompts = ProfilePromptLimits.clamped(prompts)
        self.occupation = occupation
        self.meetRadius = meetRadius
        self.mbti = mbti
        self.zodiac = zodiac
        self.avatarLocalName = avatarLocalName
        self.galleryLocalNames = ProfileGalleryLimits.clamped(galleryLocalNames)
        self.verificationPhotos = Array(verificationPhotos.prefix(VerificationPhotoLimits.maxCount))
        self.voiceIntroDuration = voiceIntroDuration
        self.voiceIntroCaption = voiceIntroCaption
        self.birthDate = birthDate
        self.isRealNameVerified = isRealNameVerified
        self.realNameVerifiedAt = realNameVerifiedAt
        self.idNumberFingerprint = idNumberFingerprint
        self.idNumberMasked = idNumberMasked
        self.realNameDocumentKind = realNameDocumentKind
        self.idCardFrontLocalName = idCardFrontLocalName
        self.idCardBackLocalName = idCardBackLocalName
        self.passportDataPageLocalName = passportDataPageLocalName
        self.availability = availability
        if isRealNameVerified, let birthDate {
            self.gender = gender
            self.age = Self.normalizedAge(Self.ageYears(from: birthDate))
        } else {
            self.gender = gender
            self.age = Self.normalizedAge(age)
        }
        self.heightCM = Self.normalizedHeight(heightCM)
        self.weightKG = Self.normalizedWeight(weightKG)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        handle = try container.decode(String.self, forKey: .handle)
        city = try container.decode(String.self, forKey: .city)
        bio = try container.decode(String.self, forKey: .bio)
        joinedCount = try container.decode(Int.self, forKey: .joinedCount)
        hostedCount = try container.decode(Int.self, forKey: .hostedCount)
        buddyCount = try container.decode(Int.self, forKey: .buddyCount)
        interests = try container.decodeIfPresent([String].self, forKey: .interests) ?? []
        let legacyLookingFor = try container.decodeIfPresent(String.self, forKey: .lookingFor) ?? ""
        let decodedIntents = try container.decodeIfPresent([ProfileIntent].self, forKey: .intents) ?? []
        intents = ProfileIntentLimits.clamped(decodedIntents)
        lookingFor = Self.mirroredLookingFor(intents: intents, legacy: legacyLookingFor)
        prompts = ProfilePromptLimits.clamped(
            try container.decodeIfPresent([ProfilePrompt].self, forKey: .prompts) ?? []
        )
        occupation = try container.decodeIfPresent(ProfileOccupation.self, forKey: .occupation)
        meetRadius = try container.decodeIfPresent(ProfileMeetRadius.self, forKey: .meetRadius)
        mbti = try container.decodeIfPresent(ProfileMBTI.self, forKey: .mbti)
        zodiac = try container.decodeIfPresent(ProfileZodiac.self, forKey: .zodiac)
        avatarLocalName = try container.decodeIfPresent(String.self, forKey: .avatarLocalName)
        galleryLocalNames = ProfileGalleryLimits.clamped(
            try container.decodeIfPresent([String].self, forKey: .galleryLocalNames) ?? []
        )
        verificationPhotos = try container.decodeIfPresent(
            [VerificationPhoto].self,
            forKey: .verificationPhotos
        ) ?? []
        voiceIntroDuration = try container.decodeIfPresent(Double.self, forKey: .voiceIntroDuration)
        voiceIntroCaption = try container.decodeIfPresent(String.self, forKey: .voiceIntroCaption)
        gender = try container.decodeIfPresent(ProfileGender.self, forKey: .gender)
        age = Self.normalizedAge(try container.decodeIfPresent(Int.self, forKey: .age))
        heightCM = Self.normalizedHeight(try container.decodeIfPresent(Int.self, forKey: .heightCM))
        weightKG = Self.normalizedWeight(try container.decodeIfPresent(Int.self, forKey: .weightKG))
        availability = try container.decodeIfPresent(String.self, forKey: .availability) ?? ""
        birthDate = try container.decodeIfPresent(Date.self, forKey: .birthDate)
        isRealNameVerified = try container.decodeIfPresent(Bool.self, forKey: .isRealNameVerified) ?? false
        realNameVerifiedAt = try container.decodeIfPresent(Date.self, forKey: .realNameVerifiedAt)
        idNumberFingerprint = try container.decodeIfPresent(String.self, forKey: .idNumberFingerprint)
        idNumberMasked = try container.decodeIfPresent(String.self, forKey: .idNumberMasked)
        realNameDocumentKind = try container.decodeIfPresent(
            RealNameDocumentKind.self,
            forKey: .realNameDocumentKind
        )
        idCardFrontLocalName = try container.decodeIfPresent(String.self, forKey: .idCardFrontLocalName)
        idCardBackLocalName = try container.decodeIfPresent(String.self, forKey: .idCardBackLocalName)
        passportDataPageLocalName = try container.decodeIfPresent(
            String.self,
            forKey: .passportDataPageLocalName
        )
        if isRealNameVerified, let birthDate {
            age = Self.normalizedAge(Self.ageYears(from: birthDate)) ?? age
        }
        if isRealNameVerified, realNameDocumentKind == nil {
            realNameDocumentKind = .chineseResidentID
        }
    }

    /// 证件识别成功后写入性别/出生日期，并锁定实名态。
    public mutating func applyRealName(_ result: RealNameDemographicsResult, now: Date = .now) {
        gender = result.gender
        birthDate = result.birthDate
        age = Self.normalizedAge(result.age)
        idNumberFingerprint = result.idNumberFingerprint
        idNumberMasked = result.idNumberMasked
        realNameDocumentKind = result.documentKind
        isRealNameVerified = true
        realNameVerifiedAt = now
    }

    public static func ageYears(from birthDate: Date, now: Date = .now) -> Int {
        Calendar(identifier: .gregorian).dateComponents([.year], from: birthDate, to: now).year ?? 0
    }

    public var publicVerificationPhotos: [VerificationPhoto] {
        verificationPhotos.filter(\.isPublic)
    }

    public var hasVerificationPhotosReady: Bool {
        VerificationPhotoLimits.isReady(verificationPhotos)
    }

    public var verificationBaselineFingerprint: String {
        VerificationPhotoLimits.baselineFingerprint(for: verificationPhotos)
    }

    /// 详情头徽章：性别与年龄都已录入才显示。
    public var hasGenderAgeBadge: Bool {
        gender != nil && (age ?? 0) > 0
    }

    /// 基本资料区：任一项已录入则展示对应行。
    public var hasPublicDemographics: Bool {
        gender != nil
            || (age ?? 0) > 0
            || (heightCM ?? 0) > 0
            || (weightKG ?? 0) > 0
            || !availability.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || occupation != nil
            || meetRadius != nil
            || mbti != nil
            || displayZodiac != nil
    }

    /// 对外星座：出生日期推导优先，否则手选。
    public var displayZodiac: ProfileZodiac? {
        if let birthDate { return ProfileZodiac.from(birthDate: birthDate) }
        return zodiac
    }

    /// 意图展示行（chips 优先，遗留 lookingFor 回落）。
    public var intentDisplayLine: String {
        ProfileIntentLimits.displayLine(intents: intents, legacyLookingFor: lookingFor)
    }

    /// 编辑意图后同步遗留串，供搭子卡 / 远程 DTO 兼容。
    public mutating func applyIntents(_ values: [ProfileIntent]) {
        intents = ProfileIntentLimits.clamped(values)
        lookingFor = Self.mirroredLookingFor(intents: intents, legacy: "")
    }

    private static func mirroredLookingFor(intents: [ProfileIntent], legacy: String) -> String {
        if !intents.isEmpty {
            return intents.map(\.rawValue).joined(separator: " · ")
        }
        return legacy.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func normalizedAge(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return min(max(value, ProfileDemographicsLimits.ageMin), ProfileDemographicsLimits.ageMax)
    }

    private static func normalizedHeight(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return min(max(value, ProfileDemographicsLimits.heightMin), ProfileDemographicsLimits.heightMax)
    }

    private static func normalizedWeight(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return min(max(value, ProfileDemographicsLimits.weightMin), ProfileDemographicsLimits.weightMax)
    }
}

public enum ProfileDemographicsLimits {
    public static let ageMin = 18
    public static let ageMax = 80
    public static let heightMin = 140
    public static let heightMax = 220
    public static let weightMin = 35
    public static let weightMax = 150
    public static let availabilityMax = 40
}
