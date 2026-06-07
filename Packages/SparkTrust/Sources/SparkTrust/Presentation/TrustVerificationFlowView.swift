// Module: SparkTrust — L1–L3 mock verification flows (pre-SDK UI shells).

import SparkDesignSystem
import SwiftUI

public struct TrustVerificationFlowView: View {
    let level: TrustLevel
    let onComplete: () -> Void
    let isLoading: Bool

    @State private var phoneNumber = ""
    @State private var otpCode = ""
    @State private var realName = ""
    @State private var idNumber = ""
    @State private var livenessStarted = false

    public init(level: TrustLevel, isLoading: Bool = false, onComplete: @escaping () -> Void) {
        self.level = level
        self.isLoading = isLoading
        self.onComplete = onComplete
    }

    public var body: some View {
        Form {
            Section {
                Text(flowDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            switch level {
            case .phone:
                phoneSection
            case .realName:
                realNameSection
            case .liveness:
                livenessSection
            default:
                EmptyView()
            }
        }
        .sparkDismissesKeyboardOnScroll()
        .navigationTitle(level.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            submitBar
                .padding(.horizontal, SparkLayoutMetrics.matchCardPadding)
                .padding(.bottom, SparkLayoutMetrics.compactVerticalPadding)
                .background(.bar)
        }
    }

    private var submitBar: some View {
        VStack(spacing: SparkLayoutMetrics.compactVerticalPadding) {
            Button(action: onComplete) {
                Group {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(
                            String(
                                localized: "trust.flow.submit",
                                defaultValue: "提交认证",
                                comment: "Submit verification"
                            )
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .sparkMinimumTouchTarget()
            .disabled(!canSubmit || isLoading)

            Text(
                String(
                    localized: "trust.flow.mock.footer",
                    defaultValue: "演示环境将模拟通过；正式版将接入运营商/公安/活体 SDK。",
                    comment: "Mock verification footer"
                )
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
    }

    private var phoneSection: some View {
        Section(
            String(localized: "trust.flow.phone.section", defaultValue: "手机号", comment: "Phone section")
        ) {
            TextField(
                String(localized: "trust.flow.phone.placeholder", defaultValue: "11 位手机号", comment: "Phone"),
                text: $phoneNumber
            )
            .keyboardType(.phonePad)
            TextField(
                String(localized: "trust.flow.otp.placeholder", defaultValue: "验证码", comment: "OTP"),
                text: $otpCode
            )
            .keyboardType(.numberPad)
        }
    }

    private var realNameSection: some View {
        Section(
            String(localized: "trust.flow.realName.section", defaultValue: "实名信息", comment: "Real name section")
        ) {
            TextField(
                String(localized: "trust.flow.realName.placeholder", defaultValue: "真实姓名", comment: "Real name"),
                text: $realName
            )
            TextField(
                String(localized: "trust.flow.id.placeholder", defaultValue: "身份证号", comment: "ID number"),
                text: $idNumber
            )
            .textContentType(.username)
        }
    }

    private var livenessSection: some View {
        Section {
            if livenessStarted {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .sparkLoadingAccessibilityLabel(
                        String(
                            localized: "trust.flow.liveness.running",
                            defaultValue: "正在进行活体检测",
                            comment: "Liveness running"
                        )
                    )
            } else {
                Button(
                    String(
                        localized: "trust.flow.liveness.start",
                        defaultValue: "开始活体检测",
                        comment: "Start liveness"
                    )
                ) {
                    livenessStarted = true
                }
                .buttonStyle(.sparkPressable)
                .sparkMinimumTouchTarget()
            }
        } header: {
            Text(
                String(localized: "trust.flow.liveness.section", defaultValue: "活体检测", comment: "Liveness section")
            )
        }
    }

    private var flowDescription: String {
        switch level {
        case .phone:
            String(
                localized: "trust.flow.phone.description",
                defaultValue: "验证本人手机号，用于账号安全与找回。",
                comment: "Phone flow description"
            )
        case .realName:
            String(
                localized: "trust.flow.realName.description",
                defaultValue: "提交姓名与证件号，用于实名认证。",
                comment: "Real name flow description"
            )
        case .liveness:
            String(
                localized: "trust.flow.liveness.description",
                defaultValue: "按提示完成面部动作，确认本人操作。",
                comment: "Liveness flow description"
            )
        default:
            level.localizedTitle
        }
    }

    private var canSubmit: Bool {
        switch level {
        case .phone:
            phoneNumber.count >= 11 && otpCode.count >= 4
        case .realName:
            !realName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && idNumber.count >= 15
        case .liveness:
            livenessStarted
        default:
            false
        }
    }
}

#Preview {
    NavigationStack {
        TrustVerificationFlowView(level: .phone, onComplete: {})
    }
}
