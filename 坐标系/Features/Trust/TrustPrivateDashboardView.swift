//
//  TrustPrivateDashboardView.swift
//  坐标系
//
//  「我的信誉」：对齐会员中心 / 账号与安全的 Form + LabeledContent。
//

import SwiftUI

struct TrustPrivateDashboardView: View {
    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(ActivitiesModel.self) private var activities
    @Environment(MessagesModel.self) private var messages
    @AppStorage("profile.membership.active") private var membershipActive = false

    private var photoStore: PhotoVerificationStore { .shared }

    private var status: TrustPrivateStatus {
        _ = TrustService.shared.revision
        _ = photoStore.isVerified
        let friends = messages.conversations.filter(\.isFriendChat).count
        return TrustService.shared.privateStatus(
            userName: app.user.name,
            signals: TrustPrivateSignals(
                profileRatio: ProfileCompletion.ratio(for: app.user),
                isMember: membershipActive,
                isGuest: app.auth.isGuest,
                hasPhone: !app.auth.isGuest && !app.auth.phoneNumber.isEmpty,
                photoVerified: photoStore.isVerified(for: app.user.name),
                accountCreatedAt: ProductLifecycleStore.shared.installAt,
                friendCount: friends,
                liveHostedCount: activities.hostedActivities.count
            )
        )
    }

    var body: some View {
        let data = status
        let photoOK = photoStore.isVerified(for: app.user.name)
        Form {
            Section {
                LabeledContent("等级", value: data.level.title)
                LabeledContent("综合行为分", value: "\(data.score)")
            } header: {
                Text("信用状态")
            } footer: {
                Text("根据近 90 天履约与互动计算，仅自己可见。")
            }

            Section {
                NavigationLink {
                    PhotoVerificationView()
                } label: {
                    Label(
                        photoOK ? "管理形象认证" : "开始形象认证",
                        systemImage: photoOK ? "checkmark.seal.fill" : "camera.viewfinder"
                    )
                    .platformContentSymbolStyle()
                }
            } header: {
                Text("防欺诈认证")
            } footer: {
                Text("自拍与头像本机比对，降低盗图冒用；影像不上传。")
            }

            Section {
                TrustCredentialStatusRows(
                    photoVerified: photoOK,
                    isMember: membershipActive
                )
                TrustBadgeRow(badges: earnedExtraBadges(from: data.badges))
            } header: {
                Text("认证与徽章")
            } footer: {
                Text("形象认证与会员在点亮前后都会显示；点亮后对他人可见。")
            }

            Section {
                TrustAxisBars(axes: data.axes)
            } header: {
                Text("行为健康")
            } footer: {
                Text("自查用，不会展示给其他人。")
            }

            Section {
                TrustFactLabeledRows(
                    facts: data.facts,
                    includeBooking: true
                )
            } header: {
                Text("近 90 天")
            }

            Section {
                TrustTipList(tips: data.growthTips)
            } header: {
                Text("如何提升")
            }

            Section {
                NavigationLink {
                    TrustPublicPreviewView(
                        nickname: app.user.name,
                        buddyItem: buddies.item(for: app.user.name)
                    )
                } label: {
                    Label("预览信任档案", systemImage: "eye")
                        .platformContentSymbolStyle()
                }
            } footer: {
                Text("他人只会看到等级、徽章与履约事实。")
            }

            Section {
                TrustTipList(
                    tips: data.safetyTips,
                    systemImage: "shield.lefthalf.filled"
                )
            } header: {
                Text("安全提示")
            } footer: {
                Text("隐私与拉黑可在设置中管理。")
            }
        }
        .navigationTitle("我的信誉")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }

    private func earnedExtraBadges(from badges: [TrustBadge]) -> [TrustBadge] {
        badges.filter { $0.kind != .photoVerified && $0.kind != .activeMember }
    }
}
