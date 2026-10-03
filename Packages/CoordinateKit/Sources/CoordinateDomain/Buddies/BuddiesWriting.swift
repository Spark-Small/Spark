//
//  BuddiesWriting.swift
//  CoordinateDomain
//
//  搭子写意图枚举（与网络解耦）；接通远程时 Features 经 Sync 服务提交，Domain 仍管本地规则。
//

import Foundation
import CoordinateModels

public enum BuddiesWriteCommand: Equatable, Sendable {
    case submitInvite(inviteID: UUID)
    case createClub(circleID: UUID)
    case joinClub(circleID: UUID)
    case leaveClub(circleID: UUID)
    case submitBooking(bookingID: UUID)
}

/// 远程写未开时的本地真相说明（供文档 / 调试；无网络）。
public enum BuddiesWritePathPolicy: Sendable {
    /// 预约 submit/detail：跟 `useRemoteBuddies`（读路径 Flag）
    case bookingTiedToRemoteBuddiesRead
    /// 邀约 / 俱乐部：跟 `useRemoteBuddiesWrite`（默认关）
    case inviteAndClubRequireWriteFlag
}
