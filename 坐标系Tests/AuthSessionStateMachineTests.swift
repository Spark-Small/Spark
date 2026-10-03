//
//  AuthSessionStateMachineTests.swift
//  坐标系Tests
//
//  登录会话状态机 / UseCase / WorkGate 单元测试。
//

import CoordinateFeatureFlags
import XCTest
@testable import 坐标系

@MainActor
final class AuthSessionStateMachineTests: XCTestCase {
    override func setUp() {
        super.setUp()
        FeatureFlags.setUseRemoteAuth(false)
        AuthTokenStore.clearAllIncludingAppleUser()
    }

    override func tearDown() {
        AuthTokenStore.clearAllIncludingAppleUser()
        super.tearDown()
    }

    // MARK: - Credential format

    func testCredentialFormatAcceptsMainlandMobile() {
        XCTAssertTrue(AuthCredentialFormat.isValidPhone("13800138000"))
        XCTAssertEqual(AuthCredentialFormat.sanitizedPhone("138-0013-8000"), "13800138000")
    }

    func testCredentialFormatRejectsShortOrNonMobile() {
        XCTAssertFalse(AuthCredentialFormat.isValidPhone("12345"))
        XCTAssertFalse(AuthCredentialFormat.isValidPhone("23800138000"))
        XCTAssertFalse(AuthCredentialFormat.isValidCode("12"))
        XCTAssertTrue(AuthCredentialFormat.isValidCode("123456"))
    }

    // MARK: - Use cases (pure)

    func testReconcileUseCaseInvalidatesWhenRemoteWithoutTokens() {
        let useCase = ReconcileAuthSessionUseCase()
        XCTAssertTrue(
            useCase.shouldInvalidate(
                isSignedIn: true,
                hasUsableRemoteSession: false,
                useRemoteAuth: true
            )
        )
        XCTAssertFalse(
            useCase.shouldInvalidate(
                isSignedIn: true,
                hasUsableRemoteSession: true,
                useRemoteAuth: true
            )
        )
        XCTAssertFalse(
            useCase.shouldInvalidate(
                isSignedIn: true,
                hasUsableRemoteSession: false,
                useRemoteAuth: false
            )
        )
    }

    func testDemoSMSUseCaseSignsInWithValidCode() {
        #if DEBUG
        let result = SignInWithDemoSMSUseCase(demoCode: LocalAuthSession.demoCode)
            .execute(phone: "13800138000", code: "123456", source: .login)
        guard case .success(let success) = result else {
            return XCTFail("expected success")
        }
        XCTAssertTrue(success.snapshot.isSignedIn)
        XCTAssertEqual(success.snapshot.provider, .phone)
        XCTAssertEqual(success.snapshot.phoneNumber, "13800138000")
        #else
        throw XCTSkip("DEBUG demo SMS only")
        #endif
    }

    func testDemoSMSUseCaseRejectsBadCode() {
        #if DEBUG
        let result = SignInWithDemoSMSUseCase(demoCode: LocalAuthSession.demoCode)
            .execute(phone: "13800138000", code: "000000", source: .login)
        XCTAssertNotNil(result.errorMessage)
        #else
        throw XCTSkip("DEBUG demo SMS only")
        #endif
    }

    // MARK: - Session store + LocalAuthSession facade

    func testSignedOutByDefault() {
        let store = InMemoryAuthSessionStore()
        let session = LocalAuthSession(store: store)
        XCTAssertFalse(session.isSignedIn)
        XCTAssertEqual(session.phoneNumber, "")
        XCTAssertEqual(session.accountStatusLabel, "未登录")
    }

    func testDebugPhoneSignInPersistsSnapshot() {
        #if DEBUG
        let store = InMemoryAuthSessionStore()
        let session = LocalAuthSession(store: store)
        XCTAssertTrue(session.signIn(phone: "13800138000", code: LocalAuthSession.demoCode))
        XCTAssertTrue(session.isSignedIn)
        XCTAssertEqual(session.provider, .phone)
        XCTAssertEqual(session.phoneNumber, "13800138000")
        XCTAssertEqual(session.maskedPhoneLabel, "138****8000")

        let reloaded = store.load()
        XCTAssertTrue(reloaded.isSignedIn)
        XCTAssertEqual(reloaded.provider, .phone)
        XCTAssertEqual(reloaded.phoneNumber, "13800138000")
        #else
        throw XCTSkip("DEBUG local SMS only")
        #endif
    }

    func testSignOutClearsPersistedSnapshot() {
        #if DEBUG
        let store = InMemoryAuthSessionStore()
        let session = LocalAuthSession(store: store)
        XCTAssertTrue(session.signIn(phone: "13800138000", code: LocalAuthSession.demoCode))
        session.signOut()
        XCTAssertFalse(session.isSignedIn)
        XCTAssertEqual(session.phoneNumber, "")
        XCTAssertEqual(store.load(), .signedOut)
        #else
        throw XCTSkip("DEBUG local SMS only")
        #endif
    }

    func testLegacyGuestSnapshotNormalizesToSignedOut() {
        let service = "com.zuobiaoxi.test.auth.\(UUID().uuidString)"
        let keychain = KeychainAuthSessionStore(service: service)
        keychain.save(AuthSessionSnapshot(isSignedIn: true, provider: .guest, phoneNumber: "x"))
        let loaded = keychain.load()
        XCTAssertEqual(loaded, .signedOut)
        keychain.clear()
    }

    func testReconcileSignsOutWhenRemoteAuthMissingTokens() {
        #if DEBUG
        FeatureFlags.setUseRemoteAuth(true)
        let store = InMemoryAuthSessionStore()
        let session = LocalAuthSession(store: store)
        XCTAssertTrue(session.signIn(phone: "13800138000", code: LocalAuthSession.demoCode))
        AuthTokenStore.clear()
        session.reconcilePersistedSession()
        XCTAssertFalse(session.isSignedIn)
        FeatureFlags.setUseRemoteAuth(false)
        #else
        throw XCTSkip("DEBUG local SMS only")
        #endif
    }

    func testInvalidateRemoteSessionSignsOut() {
        #if DEBUG
        let store = InMemoryAuthSessionStore()
        let session = LocalAuthSession(store: store)
        XCTAssertTrue(session.signIn(phone: "13800138000", code: LocalAuthSession.demoCode))
        session.invalidateRemoteSession()
        XCTAssertFalse(session.isSignedIn)
        #else
        throw XCTSkip("DEBUG local SMS only")
        #endif
    }

    // MARK: - Work gate

    func testWorkGateBeginCancelsPriorBusyFlags() {
        let gate = LoginAuthWorkGate()
        _ = gate.begin(.sendingCode)
        XCTAssertTrue(gate.isSendingCode)
        XCTAssertTrue(gate.isBusy)

        let gen = gate.begin(.social)
        XCTAssertFalse(gate.isSendingCode)
        XCTAssertTrue(gate.isSocialBusy)
        XCTAssertTrue(gate.isCurrent(gen))

        gate.cancel()
        XCTAssertFalse(gate.isBusy)
        XCTAssertFalse(gate.isCurrent(gen))
    }
}
