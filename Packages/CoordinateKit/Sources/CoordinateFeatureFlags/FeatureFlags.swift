//
//  FeatureFlags.swift
//  CoordinateFeatureFlags
//
//  演示 / 远程能力开关集中管理；Release 默认保守，DEBUG 可覆盖。
//

import Foundation

public enum FeatureFlags {
    /// 远程活动目录同步（`RemoteActivitiesRepository`）。
    public static var useRemoteCatalog: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: Keys.useRemoteCatalog)
        #else
        false
        #endif
    }

    /// 本地样例目录合并（`AppPersistence.refreshCatalogIfNeeded`）。
    /// Release：远程目录未作真相源时保持 true；DEBUG 可关以验证空库 / 远程合并。
    public static var useLocalCatalogBootstrap: Bool {
        #if DEBUG
        if UserDefaults.standard.object(forKey: Keys.useLocalCatalogBootstrap) != nil {
            return UserDefaults.standard.bool(forKey: Keys.useLocalCatalogBootstrap)
        }
        return true
        #else
        true
        #endif
    }

    /// 远程资料同步（`RemoteProfileRepository`）。
    public static var useRemoteProfile: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: Keys.useRemoteProfile)
        #else
        false
        #endif
    }

    /// 远程消息同步（`RemoteMessagesRepository`）。Release 恒尝试远程；DEBUG 可关。
    public static var useRemoteMessages: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: Keys.useRemoteMessages)
        #else
        true
        #endif
    }

    /// 远程广场同步（`RemoteCommunityRepository`）。
    public static var useRemoteCommunity: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: Keys.useRemoteCommunity)
        #else
        false
        #endif
    }

    /// 远程搭子同步（`RemoteBuddiesRepository`）。Release 恒尝试远程；DEBUG 可关。
    public static var useRemoteBuddies: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: Keys.useRemoteBuddies)
        #else
        true
        #endif
    }

    /// 搭子写路径（邀约 / 俱乐部远程提交）。契约已备；Release / DEBUG 默认关，接通后端后再开。
    public static var useRemoteBuddiesWrite: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: Keys.useRemoteBuddiesWrite)
        #else
        false
        #endif
    }

    /// 发现页使用 `SampleData` 人设目录。Release 恒关闭（避免与虚构人设交易）。
    /// DEBUG：远程搭子关着时始终开样例（避免联调一键关掉 Sample 后永久空页）；远程开着时尊重显式开关。
    public static var useSampleBuddiesCatalog: Bool {
        #if DEBUG
        if !useRemoteBuddies {
            return true
        }
        if UserDefaults.standard.object(forKey: Keys.useSampleBuddiesCatalog) != nil {
            return UserDefaults.standard.bool(forKey: Keys.useSampleBuddiesCatalog)
        }
        return true
        #else
        false
        #endif
    }

    /// 登录走后端短信 JWT（`AuthTokenStore`）。Release 恒开启；DEBUG 可用开关切回演示码。
    public static var useRemoteAuth: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: Keys.useRemoteAuth)
        #else
        true
        #endif
    }

    /// 本地演示：提交预约后自动模拟陪玩接单（约 4 秒）。Release 恒关闭。
    public static var simulateBookingCompanionAcceptance: Bool {
        #if DEBUG
        if UserDefaults.standard.object(forKey: Keys.simulateBookingCompanionAcceptance) != nil {
            return UserDefaults.standard.bool(forKey: Keys.simulateBookingCompanionAcceptance)
        }
        return true
        #else
        false
        #endif
    }

    /// 登录用户使用报名 / 预约 / 消息前须完成认证照 + 摄像头人脸核验。
    public static var requireIdentityVerification: Bool {
        #if DEBUG
        if UserDefaults.standard.object(forKey: Keys.requireIdentityVerification) != nil {
            return UserDefaults.standard.bool(forKey: Keys.requireIdentityVerification)
        }
        return true
        #else
        true
        #endif
    }

    /// 上传图走内容安全审核（本机启发式 + 可选远程 / 演示代理）。
    public static var useMediaModeration: Bool {
        #if DEBUG
        if UserDefaults.standard.object(forKey: Keys.useMediaModeration) != nil {
            return UserDefaults.standard.bool(forKey: Keys.useMediaModeration)
        }
        return true
        #else
        true
        #endif
    }

    /// 无真实 Private Detector 服务时，用本机代理模拟服务端打分。Release 恒关闭。
    public static var useDemoModerationProxy: Bool {
        #if DEBUG
        if UserDefaults.standard.object(forKey: Keys.useDemoModerationProxy) != nil {
            return UserDefaults.standard.bool(forKey: Keys.useDemoModerationProxy)
        }
        return true
        #else
        false
        #endif
    }

    /// 远程审核不可用时是否拒绝上传（正式环境建议 true）。
    public static var mediaModerationFailClosed: Bool {
        #if DEBUG
        if UserDefaults.standard.object(forKey: Keys.mediaModerationFailClosed) != nil {
            return UserDefaults.standard.bool(forKey: Keys.mediaModerationFailClosed)
        }
        return false
        #else
        true
        #endif
    }

    /// 本机比对通过后再做联网 / 演示代理二次复核。
    public static var useRemoteIdentityReverify: Bool {
        #if DEBUG
        if UserDefaults.standard.object(forKey: Keys.useRemoteIdentityReverify) != nil {
            return UserDefaults.standard.bool(forKey: Keys.useRemoteIdentityReverify)
        }
        return true
        #else
        true
        #endif
    }

    /// 无真实复核服务时，用更严本机阈值模拟服务端确认。Release 恒关闭。
    public static var useDemoIdentityReverifyProxy: Bool {
        #if DEBUG
        if UserDefaults.standard.object(forKey: Keys.useDemoIdentityReverifyProxy) != nil {
            return UserDefaults.standard.bool(forKey: Keys.useDemoIdentityReverifyProxy)
        }
        return true
        #else
        false
        #endif
    }

    /// 五域快照走 SwiftData；关闭则回退 JSON。
    public static var useSwiftDataSnapshots: Bool {
        #if DEBUG
        if UserDefaults.standard.object(forKey: Keys.useSwiftDataSnapshots) != nil {
            return UserDefaults.standard.bool(forKey: Keys.useSwiftDataSnapshots)
        }
        if UserDefaults.standard.object(forKey: Keys.useSwiftDataActivities) != nil {
            return UserDefaults.standard.bool(forKey: Keys.useSwiftDataActivities)
        }
        #endif
        return true
    }

    /// 兼容旧开关名。
    public static var useSwiftDataActivities: Bool { useSwiftDataSnapshots }

    #if DEBUG
    public static func setUseRemoteCatalog(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useRemoteCatalog)
    }

    public static func setUseRemoteProfile(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useRemoteProfile)
    }

    public static func setUseRemoteMessages(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useRemoteMessages)
    }

    public static func setUseRemoteCommunity(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useRemoteCommunity)
    }

    public static func setUseRemoteBuddies(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useRemoteBuddies)
    }

    public static func setUseRemoteBuddiesWrite(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useRemoteBuddiesWrite)
    }

    public static func setUseSampleBuddiesCatalog(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useSampleBuddiesCatalog)
    }

    public static func setUseRemoteAuth(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useRemoteAuth)
    }

    public static func setUseLocalCatalogBootstrap(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useLocalCatalogBootstrap)
    }

    /// 一键打开读路径联调：活动 / 广场 / 资料 / 搭子 snapshot + 远程登录；关 Sample 与演示接单。
    public static func enableReadPathRemoteIntegration() {
        setUseRemoteCatalog(true)
        setUseRemoteCommunity(true)
        setUseRemoteProfile(true)
        setUseRemoteBuddies(true)
        setUseRemoteAuth(true)
        setUseLocalCatalogBootstrap(false)
        setUseSampleBuddiesCatalog(false)
        setSimulateBookingCompanionAcceptance(false)
        // 写路径仍默认关；后端邀约/俱乐部就绪后另调 `setUseRemoteBuddiesWrite(true)`
    }

    /// DEBUG：关远程搭子、开样例货架（找回「找搭子」模拟目录）。
    public static func restoreLocalBuddiesSampleCatalog() {
        setUseRemoteBuddies(false)
        setUseRemoteBuddiesWrite(false)
        setUseSampleBuddiesCatalog(true)
        setSimulateBookingCompanionAcceptance(true)
    }

    /// 搭子读+写联调（需后端 snapshot + invites/clubs 已通）。
    public static func enableBuddiesRemoteIntegration() {
        setUseRemoteBuddies(true)
        setUseRemoteBuddiesWrite(true)
        setUseSampleBuddiesCatalog(false)
        setSimulateBookingCompanionAcceptance(false)
    }

    public static func setSimulateBookingCompanionAcceptance(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.simulateBookingCompanionAcceptance)
    }

    public static func setUseSwiftDataSnapshots(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useSwiftDataSnapshots)
    }

    public static func setUseSwiftDataActivities(_ enabled: Bool) {
        setUseSwiftDataSnapshots(enabled)
    }

    public static func setRequireIdentityVerification(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.requireIdentityVerification)
    }

    public static func setUseMediaModeration(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useMediaModeration)
    }

    public static func setUseDemoModerationProxy(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useDemoModerationProxy)
    }

    public static func setMediaModerationFailClosed(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.mediaModerationFailClosed)
    }

    public static func setUseRemoteIdentityReverify(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useRemoteIdentityReverify)
    }

    public static func setUseDemoIdentityReverifyProxy(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.useDemoIdentityReverifyProxy)
    }
    #endif

    private enum Keys {
        static let useRemoteCatalog = "feature.useRemoteCatalog"
        static let legacyUseRemoteCatalog = "api.useRemoteCatalog"
        static let useLocalCatalogBootstrap = "feature.useLocalCatalogBootstrap"
        static let useRemoteProfile = "feature.useRemoteProfile"
        static let useRemoteMessages = "feature.useRemoteMessages"
        static let useRemoteCommunity = "feature.useRemoteCommunity"
        static let useRemoteBuddies = "feature.useRemoteBuddies"
        static let useRemoteBuddiesWrite = "feature.useRemoteBuddiesWrite"
        static let useSampleBuddiesCatalog = "feature.useSampleBuddiesCatalog"
        static let useRemoteAuth = "feature.useRemoteAuth"
        static let simulateBookingCompanionAcceptance = "feature.simulateBookingCompanionAcceptance"
        static let useSwiftDataSnapshots = "feature.useSwiftDataSnapshots"
        static let useSwiftDataActivities = "feature.useSwiftDataActivities"
        static let requireIdentityVerification = "feature.requireIdentityVerification"
        static let useMediaModeration = "feature.useMediaModeration"
        static let useDemoModerationProxy = "feature.useDemoModerationProxy"
        static let mediaModerationFailClosed = "feature.mediaModerationFailClosed"
        static let useRemoteIdentityReverify = "feature.useRemoteIdentityReverify"
        static let useDemoIdentityReverifyProxy = "feature.useDemoIdentityReverifyProxy"
    }

    /// 一次性迁移 DEBUG 演示里旧版 `api.useRemoteCatalog` 键。
    public static func migrateLegacyFlagsIfNeeded() {
        #if DEBUG
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Keys.useRemoteCatalog) == nil,
              defaults.bool(forKey: Keys.legacyUseRemoteCatalog) else { return }
        defaults.set(true, forKey: Keys.useRemoteCatalog)
        defaults.removeObject(forKey: Keys.legacyUseRemoteCatalog)
        #endif
    }
}
