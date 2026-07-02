// Module: SparkNotifications — First-launch push permission onboarding.

import SparkCore
import SparkDesignSystem
import SwiftUI
import UserNotifications

public enum SparkPushPermissionPreferences {
    private static let hasSeenGuideKey = "spark.pushPermissionGuideSeen"

    public static var hasSeenGuide: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenGuideKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenGuideKey) }
    }
}

public struct PushNotificationPermissionGuideView: View {
    public var onContinue: () -> Void
    public var onSkip: () -> Void

    @State private var isRequesting = false

    public init(onContinue: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.onContinue = onContinue
        self.onSkip = onSkip
    }

    public var body: some View {
        VStack(spacing: SparkLayoutMetrics.matchCardPadding) {
            Spacer(minLength: 0)

            Image(systemName: "bell.badge")
                .font(.system(size: 56))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text(
                String(
                    localized: "notifications.guide.title",
                    defaultValue: "开启通知",
                    comment: "Push guide title"
                )
            )
            .font(.title2.weight(.bold))
            .multilineTextAlignment(.center)

            Text(
                String(
                    localized: "notifications.guide.body",
                    defaultValue: "及时收到配对、新消息和活动提醒。你可在系统设置中随时关闭。",
                    comment: "Push guide body"
                )
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, SparkLayoutMetrics.matchCardPadding)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, SparkLayoutMetrics.matchCardPadding)
        .padding(.top, SparkLayoutMetrics.matchCardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: SparkLayoutMetrics.sectionVerticalPadding) {
                Button(
                    String(
                        localized: "notifications.guide.enable",
                        defaultValue: "开启通知",
                        comment: "Enable notifications"
                    )
                ) {
                    Task { await requestPermission() }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .sparkMinimumTouchTarget()
                .disabled(isRequesting)

                Button(
                    String(localized: "notifications.guide.later", defaultValue: "稍后再说", comment: "Later")
                ) {
                    SparkPermissionTelemetry.promptSkipped(
                        permission: .notifications,
                        source: .pushPermissionGuide
                    )
                    markSeen()
                    onSkip()
                }
                .buttonStyle(.sparkPressable)
                .sparkMinimumTouchTarget()
            }
            .padding(.horizontal, SparkLayoutMetrics.matchCardPadding)
            .padding(.bottom, SparkLayoutMetrics.matchCardPadding)
            .background(.bar)
        }
        .overlay {
            if isRequesting {
                ProgressView()
                    .sparkLoadingAccessibilityLabel(
                        String(
                            localized: "notifications.guide.loading.a11y",
                            defaultValue: "正在请求通知权限",
                            comment: "Push guide loading"
                        )
                    )
            }
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            SparkPermissionTelemetry.statusChecked(
                permission: .notifications,
                source: .pushPermissionGuide,
                status: SparkPermissionTelemetry.notificationStatus(from: settings.authorizationStatus)
            )
        }
    }

    private func requestPermission() async {
        isRequesting = true
        defer { isRequesting = false }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let source = SparkPermissionTelemetry.Source.pushPermissionGuide
        SparkPermissionTelemetry.statusChecked(
            permission: .notifications,
            source: source,
            status: SparkPermissionTelemetry.notificationStatus(from: settings.authorizationStatus)
        )

        if settings.authorizationStatus == .notDetermined {
            SparkPermissionTelemetry.promptRequested(permission: .notifications, source: source)
        }

        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        if settings.authorizationStatus == .notDetermined {
            SparkPermissionTelemetry.promptResult(
                permission: .notifications,
                source: source,
                outcome: SparkPermissionTelemetry.notificationOutcome(granted: granted)
            )
        }

        markSeen()
        onContinue()
    }

    private func markSeen() {
        SparkPushPermissionPreferences.hasSeenGuide = true
    }
}

#Preview {
    PushNotificationPermissionGuideView(onContinue: {}, onSkip: {})
}
