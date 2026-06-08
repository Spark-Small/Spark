// Module: SparkPayments — CN payment coordinator protocols (implemented in App target).

import Foundation

@MainActor
public protocol WeChatPayCoordinating {
    func pay(order: CNPaymentOrder) async throws -> CNPaymentReceipt
    func handleOpenURL(_ url: URL) -> Bool
}

@MainActor
public protocol AlipayPayCoordinating {
    func pay(order: CNPaymentOrder) async throws -> CNPaymentReceipt
    func handleOpenURL(_ url: URL) -> Bool
}

@MainActor
public struct CNPaymentCoordinators {
    public let weChat: any WeChatPayCoordinating
    public let alipay: any AlipayPayCoordinating

    public init(weChat: any WeChatPayCoordinating, alipay: any AlipayPayCoordinating) {
        self.weChat = weChat
        self.alipay = alipay
    }
}
