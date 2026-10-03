//
//  RemoteReadPathDebugView.swift
//  坐标系
//
//  DEBUG：活动 / 广场 / 我的读路径联调开关。
//

#if DEBUG
import CoordinateFeatureFlags
import SwiftUI

struct RemoteReadPathDebugView: View {
    @Environment(AppModel.self) private var app
    @State private var catalog = FeatureFlags.useRemoteCatalog
    @State private var community = FeatureFlags.useRemoteCommunity
    @State private var profile = FeatureFlags.useRemoteProfile
    @State private var buddies = FeatureFlags.useRemoteBuddies
    @State private var sampleBuddies = FeatureFlags.useSampleBuddiesCatalog
    @State private var auth = FeatureFlags.useRemoteAuth
    @State private var syncing = false
    @State private var endpointChoice = EndpointChoice.current

    private enum EndpointChoice: String, CaseIterable, Identifiable {
        case staging
        case local
        case custom

        var id: String { rawValue }

        static var current: EndpointChoice {
            switch APIConfiguration.baseURLOverride {
            case nil, APIConfiguration.localBaseURLString: return .local
            case APIConfiguration.stagingBaseURLString: return .staging
            default: return .custom
            }
        }

        var title: String {
            switch self {
            case .staging: return "测试机"
            case .local: return "本机 8000"
            case .custom: return "自定义"
            }
        }
    }

    var body: some View {
        List {
            Section {
                Toggle("远程登录 (useRemoteAuth)", isOn: $auth)
                Toggle("活动目录 (useRemoteCatalog)", isOn: $catalog)
                Toggle("广场 (useRemoteCommunity)", isOn: $community)
                Toggle("我的资料 (useRemoteProfile)", isOn: $profile)
                Toggle("搭子远程 (useRemoteBuddies)", isOn: $buddies)
                Toggle("搭子样例货架 (useSampleBuddiesCatalog)", isOn: $sampleBuddies)
                    .disabled(!buddies)
                Button("一键开启读路径联调") {
                    APIConfiguration.enableReadPathRemoteIntegration()
                    refreshToggles()
                }
                Button("恢复样例搭子货架") {
                    FeatureFlags.restoreLocalBuddiesSampleCatalog()
                    refreshToggles()
                }
            } header: {
                Text("旗标")
            } footer: {
                Text("需已远程登录并持有 JWT。改旗标后点下方「立即同步」。关「搭子远程」或点「恢复样例搭子货架」可重新看到 Sample 找搭子页。")
            }

            Section {
                Picker("API", selection: $endpointChoice) {
                    ForEach(EndpointChoice.allCases) { choice in
                        Text(choice.title).tag(choice)
                    }
                }
                .onChange(of: endpointChoice) { _, choice in
                    switch choice {
                    case .staging:
                        // 测试机仍为 HTTP：仅 DEBUG 联调；Info.plist 已去掉明文 IP 例外时需本机隧道或临时加回 ATS。
                        APIConfiguration.baseURLOverride = APIConfiguration.stagingBaseURLString
                    case .local:
                        APIConfiguration.baseURLOverride = nil
                    case .custom:
                        break
                    }
                }
                Text(APIConfiguration.baseURL.absoluteString)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            } header: {
                Text("端点")
            }

            Section {
                Button {
                    Task {
                        syncing = true
                        await app.resyncRemoteReadPath()
                        syncing = false
                    }
                } label: {
                    if syncing {
                        ProgressView()
                    } else {
                        Text("立即同步读路径")
                    }
                }
                .disabled(syncing || AuthTokenStore.accessToken == nil)

                Text(RemoteSyncStatus.summaryLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Array(RemoteSyncStatus.entries.prefix(6).enumerated()), id: \.offset) { _, entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.ok ? "✓" : "✗") \(entry.domain)")
                            .font(.subheadline.weight(.medium))
                        Text(entry.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("同步")
            } footer: {
                if AuthTokenStore.accessToken == nil {
                    Text("无 access token：请用远程短信登录后再同步。")
                }
            }
        }
        .navigationTitle("读路径联调")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshToggles)
        .onChange(of: catalog) { _, v in APIConfiguration.setUseRemoteCatalog(v) }
        .onChange(of: community) { _, v in APIConfiguration.setUseRemoteCommunity(v) }
        .onChange(of: profile) { _, v in APIConfiguration.setUseRemoteProfile(v) }
        .onChange(of: buddies) { _, v in
            APIConfiguration.setUseRemoteBuddies(v)
            if !v {
                FeatureFlags.setUseSampleBuddiesCatalog(true)
            }
            refreshToggles()
        }
        .onChange(of: sampleBuddies) { _, v in FeatureFlags.setUseSampleBuddiesCatalog(v) }
        .onChange(of: auth) { _, v in APIConfiguration.setUseRemoteAuth(v) }
    }

    private func refreshToggles() {
        catalog = FeatureFlags.useRemoteCatalog
        community = FeatureFlags.useRemoteCommunity
        profile = FeatureFlags.useRemoteProfile
        buddies = FeatureFlags.useRemoteBuddies
        sampleBuddies = FeatureFlags.useSampleBuddiesCatalog
        auth = FeatureFlags.useRemoteAuth
        endpointChoice = .current
    }
}
#endif
