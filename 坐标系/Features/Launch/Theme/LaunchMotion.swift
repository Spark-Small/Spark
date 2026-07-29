//
//  LaunchMotion.swift
//  坐标系
//
//  Apple Invites–grade timing and curves for the launch ceremony.
//

import SwiftUI

enum LaunchMotion {
    // Splash
    static let logoReveal: Animation = .timingCurve(0.33, 0.00, 0.20, 1.00, duration: 1.20)
    static let logoIntro: Duration = .milliseconds(2000) // reveal 1.2s + hold 0.8s

    // Envelope arrival
    static let logoDissolve: Animation = .timingCurve(0.40, 0.00, 0.20, 1.00, duration: 0.90)
    static let envelopeArrive: Animation = .timingCurve(0.22, 0.00, 0.18, 1.00, duration: 1.10)
    static let floatAmplitude: CGFloat = 2.5
    static let floatCycle: TimeInterval = 7.0
    static let pressIn: Animation = .timingCurve(0.20, 0.00, 0.20, 1.00, duration: 0.06)
    static let pressOut: Animation = .timingCurve(0.20, 0.00, 0.15, 1.00, duration: 0.06)
    static let pressScale: CGFloat = 0.99
    static let flapOpen: Animation = .timingCurve(0.40, 0.00, 0.20, 1.00, duration: 0.85)
    static let letterRise: Animation = .timingCurve(0.33, 0.00, 0.20, 1.00, duration: 0.95)
    static let paperUnfold: Animation = .timingCurve(0.32, 0.00, 0.18, 1.00, duration: 1.25)

    // Login chrome
    static let chromeFade: Animation = .timingCurve(0.25, 0.00, 0.20, 1.00, duration: 0.55)
    static let chromeStagger: Duration = .milliseconds(100)

    // Handoffs
    static let stateCrossfade: Animation = .timingCurve(0.33, 0.00, 0.20, 1.00, duration: 0.70)
    static let openSequence: Duration = .milliseconds(1000)
    static let expandSequence: Duration = .milliseconds(1300)
}
