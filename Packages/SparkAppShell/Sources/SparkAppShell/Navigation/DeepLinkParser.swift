// Module: SparkAppShell — URL parsing for custom scheme and universal links.

import Foundation
import SparkPayments

public enum DeepLinkParser: Sendable {
    private static let customSchemes: Set<String> = ["spark"]
    private static let universalHosts: Set<String> = ["spark.app", "www.spark.app"]

    public static func parse(url: URL) -> DeepLinkRoute? {
        guard let scheme = url.scheme?.lowercased() else { return nil }

        if customSchemes.contains(scheme) {
            return parseCustomScheme(url)
        }

        if scheme == "https" || scheme == "http", let host = url.host?.lowercased(), universalHosts.contains(host) {
            return parseUniversalLink(url)
        }

        return nil
    }

    private static func parseCustomScheme(_ url: URL) -> DeepLinkRoute? {
        if let host = url.host, !host.isEmpty {
            if host == "paywall" {
                return parsePaywallRoute(path: url.path, query: url)
            }
            if host == "messages" {
                return parseMessagesRoute(path: url.path, query: url)
            }
            if host == "community" {
                return parseCommunityRoute(path: url.path, query: url)
            }
            if host == "activity" {
                return parseActivityRoute(path: url.path, query: url)
            }
            if host == "likes" {
                return parseLikesRoute(path: url.path, query: url)
            }
            if let tab = SparkTab(rawValue: host) {
                return .tab(tab, query: url.queryValue(for: "q"))
            }
        }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if path == "messages" || path.hasPrefix("messages/") {
            return parseMessagesRoute(path: "/" + path, query: url)
        }
        if path == "paywall" || path.hasPrefix("paywall/") {
            return parsePaywallRoute(path: path, query: url)
        }
        if path == "likes/inbound" || path.hasPrefix("likes/inbound") {
            return .likesInbound
        }
        guard !path.isEmpty, let tab = SparkTab(rawValue: path) else { return nil }
        return .tab(tab, query: url.queryValue(for: "q"))
    }

    private static func parseUniversalLink(_ url: URL) -> DeepLinkRoute? {
        let components = url.path.split(separator: "/").map(String.init)
        guard let first = components.first else { return nil }
        if first == "a", components.count >= 2 {
            return .activityDetail(activityID: components[1])
        }
        if first == "activity", components.count >= 2 {
            return .activityDetail(activityID: components[1])
        }
        if first == "paywall" {
            let placementName = components.count >= 2 ? components[1] : url.queryValue(for: "placement")
            let placement = placementName.flatMap(PaywallPlacement.init(rawValue:)) ?? .activity
            return .paywall(placement)
        }
        guard first == "tab", components.count >= 2 else { return nil }
        let tabName = components[1]
        if tabName == "likes", components.count >= 3, components[2] == "inbound" {
            return .likesInbound
        }
        guard let tab = SparkTab(rawValue: tabName) else { return nil }
        return .tab(tab, query: url.queryValue(for: "q"))
    }

    private static func parseActivityRoute(path: String, query: URL) -> DeepLinkRoute? {
        var segments = path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        if segments.first == "activity" {
            segments.removeFirst()
        }
        if let last = segments.last, !last.isEmpty, last != "invite" {
            return .activityDetail(activityID: last)
        }
        if let activityID = query.queryValue(for: "activity_id"), !activityID.isEmpty {
            return .activityDetail(activityID: activityID)
        }
        return .tab(.activity, query: query.queryValue(for: "q"))
    }

    private static func parseCommunityRoute(path: String, query: URL) -> DeepLinkRoute? {
        var segments = path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        if segments.first == "community" {
            segments.removeFirst()
        }
        if segments.count >= 2, segments[0] == "post" {
            return .communityPost(postID: segments[1])
        }
        if let postID = query.queryValue(for: "post_id"), !postID.isEmpty {
            return .communityPost(postID: postID)
        }
        if let activityID = query.queryValue(for: "activity_id"), !activityID.isEmpty {
            return .communityRecap(activityID: activityID)
        }
        return .tab(.community, query: query.queryValue(for: "q"))
    }

    private static func parseMessagesRoute(path: String, query: URL) -> DeepLinkRoute? {
        var segments = path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        if segments.first == "messages" {
            segments.removeFirst()
        }
        if segments.count >= 2, segments[0] == "thread" {
            return .conversation(threadID: segments[1])
        }
        if let threadID = query.queryValue(for: "thread_id"), !threadID.isEmpty {
            return .conversation(threadID: threadID)
        }
        return .tab(.messages, query: query.queryValue(for: "q"))
    }

    private static func parseLikesRoute(path: String, query: URL) -> DeepLinkRoute? {
        var segments = path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        if segments.first == "likes" {
            segments.removeFirst()
        }
        if segments.first == "inbound" {
            return .likesInbound
        }
        return .tab(.likes, query: query.queryValue(for: "q"))
    }

    private static func parsePaywallRoute(path: String, query: URL) -> DeepLinkRoute {
        let segments = path.split(separator: "/").map(String.init)
        let placementName: String? = if segments.count >= 2 {
            segments[1]
        } else {
            query.queryValue(for: "placement")
        }
        let placement = placementName.flatMap(PaywallPlacement.init(rawValue:)) ?? .activity
        return .paywall(placement)
    }
}

private extension URL {
    func queryValue(for name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value
    }
}
