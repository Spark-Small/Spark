// Module: SparkPayments — Preview / unit-test CN payment coordinators.

import Foundation

@MainActor
public struct PreviewWeChatPayCoordinator: WeChatPayCoordinating {
    public init() {}

    public func pay(order: CNPaymentOrder) async throws -> CNPaymentReceipt {
        CNPaymentReceipt(
            orderID: order.orderID,
            provider: .wechat,
            receipt: "staging-wechat-pay-receipt"
        )
    }

    public func handleOpenURL(_ url: URL) -> Bool { false }
}

@MainActor
public struct PreviewAlipayPayCoordinator: AlipayPayCoordinating {
    public init() {}

    public func pay(order: CNPaymentOrder) async throws -> CNPaymentReceipt {
        CNPaymentReceipt(
            orderID: order.orderID,
            provider: .alipay,
            receipt: "staging-alipay-pay-receipt"
        )
    }

    public func handleOpenURL(_ url: URL) -> Bool { false }
}

public extension CNPaymentCoordinators {
    static var preview: CNPaymentCoordinators {
        CNPaymentCoordinators(
            weChat: PreviewWeChatPayCoordinator(),
            alipay: PreviewAlipayPayCoordinator()
        )
    }
}
