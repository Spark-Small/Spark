// Module: SparkNetworkingTests

import Foundation
import SparkNetworking
import Testing

struct APIConfigurationTests {
    @Test func mockHostEnablesMockBackend() {
        let config = APIConfiguration(baseURL: URL(string: "https://mock.spark.local")!)
        #expect(config.usesMockBackend)
    }
}
