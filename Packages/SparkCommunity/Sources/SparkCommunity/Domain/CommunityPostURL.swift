// Module: SparkCommunity — Share / Universal Link helpers (Nexus W6).

import Foundation

public enum CommunityPostURL {
    private static let webBaseURL = URL(string: "https://spark.app")!

    public static func deepLink(postID: String) -> URL {
        URL(string: "spark://community/post/\(postID)")!
    }

    public static func universalLink(postID: String) -> URL {
        webBaseURL.appending(path: "community/post/\(postID)")
    }

    public static func shareLink(postID: String) -> URL {
        universalLink(postID: postID)
    }

    public static func recapDeepLink(activityID: String) -> URL {
        var components = URLComponents(string: "spark://community")!
        components.queryItems = [URLQueryItem(name: "activity_id", value: activityID)]
        return components.url!
    }

    public static func recapUniversalLink(activityID: String) -> URL {
        var components = URLComponents(url: webBaseURL.appending(path: "community"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "activity_id", value: activityID)]
        return components.url!
    }
}
