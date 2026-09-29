//
//  ProfileSettingsView.swift
//  坐标系
//
//  「我的」设置根列表。
//

import SwiftUI
import UIKit
import CoordinateModels

struct ProfileSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(ProductLifecycleStore.self) private var lifecycle
    @State private var confirmSignOut = false
    @State private var confirmDeleteAccount = false
    #if DEBUG
    @State private var confirmResetDemo = false
    @State private var confirmClearCaches = false
    #endif

    var body: some View {
        List {
            Section {
                NavigationLink {
                    SettingsAccountView()
                } label: {
                    Label("账号与安全", systemImage: "lock.shield")
                        .platformContentSymbolStyle()
                }
            }

            Section {
                NavigationLink {
                    SettingsNotificationsView()
                } label: {
                    Label("通知设置", systemImage: "bell.badge")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    SettingsPrivacyView()
                } label: {
                    Label("隐私", systemImage: "hand.raised.fill")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    SettingsPermissionsView()
                } label: {
                    Label("系统权限", systemImage: "checkmark.shield")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    SettingsYouthModeView()
                } label: {
                    Label("青少年模式", systemImage: "figure.and.child.holdinghands")
                        .platformContentSymbolStyle()
                }
            } header: {
                Text("隐私与安全")
            }

            Section {
                if !productTips.isEmpty {
                    NavigationLink {
                        SettingsProductTipsView()
                    } label: {
                        Label("产品提示", systemImage: "lightbulb")
                            .platformContentSymbolStyle()
                    }
                }
                NavigationLink {
                    SettingsHelpFeedbackView()
                } label: {
                    Label("帮助与反馈", systemImage: "questionmark.circle")
                        .platformContentSymbolStyle()
                }
                Button {
                    openLegalDocument(.agreement)
                } label: {
                    Label("用户协议", systemImage: "doc.text")
                        .platformContentSymbolStyle()
                }
                Button {
                    openLegalDocument(.privacy)
                } label: {
                    Label("隐私政策", systemImage: "hand.raised")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    UserAgreementView()
                        .toolbarVisibility(.hidden, for: .tabBar)
                } label: {
                    Label("用户协议（离线）", systemImage: "doc.text")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    PrivacyPolicyView()
                        .toolbarVisibility(.hidden, for: .tabBar)
                } label: {
                    Label("隐私政策（离线）", systemImage: "hand.raised")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    SettingsAnnouncementsView()
                } label: {
                    Label("运营公告", systemImage: "megaphone")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    SettingsStorageView()
                } label: {
                    Label("存储与导出", systemImage: "externaldrive")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    ModerationTicketsView()
                } label: {
                    Label("举报记录", systemImage: "flag.fill")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    BlockedUsersView()
                } label: {
                    Label("已拉黑", systemImage: "hand.raised.slash")
                        .platformContentSymbolStyle()
                }
            } header: {
                Text("帮助与反馈")
            }

            Section {
                NavigationLink {
                    SettingsAboutView()
                } label: {
                    Label("关于坐标系", systemImage: "info.circle")
                        .platformContentSymbolStyle()
                }
            }

            Section {
                Button("退出登录", role: .destructive) {
                    confirmSignOut = true
                }
                Button("注销本地账号", role: .destructive) {
                    confirmDeleteAccount = true
                }
            } footer: {
                Text("注销本地账号会清除登录态与本机资料，并回到首次打开状态。")
            }

            #if DEBUG
            Section {
                NavigationLink {
                    RemoteReadPathDebugView()
                } label: {
                    Label("读路径联调 (D2)", systemImage: "antenna.radiowaves.left.and.right")
                        .platformContentSymbolStyle()
                }
                Button("恢复演示数据", role: .destructive) {
                    confirmResetDemo = true
                }
                Button("清空本地屏蔽与工单", role: .destructive) {
                    confirmClearCaches = true
                }
            } header: {
                Text("开发者")
            } footer: {
                Text("仅调试构建可见。读路径联调可开 catalog / community / profile；恢复演示数据会重建本机样本。")
            }
            #endif
        }
        .profileSecondaryListChrome()
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .platformHiddenTabBar()
        #if DEBUG
        .confirmationDialog("恢复演示数据？", isPresented: $confirmResetDemo, titleVisibility: .visible) {
            Button("恢复演示数据", role: .destructive) {
                Task { await app.resetLocalDemoData() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("会清空本机活动、消息、社区、预约、订单与已选头像，并回到默认演示样本。")
        }
        .alert("清空本地屏蔽与工单？", isPresented: $confirmClearCaches) {
            Button("清空", role: .destructive) {
                app.clearLocalCaches()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作只清除本机屏蔽名单与举报工单，且无法恢复。")
        }
        #endif
        .alert("退出登录？", isPresented: $confirmSignOut) {
            Button("退出登录", role: .destructive) {
                Task { await app.signOutLocally() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(ProfileDashboardCopy.logoutConfirmMessage)
        }
        .alert("注销本地账号？", isPresented: $confirmDeleteAccount) {
            Button("注销本地账号", role: .destructive) {
                Task { await app.deleteLocalAccount() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("会删除本机登录态、资料、活动、消息、社区、预约与工单，并回到首次打开状态。")
        }
    }

    private func openLegalDocument(_ document: LegalHostedDocument) {
        let url = document.hostedURL
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    private var productTips: [ProductLifecycleTip] {
        let hasOrders = !ActivityPaymentStore.allOrders().isEmpty
            || !buddies.bookingRecords.isEmpty
        return lifecycle.eligibleTips(
            isGuest: app.auth.isGuest,
            profileComplete: ProfileCompletion.ratio(for: app.user) >= 0.8,
            hasOrders: hasOrders
        )
    }
}

