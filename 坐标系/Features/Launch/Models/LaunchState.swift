//
//  LaunchState.swift
//  坐标系
//

import Foundation

enum LaunchState: Int, Equatable, Hashable, CaseIterable, Sendable {
    /// 放大信封静候点击。
    case invitationReady
    /// 四叶草解锁 + 信封盖翻开 + 信纸升起。
    case opening
    /// 信纸已经露出，等待用户点击进入。
    case invitationOpened
    /// 信纸通过系统 Zoom 导航展开为登录页。
    case login
}
