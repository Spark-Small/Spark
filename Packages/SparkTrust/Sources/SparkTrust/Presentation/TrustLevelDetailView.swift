// Module: SparkTrust — Per-level verification detail and retry.

import SparkDesignSystem
import SwiftUI

public struct TrustLevelDetailView: View {
    let level: TrustLevel
    let isCompleted: Bool
    let lastErrorMessage: String?
    let onVerify: () -> Void
    let isLoading: Bool

    public init(
        level: TrustLevel,
        isCompleted: Bool,
        lastErrorMessage: String? = nil,
        onVerify: @escaping () -> Void,
        isLoading: Bool = false
    ) {
        self.level = level
        self.isCompleted = isCompleted
        self.lastErrorMessage = lastErrorMessage
        self.onVerify = onVerify
        self.isLoading = isLoading
    }

    public var body: some View {
        List {
            Section {
                Text(levelDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .sparkSemanticListRow()
            }

            Section(
                String(
                    localized: "trust.level.detail.status",
                    defaultValue: "状态",
                    comment: "Status section"
                )
            ) {
                Label {
                    Text(statusText)
                } icon: {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isCompleted ? Color(.systemGreen) : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .sparkSemanticListRow()
            }

            if let lastErrorMessage, !isCompleted {
                Section(
                    String(
                        localized: "trust.level.detail.error.section",
                        defaultValue: "上次尝试",
                        comment: "Error section"
                    )
                ) {
                    Text(lastErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .sparkSemanticListRow()
                }
            }

            if !isCompleted {
                Section {
                    Button(
                        String(
                            localized: "trust.wizard.verify",
                            defaultValue: "去认证",
                            comment: "Verify CTA"
                        ),
                        action: onVerify
                    )
                    .buttonStyle(.borderedProminent)
                    .sparkMinimumTouchTarget()
                    .disabled(isLoading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .sparkSemanticListRow()
                }
            }
        }
        .sparkSemanticListChrome()
        .navigationTitle(level.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var levelDescription: String {
        switch level {
        case .phone:
            String(
                localized: "trust.level.phone.detail",
                defaultValue: "验证手机号，提升账号安全性。",
                comment: "Phone level detail"
            )
        case .realName:
            String(
                localized: "trust.level.realName.detail",
                defaultValue: "完成实名认证，解锁更多互动能力。",
                comment: "Real name detail"
            )
        case .liveness:
            String(
                localized: "trust.level.liveness.detail",
                defaultValue: "活体检测确认本人操作，防止冒充。",
                comment: "Liveness detail"
            )
        case .career:
            String(
                localized: "trust.level.career.detail",
                defaultValue: "验证职业信息，增强资料可信度。",
                comment: "Career detail"
            )
        case .activityRecord:
            String(
                localized: "trust.level.activity.detail",
                defaultValue: "基于真实活动参与记录累计信任分。",
                comment: "Activity record detail"
            )
        case .socialEndorsement:
            String(
                localized: "trust.level.social.detail",
                defaultValue: "好友背书与社区互动提升社交信任。",
                comment: "Social detail"
            )
        }
    }

    private var statusText: String {
        if isCompleted {
            return String(
                localized: "trust.wizard.level.completed",
                defaultValue: "已完成",
                comment: "Level completed"
            )
        }
        return String(
            localized: "trust.wizard.level.pending",
            defaultValue: "未完成",
            comment: "Level pending"
        )
    }
}

#Preview {
    NavigationStack {
        TrustLevelDetailView(level: .phone, isCompleted: false, onVerify: {})
    }
}
