//
//  AnalyticsClient.swift
//  坐标系
//
//  产品埋点门面：默认 OSLog；接入友盟 / Firebase 时替换或组合 `Analytics.sink`。
//

import Foundation
import OSLog

protocol AnalyticsSink: Sendable {
    func track(name: String, parameters: [String: String])
}

struct NoOpAnalyticsSink: AnalyticsSink {
    func track(name: String, parameters: [String: String]) {}
}

struct OSLogAnalyticsSink: AnalyticsSink {
    private let logger = Logger(subsystem: "com.zuobiaoxi.analytics", category: "track")

    func track(name: String, parameters: [String: String]) {
        if parameters.isEmpty {
            logger.info("event=\(name, privacy: .public)")
        } else {
            let payload = parameters
                .map { "\($0.key)=\($0.value)" }
                .sorted()
                .joined(separator: " ")
            logger.info("event=\(name, privacy: .public) \(payload, privacy: .public)")
        }
    }
}

/// 多 sink 组合，便于「OSLog + 第三方 SDK」并行。
struct CompositeAnalyticsSink: AnalyticsSink {
    let sinks: [any AnalyticsSink]

    func track(name: String, parameters: [String: String]) {
        for sink in sinks {
            sink.track(name: name, parameters: parameters)
        }
    }
}

enum Analytics {
    /// 上线接入示例：
    /// `Analytics.sink = CompositeAnalyticsSink(sinks: [OSLogAnalyticsSink(), YourSDKSink()])`
    nonisolated(unsafe) static var sink: AnalyticsSink = OSLogAnalyticsSink()

    static func track(_ name: String, _ parameters: [String: String] = [:]) {
        sink.track(name: name, parameters: parameters)
    }
}
