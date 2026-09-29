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
    /// 搭子页「也想找」快速状态
    public var lookingFor: String
    /// Documents 下本地头像文件名（展示用，不作核验基准）
    public var avatarLocalName: String? = nil
    /// 认证照 1–2 张：摄像头比对基准；`isPublic` 控制是否对外展示
    public var verificationPhotos: [VerificationPhoto] = []
    /// 语音介绍时长（秒）；nil 表示未录制
    public var voiceIntroDuration: Double? = nil
    /// 语音条副文案（可选）
    public var voiceIntroCaption: String? = nil

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
        avatarLocalName: String? = nil,
        verificationPhotos: [VerificationPhoto] = [],
        voiceIntroDuration: Double? = nil,
        voiceIntroCaption: String? = nil
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
        self.lookingFor = lookingFor
        self.avatarLocalName = avatarLocalName
        self.verificationPhotos = Array(verificationPhotos.prefix(VerificationPhotoLimits.maxCount))
        self.voiceIntroDuration = voiceIntroDuration
        self.voiceIntroCaption = voiceIntroCaption
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
        lookingFor = try container.decodeIfPresent(String.self, forKey: .lookingFor) ?? ""
        avatarLocalName = try container.decodeIfPresent(String.self, forKey: .avatarLocalName)
        verificationPhotos = try container.decodeIfPresent(
            [VerificationPhoto].self,
            forKey: .verificationPhotos
        ) ?? []
        voiceIntroDuration = try container.decodeIfPresent(Double.self, forKey: .voiceIntroDuration)
        voiceIntroCaption = try container.decodeIfPresent(String.self, forKey: .voiceIntroCaption)
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
}
