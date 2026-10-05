//
//  TrustPrivateDashboardView.swift
//  坐标系
//
//  「我的信誉」：对齐会员中心 / 账号与安全的 Form + LabeledContent。
//

import CoordinateModels
import SwiftUI

struct TrustPrivateDashboardView: View {
    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(ActivitiesModel.self) private var activities
    @Environment(MessagesModel.self) private var messages
    @Environment(MembershipStore.self) private var membership
    @Environment(TrustService.self) private var trust
    @Environment(ProductLifecycleStore.self) private var lifecycle
    @Environment(PhotoVerificationStore.self) private var photoVerification

    private var status: TrustPrivateStatus {
        _ = trust.revision
        _ = photoVerification.isVerified
        let friends = messages.conversations.filter(\.isFriendChat).count
        let identity = app.identitySignals
        return trust.privateStatus(
            userName: app.user.name,
            signals: TrustPrivateSignals(
                profileRatio: ProfileCompletion.ratio(for: app.user),
                isMember: membership.isEntitled,
                isGuest: false,
                hasPhone: !app.auth.phoneNumber.isEmpty,
                photoVerified: identity.photoVerified,
                identityVerified: identity.realNameVerified,
                accountCreatedAt: lifecycle.installAt,
                friendCount: friends,
                liveHostedCount: activities.hostedActivities.count
            )
        )
    }

    var body: some View {
        let data = status
        let photoOK = photoVerification.isVerified(for: app.user)
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
                TrustCredentialStatusRows(
                    photoVerified: photoOK,
                    isMember: membership.isEntitled
                )
                TrustBadgeShowcase(earned: data.badges, mode: .privateCollection)
            } header: {
                Text("认证与徽章")
            } footer: {
                Text("灰态为未点亮；点亮后出现在对外信任档案奖章墙。会员状态见上行，不进入信任档案。")
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
                Text("他人只会看到等级、已点亮奖章与近 90 天事实；会员标识不在信任档案中。")
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
        .profileSecondaryListChrome()
        .navigationTitle("我的认证")
        .navigationBarTitleDisplayMode(.inline)
    }
}
