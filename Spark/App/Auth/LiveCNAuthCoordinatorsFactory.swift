// Module: Spark App — Factory for Live CN auth coordinators.

import Foundation
import SparkAuth
import SparkNetworking

enum LiveCNAuthCoordinatorsFactory {
    @MainActor
    static func make(configuration: APIConfiguration) -> CNAuthCoordinators {
        if configuration.usesMockBackend {
            return .preview
        }
        if CNVendorConfiguration.allowsStagingBridge && !CNVendorConfiguration.isAnyCNProviderConfigured {
            return CNAuthCoordinators.stagingBridge(phoneProvider: CNVendorConfiguration.phoneOneTapPrimary)
        }
        return CNAuthCoordinators(
            weChat: WeChatSignInCoordinator(),
            phoneOneTap: PhoneOneTapCoordinatorFacade(),
            alipay: AlipaySignInCoordinator()
        )
    }
}
