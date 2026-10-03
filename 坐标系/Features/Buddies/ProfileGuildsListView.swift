//
//  ProfileGuildsListView.swift
//  坐标系
//

import SwiftUI
import CoordinateModels

struct ProfileGuildsListView: View {
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app

    var body: some View {
        List {
            if buddies.joinedGuilds.isEmpty {
                ContentUnavailableView {
                    Label(BuddyBrowseCopy.Guilds.emptyTitle, systemImage: "building.2")
                } description: {
                    Text(BuddyBrowseCopy.Guilds.emptyBody)
                } actions: {
                    Button(BuddyBrowseCopy.Guilds.browseCTA) {
                        app.selectedTab = .buddies
                    }
                    .activityPrimaryCTA(controlSize: .regular)
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(buddies.joinedGuilds) { guild in
                    NavigationLink(value: guild) {
                        HStack(spacing: PlatformMetrics.cardFooterSpacing) {
                            Image(systemName: guild.systemImage)
                                .font(.title3)
                                .foregroundStyle(PlatformStatus.warning)
                                .frame(width: 36, height: 36)
                                .background(
                                    PlatformStatus.warning.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text(guild.name)
                                    .font(.body.weight(.medium))
                                    .lineLimit(1)
                                Text("\(guild.specialty) · \(guild.city)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, PlatformMetrics.hairlineSpacing)
                    }
                }
            }
        }
        .navigationTitle(BuddyBrowseCopy.Guilds.listTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CompanionGuild.self) { guild in
            BuddyGuildDetailView(guild: guild)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
    }
}
