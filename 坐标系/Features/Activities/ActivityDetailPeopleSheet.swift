//
//  ActivityDetailPeopleSheet.swift
//  坐标系
//
//  活动详情：参与者列表 Sheet。
//

import SwiftUI
import CoordinateModels

struct ActivityDetailPeopleSheet: View {
    let activity: Activity

    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()
    @State private var memberContactRoute: PeerContactRoute?

    private var members: [String] {
        var names = [activity.hostName]
        for name in activity.displayParticipants where !names.contains(name) {
            names.append(name)
        }
        return names
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach(Array(members.enumerated()), id: \.offset) { index, name in
                        HStack {
                            NavigationLink(value: name) {
                                Label {
                                    VStack(alignment: .leading) {
                                        Text(name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(index == 0 ? ActivityDetailCopy.peopleHostRole : ActivityDetailCopy.peopleMemberRole)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    PlatformListAvatarView(name: name)
                                }
                                .labelStyle(.titleAndIcon)
                            }
                            .buttonStyle(.plain)

                            Spacer(minLength: 0)

                            ActivityDetailControls.GlassIconButton(
                                systemImage: "bubble.left",
                                accessibilityLabel: "私信\(name)"
                            ) {
                                openMemberChat(with: name)
                            }
                        }
                    }
                } header: {
                    Text("共 \(activity.joined) 人参与")
                } footer: {
                    if members.count < activity.joined {
                        Text("已展示 \(members.count) 位伙伴。\(ActivityDetailCopy.peopleSheetFooter)")
                    } else {
                        Text(ActivityDetailCopy.peopleSheetFooter)
                    }
                }
            }
            .navigationTitle("活动成员")
            .navigationBarTitleDisplayMode(.inline)
            .platformSheetConfirmationToolbar(ActivityDetailCopy.peopleSheetDone)
            .navigationDestination(for: String.self) { name in
                memberProfile(name)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .peerContactDestination(route: $memberContactRoute)
        }
        .independentNavigationSheetChrome()
        .platformSheet(.browser)
    }

    @ViewBuilder
    private func memberProfile(_ name: String) -> some View {
        let context: ConversationChatContext = name == activity.hostName
            ? .activityHost(activityID: activity.id)
            : .activityMember(activityID: activity.id)
        if let item = buddies.item(for: name) {
            BuddyDetailRouteView(item: item)
        } else {
            CommunityAuthorProfileView(
                name: name,
                chatContextOverride: context
            )
        }
    }

    private func openMemberChat(with name: String) {
        let context: ConversationChatContext = name == activity.hostName
            ? .activityHost(activityID: activity.id)
            : .activityMember(activityID: activity.id)
        memberContactRoute = app.openPeerContact(with: name, context: context)
    }
}

