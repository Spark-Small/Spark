// Module: Spark App — Staging bridge CN payment coordinators.

import Foundation
import SparkPayments

enum StagingBridgeCNPaymentCoordinators {
    static func make() -> CNPaymentCoordinators {
        CNPaymentCoordinators(
            weChat: StagingBridgeWeChatPayCoordinator(),
            alipay: StagingBridgeAlipayPayCoordinator()
        )
    }
}

@MainActor
struct StagingBridgeWeChatPayCoordinator: WeChatPayCoordinating {
    func pay(order: CNPaymentOrder) async throws -> CNPaymentReceipt {
        CNPaymentReceipt(
            orderID: order.orderID,
            provider: .wechat,
            receipt: "staging-wechat-pay-receipt"
        )
    }

    func handleOpenURL(_ url: URL) -> Bool { false }
}

@MainActor
struct StagingBridgeAlipayPayCoordinator: AlipayPayCoordinating {
    func pay(order: CNPaymentOrder) async throws -> CNPaymentReceipt {
        CNPaymentReceipt(
            orderID: order.orderID,
            provider: .alipay,
            receipt: "staging-alipay-pay-receipt"
        )
    }

    func handleOpenURL(_ url: URL) -> Bool { false }
}
