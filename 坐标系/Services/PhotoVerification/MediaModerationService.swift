//
//  MediaModerationService.swift
//  坐标系
//
//  上传图内容安全：本机启发式 + 演示代理 / 远程 Private Detector。
//

import CoordinateFeatureFlags
import CoordinateNetworking
import Foundation
import UIKit

enum MediaModerationService {
    enum Context: String, Sendable {
        case avatar
        case verificationPhoto
        case chat
        case community
        case activityCover
    }

    enum Decision: Equatable, Sendable {
        case allow
        case block(reason: String)
    }

    /// 头像 / 认证照 / 聊天 / 社区 / 活动封面发送前调用。
    static func moderateImageData(
        _ data: Data,
        context: Context = .chat,
        youthMode: Bool = YouthModePreference.isEnabled,
        actorKey: String? = nil
    ) async -> Decision {
        guard FeatureFlags.useMediaModeration else { return .allow }
        guard UIImage(data: data) != nil else {
            return .block(reason: "无法读取图片，请换一张再试。")
        }

        // Data 可跨线程；真机原图 Vision 必须离开主线程
        let local = await Task.detached(priority: .userInitiated) {
            LocalPrivateDetectorProxy.score(imageData: data)
        }.value

        return await decide(
            local: local,
            imageData: data,
            context: context,
            youthMode: youthMode,
            actorKey: actorKey
        )
    }

    static func moderateImage(
        _ image: UIImage,
        context: Context = .chat,
        youthMode: Bool = YouthModePreference.isEnabled,
        actorKey: String? = nil
    ) async -> Decision {
        guard FeatureFlags.useMediaModeration else { return .allow }
        let data = await Task.detached(priority: .utility) {
            image.jpegData(compressionQuality: 0.9)
        }.value
        guard let data else {
            return .block(reason: "无法读取图片，请换一张再试。")
        }
        return await moderateImageData(
            data,
            context: context,
            youthMode: youthMode,
            actorKey: actorKey
        )
    }

    private static func decide(
        local: LocalPrivateDetectorProxy.Score,
        imageData: Data,
        context: Context,
        youthMode: Bool,
        actorKey: String?
    ) async -> Decision {
        let threshold = blockThreshold(context: context, youthMode: youthMode)

        if context == .avatar || context == .verificationPhoto {
            if local.faceCoverage < 0.06 {
                return await finish(
                    .block(reason: "未检测到清晰正脸，请上传本人正面照片。"),
                    actorKey: actorKey,
                    context: context
                )
            }
        }

        let remoteScore: Double
        if FeatureFlags.useDemoModerationProxy {
            remoteScore = local.nsfwScore
        } else {
            switch await fetchRemoteScore(imageData: imageData, context: context, youthMode: youthMode) {
            case .success(let score):
                remoteScore = score
            case .failure:
                if FeatureFlags.mediaModerationFailClosed {
                    return await finish(
                        .block(reason: "内容审核服务暂不可用，请稍后再试。"),
                        actorKey: actorKey,
                        context: context
                    )
                }
                remoteScore = local.nsfwScore
            }
        }

        let score = max(local.nsfwScore, remoteScore)
        if score >= threshold {
            return await finish(
                .block(reason: blockReason(context: context, youthMode: youthMode)),
                actorKey: actorKey,
                context: context
            )
        }
        return .allow
    }

    private static func blockThreshold(context: Context, youthMode: Bool) -> Double {
        let base: Double
        switch context {
        case .avatar, .verificationPhoto: base = 0.62
        case .activityCover: base = 0.68
        case .community: base = 0.70
        case .chat: base = 0.72
        }
        return youthMode ? max(0.45, base - 0.12) : base
    }

    private static func blockReason(context: Context, youthMode: Bool) -> String {
        if youthMode {
            return "青少年模式下该图片未通过内容安全检测，请更换后重试。"
        }
        switch context {
        case .avatar, .verificationPhoto:
            return "认证/头像照片未通过内容安全检测，请更换本人正脸照。"
        case .chat:
            return "该图片可能包含不雅内容，无法发送。"
        case .community:
            return "该图片可能包含不雅内容，无法发布。"
        case .activityCover:
            return "封面未通过内容安全检测，请更换图片。"
        }
    }

    private static func fetchRemoteScore(
        imageData: Data,
        context: Context,
        youthMode: Bool
    ) async -> Result<Double, Error> {
        do {
            let body = MediaModerationRequest(
                imageBase64: imageData.base64EncodedString(),
                context: context.rawValue,
                youthMode: youthMode
            )
            let response = try await APIClient.shared.send(.moderateMedia(body))
            return .success(response.nsfwScore)
        } catch {
            return .failure(error)
        }
    }

    private static func finish(
        _ decision: Decision,
        actorKey: String?,
        context: Context
    ) async -> Decision {
        if case .block = decision, let actorKey, !actorKey.isEmpty {
            await MainActor.run {
                AppComposition.trustService.record(
                    .mediaBlocked,
                    domain: .moderation,
                    actorKey: actorKey,
                    note: context.rawValue
                )
            }
        }
        return decision
    }
}
