//
//  ProfileAccountCommercialViews.swift
//  坐标系
//
//  「我的」账号创建、会员与钱包入口页。
//

import SwiftUI

struct ProfileCreateAccountSheet: View {
    @Bindable var session: LocalAuthSession
    @Environment(\.dismiss) private var dismiss

    @State private var phone = ""
    @State private var code = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("手机号") {
                    TextField("手机号码", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    SecureField("验证码", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(PlatformStatus.danger)
                    }
                }

                Section {
                    Button("创建账号") {
                        createAccount()
                    }
                } footer: {
                    Text("本地演示验证码：\(LocalAuthSession.demoCode)")
                }
            }
            .navigationTitle("创建账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .platformSheet(.form)
    }

    private func createAccount() {
        if session.signIn(phone: phone, code: code) {
            dismiss()
        } else {
            errorMessage = "请输入有效手机号，并使用演示验证码。"
        }
    }
}

struct ProfileMembershipView: View {
    @AppStorage("profile.membership.active") private var isActive = false

    var body: some View {
        Form {
            Section("会员状态") {
                LabeledContent("当前状态", value: isActive ? "已开通" : "未开通")
            }

            Section("会员权益") {
                Label("活动优先提醒", systemImage: "bell.badge")
                    .platformContentSymbolStyle()
                Label("专属身份标识", systemImage: "checkmark.seal.fill")
                    .platformContentSymbolStyle()
                Label("更多内容收藏空间", systemImage: "bookmark.fill")
                    .platformContentSymbolStyle()
            }

            Section {
                Button(isActive ? "会员已开通" : "确认开通会员") {
                    isActive = true
                }
                .disabled(isActive)
            } footer: {
                Text("当前为本地演示会员，不会产生真实扣款。")
            }
        }
        .navigationTitle("会员中心")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}

struct ProfileWalletView: View {
    @AppStorage("profile.wallet.balanceCents") private var balanceCents = 0

    private var balanceText: String {
        String(format: "¥%.2f", Double(balanceCents) / 100)
    }

    var body: some View {
        Form {
            Section("余额") {
                LabeledContent("可用余额", value: balanceText)
            }

            Section("支付") {
                LabeledContent("默认方式", value: "余额支付")
            }

            Section("交易记录") {
                ContentUnavailableView(
                    "暂无交易",
                    systemImage: "wallet.bifold",
                    description: Text("活动与陪玩付款记录会出现在这里。")
                )
                .platformContentSymbolStyle()
            }
        }
        .navigationTitle("我的钱包")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}
