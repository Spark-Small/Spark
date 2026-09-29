//
//  SettingsAccountView.swift
//  坐标系
//
//  设置 · 账号子页。
//

import SwiftUI
import UIKit
import CoordinateModels

struct SettingsAccountView: View {
    @Environment(AppModel.self) private var app
    @Environment(MembershipStore.self) private var membership
    @Environment(PhotoVerificationStore.self) private var photoVerification
    @State private var showCreateAccount = false
    @State private var showEditProfile = false

    private var completionPercent: Int {
        Int((ProfileCompletion.ratio(for: app.user) * 100).rounded())
    }

    private var photoVerified: Bool {
        _ = photoVerification.isVerified
        return photoVerification.isVerified(for: app.user)
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                    ProfileAvatarView(user: app.user)
                    VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                        Text(app.user.name)
                            .font(.headline)
                        Text(app.auth.accountStatusLabel)
                            .font(.subheadline)
                            .foregroundStyle(app.auth.isGuest ? PlatformStatus.warning : .secondary)
                        Text("资料完整度 \(completionPercent)%")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        if !app.auth.isGuest {
                            TrustCredentialBadgeStrip(
                                photoVerified: photoVerified,
                                isMember: membership.isEntitled,
                                revealLocked: true
                            )
                        }
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }

            if !app.auth.isGuest {
                Section {
                    TrustCredentialStatusRows(
                        photoVerified: photoVerified,
                        isMember: membership.isEntitled
                    )
                    NavigationLink {
                        PhotoVerificationView()
                    } label: {
                        Label(
                            photoVerified ? "管理形象认证" : "开始形象认证",
                            systemImage: photoVerified ? "checkmark.seal.fill" : "camera.viewfinder"
                        )
                        .platformContentSymbolStyle()
                    }
                    NavigationLink {
                        ProfileMembershipView()
                    } label: {
                        Label(
                            membership.isEntitled ? "会员中心" : "开通会员",
                            systemImage: membership.isEntitled ? "checkmark.seal.fill" : "checkmark.seal"
                        )
                        .platformContentSymbolStyle()
                    }
                } header: {
                    Text("认证与徽章")
                }
            }

            Section("身份") {
                LabeledContent("登录状态", value: app.auth.accountStatusLabel)
                LabeledContent("登录方式", value: app.auth.loginMethodLabel)
                LabeledContent("手机号", value: app.auth.maskedPhoneLabel)
                LabeledContent("昵称", value: app.user.name)
                LabeledContent("账号", value: app.user.handle.isEmpty ? "—" : app.user.handle)
                LabeledContent("常驻城市", value: app.user.city.isEmpty ? "—" : app.user.city)
            }

            Section {
                if app.auth.isGuest {
                    Button("创建账号，升级身份") {
                        showCreateAccount = true
                    }
                    .fontWeight(.semibold)
                } else {
                    Button("编辑个人资料") {
                        showEditProfile = true
                    }
                }
            } footer: {
                Text(
                    app.auth.isGuest
                        ? GuestAccessGate.identityReason
                        : "完善头像、兴趣与简介，有助于搭子匹配与活动推荐。"
                )
            }

            Section {
                LabeledContent("UID", value: app.user.publicUIDDisplay)
                    .textSelection(.enabled)
                Button(MessagesCopy.copyUID) {
                    UIPasteboard.general.string = app.user.publicUID
                }
            } header: {
                Text("对外 UID")
            } footer: {
                Text("9 位数字账号，可复制给朋友用于添加好友。内部仍使用稳定 UUID，注销后会重新分配。")
            }
        }
        .navigationTitle("账号与安全")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .sheet(isPresented: $showCreateAccount) {
            ProfileCreateAccountSheet(
                session: app.auth,
                reason: GuestAccessGate.identityReason
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(user: Binding(
                get: { app.user },
                set: { updated in app.updateProfile(updated) }
            ))
            .toolbarVisibility(.hidden, for: .tabBar)
        }
    }
}

