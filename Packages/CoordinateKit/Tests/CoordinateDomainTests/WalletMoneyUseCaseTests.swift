import CoordinateDomain
import XCTest

final class WalletMoneyUseCaseTests: XCTestCase {
    private let charge = ChargeWalletUseCase()
    private let credit = ApplyWalletCreditUseCase()
    private let topUp = CreateWalletTopUpIntentUseCase()

    func testChargeWalletSuccess() {
        let result = charge.evaluate(
            balanceCents: 10_000,
            amountCents: 2_800,
            methodAffectsBalance: true,
            isExternalMethod: false,
            allowsSimulatedExternal: false
        )
        XCTAssertEqual(result, .success(newBalanceCents: 7_200, balanceDeltaCents: -2_800))
    }

    func testChargeInsufficientBalance() {
        let result = charge.evaluate(
            balanceCents: 100,
            amountCents: 200,
            methodAffectsBalance: true,
            isExternalMethod: false,
            allowsSimulatedExternal: false
        )
        XCTAssertEqual(result, .failure(.insufficientBalance))
    }

    func testChargeBlocksExternalWhenNotAllowed() {
        let result = charge.evaluate(
            balanceCents: 10_000,
            amountCents: 100,
            methodAffectsBalance: false,
            isExternalMethod: true,
            allowsSimulatedExternal: false
        )
        XCTAssertEqual(result, .failure(.externalUnavailable))
    }

    func testExternalSimulatedDoesNotChangeBalance() {
        let result = charge.evaluate(
            balanceCents: 10_000,
            amountCents: 500,
            methodAffectsBalance: false,
            isExternalMethod: true,
            allowsSimulatedExternal: true
        )
        XCTAssertEqual(result, .success(newBalanceCents: 10_000, balanceDeltaCents: 0))
    }

    func testCreditTopUpAlwaysApplies() {
        XCTAssertEqual(
            credit.balanceDeltaCents(
                amountCents: 5_000,
                kind: .topUp,
                methodAffectsBalance: false
            ),
            5_000
        )
    }

    func testCreditRefundOnlyWhenWalletMethod() {
        XCTAssertEqual(
            credit.balanceDeltaCents(
                amountCents: 5_000,
                kind: .activityRefund,
                methodAffectsBalance: true
            ),
            5_000
        )
        XCTAssertEqual(
            credit.balanceDeltaCents(
                amountCents: 5_000,
                kind: .activityRefund,
                methodAffectsBalance: false
            ),
            0
        )
    }

    func testTopUpIntentYouthBlocked() {
        let result = topUp.evaluate(
            amountCents: 10_000,
            channel: "wechat",
            allowsRemoteTopUp: true,
            allowsDemoTopUp: false,
            youthBlocked: true
        )
        XCTAssertEqual(result, .failure(.youthBlocked))
    }

    func testTopUpIntentRemoteChannel() {
        let result = topUp.evaluate(
            amountCents: 10_000,
            channel: "wechat",
            allowsRemoteTopUp: true,
            allowsDemoTopUp: false,
            youthBlocked: false
        )
        XCTAssertEqual(result, .ready(amountCents: 10_000, channel: "wechat"))
    }

    func testTopUpIntentRejectsApplePayOnRemote() {
        let result = topUp.evaluate(
            amountCents: 10_000,
            channel: "applePay",
            allowsRemoteTopUp: true,
            allowsDemoTopUp: false,
            youthBlocked: false
        )
        XCTAssertEqual(result, .failure(.channelUnavailable))
    }

    func testWelcomeGiftReleaseIsZero() {
        XCTAssertEqual(WalletMoneyPolicy.welcomeGiftCents(isDebugBuild: false), 0)
        XCTAssertEqual(WalletMoneyPolicy.welcomeGiftCents(isDebugBuild: true), 50_000)
    }

    func testRemoteLedgerReplaceClearsWhenRemoteEmpty() {
        let merge = MergeRemoteWalletLedgerUseCase()
        let local = [UUID(), UUID()]
        let ids = merge.idsAfterRefresh(
            previousLocalIDs: local,
            remoteIDs: [],
            remoteFetchSucceeded: true
        )
        XCTAssertTrue(ids.isEmpty)
    }

    func testRemoteLedgerKeepsLocalWhenFetchFails() {
        let merge = MergeRemoteWalletLedgerUseCase()
        let local = [UUID(), UUID()]
        let ids = merge.idsAfterRefresh(
            previousLocalIDs: local,
            remoteIDs: nil,
            remoteFetchSucceeded: false
        )
        XCTAssertEqual(ids, local)
    }
}
