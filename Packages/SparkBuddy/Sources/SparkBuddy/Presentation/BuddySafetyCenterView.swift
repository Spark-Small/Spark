// Module: SparkBuddy — Safety escort features (location, SOS, route log).

import SparkDesignSystem
import SwiftUI

public struct BuddySafetyCenterView: View {
    let listingID: String
    let isSessionActive: Bool
    let onTriggerSOS: () -> Void

    public init(
        listingID: String,
        isSessionActive: Bool = false,
        onTriggerSOS: @escaping () -> Void = {}
    ) {
        self.listingID = listingID
        self.isSessionActive = isSessionActive
        self.onTriggerSOS = onTriggerSOS
    }

    public var body: some View {
        List {
            if isSessionActive {
                Section {
                    Label(
                        String(
                            localized: "buddy.safety.session.active",
                            defaultValue: "安全护航已开启",
                            comment: "Active safety session"
                        ),
                        systemImage: "location.fill.viewfinder"
                    )
                    .foregroundStyle(Color.accentColor)
                    Button(role: .destructive) {
                        onTriggerSOS()
                    } label: {
                        Label(
                            String(
                                localized: "buddy.safety.sos.trigger",
                                defaultValue: "一键 SOS 求助",
                                comment: "Trigger SOS"
                            ),
                            systemImage: "sos"
                        )
                        .font(.body.weight(.semibold))
                    }
                    .sparkMinimumTouchTarget()
                }
            }
            Section {
                safetyFeature(
                    icon: "location.fill",
                    title: String(
                        localized: "buddy.safety.center.location.title",
                        defaultValue: "实时定位共享",
                        comment: "Live location title"
                    ),
                    detail: String(
                        localized: "buddy.safety.center.location.detail",
                        defaultValue: "服务开始后自动向平台与紧急联系人共享位置，结束后自动关闭。",
                        comment: "Live location detail"
                    )
                )
                safetyFeature(
                    icon: "sos",
                    title: String(
                        localized: "buddy.safety.center.sos.title",
                        defaultValue: "一键 SOS 求助",
                        comment: "SOS title"
                    ),
                    detail: String(
                        localized: "buddy.safety.center.sos.detail",
                        defaultValue: "触发后同步定位、订单信息与用户资料至平台客服与紧急联系人。",
                        comment: "SOS detail"
                    )
                )
                safetyFeature(
                    icon: "map.fill",
                    title: String(
                        localized: "buddy.safety.center.route.title",
                        defaultValue: "行程记录",
                        comment: "Route log title"
                    ),
                    detail: String(
                        localized: "buddy.safety.center.route.detail",
                        defaultValue: "自动记录路线、时间与停留地点，便于事后追溯与纠纷处理。",
                        comment: "Route log detail"
                    )
                )
                safetyFeature(
                    icon: "exclamationmark.triangle.fill",
                    title: String(
                        localized: "buddy.safety.center.merchant.title",
                        defaultValue: "反酒托饭托监测",
                        comment: "Merchant risk title"
                    ),
                    detail: String(
                        localized: "buddy.safety.center.merchant.detail",
                        defaultValue: "平台监测商户投诉率与异常消费，高风险商户自动预警；违规陪玩永久封禁，用户可先行赔付。",
                        comment: "Merchant risk detail"
                    )
                )
            } header: {
                Text(
                    String(
                        localized: "buddy.safety.center.header",
                        defaultValue: "全程安全护航",
                        comment: "Safety center header"
                    )
                )
            }
        }
        .navigationTitle(
            String(
                localized: "buddy.safety.center.title",
                defaultValue: "安全中心",
                comment: "Safety center nav title"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func safetyFeature(icon: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.body.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
