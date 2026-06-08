// Module: SparkProfile — PUT avatar bytes to presigned URL.

import Foundation
import os
import SparkCore

public enum AvatarUploadTransport: Sendable {
    private static let logger = Logger(subsystem: SparkLog.subsystem, category: "AvatarUpload")

    public static func put(data: Data, to uploadURL: URL, contentType: String) async throws {
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ProfileError.underlying(.unknown(message: "Invalid upload response"))
        }
        guard (200 ... 299).contains(http.statusCode) else {
            logger.error("avatar upload failed status=\(http.statusCode, privacy: .public)")
            throw ProfileError.underlying(.unknown(message: "Avatar upload failed"))
        }
    }
}
