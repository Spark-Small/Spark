//
//  CommunityDynamicsChrome.swift
//  坐标系
//
//  广场动态区：List 首段分类 chip + 通知关闭提示条。
//  「发现作者」只靠内容 Feed + 帖卡作者行关注；不做人轨「推荐关注」。
//

import SwiftUI
import CoordinateModels

// MARK: - Feed filter chips

struct CommunityFeedFilterBar: View {
    @Binding var filter: CommunityFeedFilter

    var body: some View {
        PlatformFilterChipBar(padsHorizontally: false) {
            ForEach(CommunityFeedFilter.allCases) { item in
                PlatformFilterChipButton(
                    title: item.title,
                    systemImage: item.systemImage,
                    isSelected: filter == item,
                    accessibilityHint: item.accessibilityHint
                ) {
                    filter = item
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(CommunityBrowseCopy.filterBarAccessibility)
    }
}

// MARK: - Follow session (发现作者：关注后本会话保留帖)

private enum CommunityRetainFollowedAuthorKey: EnvironmentKey {
    // 闭包非 Sendable；Environment 默认值仅读一次，与 PlatformChromeMeasurementsKey 同规。
    nonisolated(unsafe) static let defaultValue: ((String) -> Void)? = nil
}

extension EnvironmentValues {
    /// 「发现作者」下点关注时登记作者，避免帖立刻被筛掉。
    var communityRetainFollowedAuthor: ((String) -> Void)? {
        get { self[CommunityRetainFollowedAuthorKey.self] }
        set { self[CommunityRetainFollowedAuthorKey.self] = newValue }
    }
}

// MARK: - Follow CTA chrome（帖卡作者行 / 作者资料）

struct CommunityFollowButtonChrome: ViewModifier {
    var following: Bool
    var controlSize: ControlSize = .small

    func body(content: Content) -> some View {
        if following {
            content.activitySecondaryCTA(controlSize: controlSize)
        } else {
            content.activityPrimaryCTA(controlSize: controlSize)
        }
    }
}

// MARK: - Notifications-off banner（对齐消息收件箱提示条）

struct CommunityNotificationsOffBanner: View {
    var onTurnOn: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            Label {
                Text("\(CommunityDynamicsCopy.notificationsOffPrefix)\(Text(CommunityDynamicsCopy.notificationsOffAction).fontWeight(.semibold))")
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            } icon: {
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(.secondary)
                    .platformContentSymbolStyle()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTurnOn)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(CommunityDynamicsCopy.notificationsOffAccessibility)

            Button(CommunityDynamicsCopy.dismiss, action: onDismiss)
                .font(PlatformListTypography.footnoteEmphasized)
                .buttonStyle(.borderless)
        }
        .padding(.horizontal, PlatformConversationListRow.horizontalInset)
        .padding(.vertical, PlatformConversationListRow.verticalInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .platformBarMaterialFill()
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
