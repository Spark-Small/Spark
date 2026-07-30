//
//  LaunchMotion.swift
//  坐标系
//

import SwiftUI

enum LaunchMotion {
    static let floatAmplitude: CGFloat = 2.5
    static let floatCycle: TimeInterval = 7.0

    static let pressIn: Animation = .timingCurve(0.20, 0.00, 0.20, 1.00, duration: 0.06)
    static let pressOut: Animation = .timingCurve(0.20, 0.00, 0.15, 1.00, duration: 0.06)
    static let pressScale: CGFloat = 0.99

    // 开启时序：四叶草解锁 → 上盖翻开并淡出 → 信纸升起 → 停留 1.5s → 自动进入登录。
    // 前三段互不重叠，避免翻开中的上盖半透明地压在信纸上。
    static let cloverUnlock: Animation = .timingCurve(0.22, 0.00, 0.18, 1.00, duration: 0.28)
    static let cloverUnlockDuration: Duration = .milliseconds(280)

    static let flapOpen: Animation = .timingCurve(0.40, 0.00, 0.20, 1.00, duration: 0.40)
    static let sealFade: Animation = .easeOut(duration: 0.18)
    static let flapVanish: Animation = .easeOut(duration: 0.16)
    static let flapVanishDelay: Duration = .milliseconds(200)

    static let letterRiseDelay: Duration = .milliseconds(140)
    static let letterRise: Animation = .timingCurve(0.33, 0.00, 0.20, 1.00, duration: 0.46)

    /// 信纸完全升起后停留，再自动进入登录页。
    static let letterDwell: Duration = .milliseconds(1500)

    static let chromeFade: Animation = .timingCurve(0.25, 0.00, 0.20, 1.00, duration: 0.36)
    static let chromeStagger: Duration = .milliseconds(60)

    /// 解锁到信纸升起结束：280 + 340 + 460；不含随后的 letterDwell。
    static let openSequence: Duration = .milliseconds(1080)
}
