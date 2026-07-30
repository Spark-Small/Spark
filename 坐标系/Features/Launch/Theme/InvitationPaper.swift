//
//  InvitationPaper.swift
//  坐标系
//
//  加载信纸与登录页共用的天气便笺文案、水彩背景。
//

import SwiftUI

enum LaunchWeather {
    /// 启动页不抢先弹定位权限；仅在已授权时刷新天气。
    @MainActor
    static func refreshIfAuthorized(_ store: GreetingWeatherStore) async {
        guard LocationService.shared.isAuthorized else { return }
        await store.refresh()
    }
}

struct InvitationNote {
    let salutation: String
    let message: String
    let shortMessage: String
    let systemImage: String
    let temperatureC: Int?

    var greetingTitle: String {
        String(salutation.dropLast())
    }

    static func make(
        date: Date,
        weather: GreetingWeatherStore.Reading?
    ) -> InvitationNote {
        let hour = Calendar.current.component(.hour, from: date)
        let salutation = salutation(for: hour)
        let fallbackSymbol = (6..<18).contains(hour) ? "sun.max.fill" : "moon.stars.fill"

        guard let weather else {
            return InvitationNote(
                salutation: salutation,
                message: timeBasedMessage(for: hour),
                shortMessage: timeBasedShortMessage(for: hour),
                systemImage: fallbackSymbol,
                temperatureC: nil
            )
        }

        let condition = "\(weather.conditionText) \(weather.systemImage)".lowercased()
        let temperature = weather.temperatureC
        let copy = weatherCopy(condition: condition, temperature: temperature, hour: hour)

        return InvitationNote(
            salutation: salutation,
            message: copy.message,
            shortMessage: copy.shortMessage,
            systemImage: displaySymbol(weather.systemImage, fallback: fallbackSymbol),
            temperatureC: temperature
        )
    }

    private static func weatherCopy(
        condition: String,
        temperature: Int,
        hour: Int
    ) -> (message: String, shortMessage: String) {
        if condition.contains("thunder") || condition.contains("雷") {
            return (
                "外面可能有雷雨。\n先听听雨声，等天气温柔一点再出门。",
                "可能有雷雨，晚点再出门。"
            )
        }
        if condition.contains("rain")
            || condition.contains("drizzle")
            || condition.contains("雨") {
            return (
                temperature <= 10
                    ? "雨天有点凉。\n带好伞，多穿一件再出门。"
                    : "外面在下雨。\n带把伞，也去听听街上的雨声。",
                "外面在下雨，出门记得带伞。"
            )
        }
        if condition.contains("snow") || condition.contains("雪") {
            return (
                "雪把街道铺得很安静。\n穿暖一点，出去看看吧。",
                "外面在下雪，记得穿暖一些。"
            )
        }
        if condition.contains("wind") || condition.contains("风") {
            return (
                "今天的风很有精神。\n找件舒服的外套，再轻松出门。",
                "今天风有点大，出门带件外套。"
            )
        }
        if temperature >= 30 {
            return (
                "外面有点热。\n等风凉一点，再找片树荫走走。",
                "外面有点热，记得带水。"
            )
        }
        if temperature <= 8 {
            return (
                "今天有点冷。\n穿暖一些，也很适合出门。",
                "今天有点冷，记得穿暖一些。"
            )
        }
        if condition.contains("cloud") || condition.contains("阴") || condition.contains("云") {
            return (
                "云把阳光收得刚刚好。\n今天很适合出门，慢慢走走。",
                "云把阳光收得刚刚好。"
            )
        }
        return (timeBasedMessage(for: hour), timeBasedShortMessage(for: hour))
    }

    private static func salutation(for hour: Int) -> String {
        switch hour {
        case 5..<9: "早上好，"
        case 9..<12: "上午好，"
        case 12..<14: "中午好，"
        case 14..<18: "下午好，"
        case 18..<23: "晚上好，"
        default: "夜深了，"
        }
    }

    private static func timeBasedMessage(for hour: Int) -> String {
        switch hour {
        case 5..<9:
            "今天很适合出门。\n趁街道刚醒，去吃顿热乎的早餐。"
        case 9..<12:
            "今天很适合出门。\n去逛逛喜欢的地方，也晒晒太阳。"
        case 12..<18:
            "今天很适合出门。\n去做点喜欢的事，认识有趣的人。"
        case 18..<23:
            "晚风正合适。\n吃完饭，出去慢慢走走吧。"
        default:
            "慢一点也没关系。\n若要出门，记得照顾好自己。"
        }
    }

    private static func timeBasedShortMessage(for hour: Int) -> String {
        switch hour {
        case 5..<18: "今天很适合出门。"
        case 18..<23: "晚风正合适，出去走走吧。"
        default: "夜深了，记得照顾好自己。"
        }
    }

    private static func displaySymbol(_ symbol: String, fallback: String) -> String {
        switch symbol {
        case "sun.max": "sun.max.fill"
        case "cloud.sun": "cloud.sun.fill"
        case "cloud": "cloud.fill"
        case "cloud.drizzle": "cloud.drizzle.fill"
        default: symbol.isEmpty ? fallback : symbol
        }
    }
}

struct InvitationPaperArtwork: View {
    enum Presentation: Equatable {
        case note
        case fullPage
    }

    let systemImage: String
    var presentation: Presentation = .note

    private enum Mood: Equatable {
        case sunny, cloudy, rainy, snowy, night
    }

    private var mood: Mood {
        let symbol = systemImage.lowercased()
        if symbol.contains("moon") { return .night }
        if symbol.contains("rain") || symbol.contains("drizzle") || symbol.contains("thunder") {
            return .rainy
        }
        if symbol.contains("snow") || symbol.contains("sleet") { return .snowy }
        if symbol.contains("sun") { return .sunny }
        return .cloudy
    }

    private var isNote: Bool { presentation == .note }

    private var colors: (Color, Color, Color) {
        switch mood {
        case .sunny: (Color.yellow, Color.orange, Color.cyan)
        case .cloudy: (Color.cyan, Color.teal, Color.gray)
        case .rainy: (Color.blue, Color.indigo, Color.cyan)
        case .snowy: (Color.cyan, Color.blue, Color.white)
        case .night: (Color.indigo, Color.purple, Color.blue)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let primary = isNote ? 0.82 : 0.62
            let secondary = isNote ? 0.72 : 0.54

            ZStack {
                watercolorWash(color: colors.0)
                    .frame(width: size.width * primary, height: size.width * primary)
                    .offset(x: size.width * 0.38, y: -size.height * 0.39)

                watercolorWash(color: colors.1)
                    .frame(width: size.width * secondary, height: size.width * secondary)
                    .offset(x: -size.width * 0.42, y: size.height * 0.40)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                colors.2.opacity(isNote ? 0.13 : 0.18),
                                colors.2.opacity(isNote ? 0.02 : 0.05)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: size.width * (isNote ? 0.82 : 0.58),
                        height: size.height * (isNote ? 0.28 : 0.15)
                    )
                    .rotationEffect(.degrees(-8))
                    .offset(x: size.width * 0.28, y: size.height * 0.42)

                weatherBrushMarks(size: size)

                LaunchSurface.invitationPaper.opacity(isNote ? 0.42 : 0.32)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func watercolorWash(color: Color) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(isNote ? 0.22 : 0.29),
                        color.opacity(isNote ? 0.07 : 0.10),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: 130
                )
            )
    }

    @ViewBuilder
    private func weatherBrushMarks(size: CGSize) -> some View {
        switch mood {
        case .rainy:
            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(Color.blue.opacity(0.14))
                    .frame(width: 2, height: 18)
                    .rotationEffect(.degrees(18))
                    .offset(
                        x: -size.width * 0.38 + CGFloat(index) * size.width * 0.15,
                        y: -size.height * 0.08 + CGFloat(index % 2) * 14
                    )
            }
        case .snowy, .night:
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(mood == .night ? 0.45 : 0.68))
                    .frame(width: index.isMultiple(of: 2) ? 4 : 2)
                    .offset(
                        x: -size.width * 0.40 + CGFloat(index) * size.width * 0.13,
                        y: -size.height * 0.25 + CGFloat((index * 17) % 70)
                    )
            }
        case .sunny:
            Circle()
                .stroke(Color.orange.opacity(0.16), lineWidth: 2)
                .frame(width: 58, height: 58)
                .offset(x: size.width * 0.34, y: -size.height * 0.33)
        case .cloudy:
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color.teal.opacity(0.09))
                    .frame(width: 82 - CGFloat(index) * 12, height: 5)
                    .rotationEffect(.degrees(-6))
                    .offset(x: size.width * 0.24, y: -18 + CGFloat(index) * 13)
            }
        }
    }
}
