// Module: SparkCommunity — Share / Universal Link helpers (Nexus W6).

import Foundation

public enum CommunityPostURL {
    private static let webBaseURL: URL = {
        guard let url = URL(string: "https://spark.app") else {
            preconditionFailure("Invalid CommunityPostURL web base")
        }
        return url
    }()

    public static func deepLink(postID: String) -> URL {
        guard let url = URL(string: "spark://community/post/\(postID)") else {
            preconditionFailure("Invalid community post deep link")
        }
        return url
    }

    public static func universalLink(postID: String) -> URL {
        webBaseURL.appending(path: "community/post/\(postID)")
    }

    public static func shareLink(postID: String) -> URL {
        universalLink(postID: postID)
    }

    public static func recapDeepLink(activityID: String) -> URL {
        var components = URLComponents()
        components.scheme = "spark"
        components.host = "community"
        components.queryItems = [URLQueryItem(name: "activity_id", value: activityID)]
        guard let url = components.url else {
            preconditionFailure("Invalid community recap deep link")
        }
        return url
    }

    public static func recapUniversalLink(activityID: String) -> URL {
        var components = URLComponents(
            url: webBaseURL.appending(path: "community"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "activity_id", value: activityID)]
        guard let url = components?.url else {
            preconditionFailure("Invalid community recap universal link")
        }
        return url
    }
}
