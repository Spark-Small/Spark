//
//  ProfileGuildsListView.swift
//  坐标系
//

import SwiftUI
import CoordinateModels

struct ProfileGuildsListView: View {
    @Environment(BuddiesModel.self) private var buddies

    var body: some View {
        List {
            if buddies.joinedGuilds.isEmpty {
                ContentUnavailableView(
                    "还没有关注工会",
                    systemImage: "building.2",
                    description: Text("在搭子 · 陪玩页关注工会后，会出现在这里。")
                )
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
        .navigationTitle("我的工会")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CompanionGuild.self) { guild in
            BuddyGuildDetailView(guild: guild)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
    }
}
