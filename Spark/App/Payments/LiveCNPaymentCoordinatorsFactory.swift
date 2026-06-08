// Module: Spark App — Factory for Live CN payment coordinators.

import Foundation
import SparkNetworking
import SparkPayments

enum LiveCNPaymentCoordinatorsFactory {
    @MainActor
    static func make(configuration: APIConfiguration) -> CNPaymentCoordinators {
        if configuration.usesMockBackend {
            return .preview
        }
        if CNVendorConfiguration.allowsStagingBridge && !CNVendorConfiguration.isAnyCNProviderConfigured {
            return StagingBridgeCNPaymentCoordinators.make()
        }
        return CNPaymentCoordinators(
            weChat: WeChatPayCoordinator(),
            alipay: AlipayPayCoordinator()
        )
    }
}
