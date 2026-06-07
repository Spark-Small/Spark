// Module: SparkNotifications — Live APNs token upload.

import Foundation
import SparkNetworking

enum DeviceAPIPath {
    static let register = "/v1/devices"
}

private struct RegisterDeviceRequestDTO: Encodable, Sendable {
    let token: String
    let platform: String
}

public struct LiveDeviceTokenUploader: DeviceTokenUploading, Sendable {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func upload(apnsToken: Data) async {
        let token = apnsToken.map { String(format: "%02x", $0) }.joined()
        guard !token.isEmpty else { return }
        do {
            let body = try JSONEncoder().encode(RegisterDeviceRequestDTO(token: token, platform: "ios"))
            try await apiClient.post(DeviceAPIPath.register, body: body)
        } catch {
            // REASONING: Token upload must not block launch; backend may be absent on Mock host.
        }
    }
}
