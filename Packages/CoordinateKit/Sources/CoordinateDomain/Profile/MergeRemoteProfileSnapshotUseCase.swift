//
//  MergeRemoteProfileSnapshotUseCase.swift
//  CoordinateDomain
//
//  远程资料快照合并：公开字段采信远程；本机独有媒体 / 关系集合并保留；禁止整包覆盖。
//

import Foundation
import CoordinateModels

public struct MergeRemoteProfileSnapshotUseCase: Sendable {
    public init() {}

    public func execute(
        remote: ProfileSnapshot,
        previous: ProfileSnapshot
    ) -> ProfileSnapshot {
        ProfileSnapshot(
            user: mergeUser(remote: remote.user, previous: previous.user),
            hasCompletedOnboarding: previous.hasCompletedOnboarding || remote.hasCompletedOnboarding,
            blockedUserNames: Array(Set(previous.blockedUserNames).union(remote.blockedUserNames)).sorted(),
            followedUserNames: Array(Set(previous.followedUserNames).union(remote.followedUserNames)).sorted(),
            moderationTickets: mergeTickets(
                remote: remote.moderationTickets,
                previous: previous.moderationTickets
            )
        )
    }

    /// 远程覆盖可同步的公开字段；本机路径媒体在远程为空时保留。
    private func mergeUser(remote: AppUser, previous: AppUser) -> AppUser {
        var merged = remote
        // 稳定本机身份优先本地（游客 / 登录墙未切远端 id 时不丢）。
        if previous.id != remote.id, remote.name.caseInsensitiveCompare(previous.name) != .orderedSame {
            merged.id = previous.id
        } else if previous.id != remote.id {
            merged.id = previous.id
        }

        if remote.avatarLocalName == nil || remote.avatarLocalName?.isEmpty == true {
            merged.avatarLocalName = previous.avatarLocalName
        }
        if remote.galleryLocalNames.isEmpty {
            merged.galleryLocalNames = previous.galleryLocalNames
        } else {
            merged.galleryLocalNames = ProfileGalleryLimits.clamped(remote.galleryLocalNames)
        }
        if remote.verificationPhotos.isEmpty {
            merged.verificationPhotos = previous.verificationPhotos
        }
        if remote.voiceIntroDuration == nil {
            merged.voiceIntroDuration = previous.voiceIntroDuration
            merged.voiceIntroCaption = previous.voiceIntroCaption
        }
        if remote.prompts.isEmpty, !previous.prompts.isEmpty {
            merged.prompts = previous.prompts
        } else {
            merged.prompts = ProfilePromptLimits.clamped(remote.prompts)
        }
        if remote.intents.isEmpty, !previous.intents.isEmpty {
            merged.applyIntents(previous.intents)
        } else {
            merged.applyIntents(remote.intents)
            if merged.intents.isEmpty {
                merged.lookingFor = remote.lookingFor.isEmpty ? previous.lookingFor : remote.lookingFor
            }
        }
        if remote.occupation == nil {
            merged.occupation = previous.occupation
        }
        if remote.meetRadius == nil {
            merged.meetRadius = previous.meetRadius
        }
        if remote.mbti == nil {
            merged.mbti = previous.mbti
        }
        if remote.zodiac == nil {
            merged.zodiac = previous.zodiac
        }
        if remote.gender == nil { merged.gender = previous.gender }
        if remote.age == nil { merged.age = previous.age }
        if remote.heightCM == nil { merged.heightCM = previous.heightCM }
        if remote.weightKG == nil { merged.weightKG = previous.weightKG }
        // 实名证件与指纹优先保留本机（远程未接 KYC 前禁止被空字段冲掉）
        if !remote.isRealNameVerified, previous.isRealNameVerified {
            merged.isRealNameVerified = previous.isRealNameVerified
            merged.realNameVerifiedAt = previous.realNameVerifiedAt
            merged.birthDate = previous.birthDate
            merged.idNumberFingerprint = previous.idNumberFingerprint
            merged.idNumberMasked = previous.idNumberMasked
            merged.realNameDocumentKind = previous.realNameDocumentKind
            merged.idCardFrontLocalName = previous.idCardFrontLocalName
            merged.idCardBackLocalName = previous.idCardBackLocalName
            merged.passportDataPageLocalName = previous.passportDataPageLocalName
            merged.gender = previous.gender
            merged.age = previous.age
        }
        if remote.availability.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.availability = previous.availability
        }
        if remote.interests.isEmpty {
            merged.interests = previous.interests
        }
        if remote.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.bio = previous.bio
        }
        if remote.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.city = previous.city
        }
        merged.joinedCount = max(previous.joinedCount, remote.joinedCount)
        merged.hostedCount = max(previous.hostedCount, remote.hostedCount)
        merged.buddyCount = max(previous.buddyCount, remote.buddyCount)
        return merged
    }

    private func mergeTickets(
        remote: [ModerationTicket],
        previous: [ModerationTicket]
    ) -> [ModerationTicket] {
        var byID: [UUID: ModerationTicket] = [:]
        for ticket in previous {
            byID[ticket.id] = ticket
        }
        for ticket in remote {
            byID[ticket.id] = ticket
        }
        return Array(byID.values).sorted { $0.createdAt > $1.createdAt }
    }
}
