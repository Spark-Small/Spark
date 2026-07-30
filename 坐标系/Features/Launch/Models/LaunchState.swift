//
//  LaunchState.swift
//  坐标系
//

enum LaunchState: Equatable, Hashable, Sendable {
    /// 放大信封静候点击。
    case invitationReady
    /// 四叶草解锁 + 信封盖翻开 + 信纸升起。
    case opening
    /// 信纸已露出，短暂停留后自动进入登录。
    case invitationOpened
    /// 信纸通过系统 Zoom 导航展开为登录页。
    case login
}
