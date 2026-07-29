//
//  LocalAuthSession.swift
//  坐标系
//

import Foundation
import Observation

@MainActor
@Observable
final class LocalAuthSession {
    private enum Keys {
        static let signedIn = "auth.isSignedIn"
        static let phone = "auth.phone"
    }

    static let demoCode = "123456"

    var isSignedIn: Bool {
        didSet { UserDefaults.standard.set(isSignedIn, forKey: Keys.signedIn) }
    }

    var phoneNumber: String {
        didSet { UserDefaults.standard.set(phoneNumber, forKey: Keys.phone) }
    }

    init() {
        isSignedIn = UserDefaults.standard.bool(forKey: Keys.signedIn)
        phoneNumber = UserDefaults.standard.string(forKey: Keys.phone) ?? ""
    }

    @discardableResult
    func signIn(phone: String, code: String) -> Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8, code == Self.demoCode else { return false }
        phoneNumber = trimmed
        isSignedIn = true
        return true
    }

    func signInDemoApple() {
        phoneNumber = phoneNumber.isEmpty ? "demo.apple" : phoneNumber
        isSignedIn = true
    }

    func signInDemoWeChat() {
        phoneNumber = phoneNumber.isEmpty ? "demo.wechat" : phoneNumber
        isSignedIn = true
    }

    func signOut() {
        isSignedIn = false
    }

    func resetStoredSession() {
        phoneNumber = ""
        isSignedIn = false
        UserDefaults.standard.removeObject(forKey: Keys.phone)
        UserDefaults.standard.removeObject(forKey: Keys.signedIn)
    }
}
