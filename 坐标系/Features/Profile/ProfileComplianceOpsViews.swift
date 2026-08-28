//
//  ProfileComplianceOpsViews.swift
//  坐标系
//
//  设置：帮助反馈 / 权限 / 合规 / 存储 / 运营公告 / 生命周期条。
//

import SwiftUI
import UserNotifications

// MARK: - Legal consent (login / create account / PIPL)

enum LegalConsentPreference {
    static let acceptedKey = "compliance.legalConsentAccepted"
    static let versionKey = "compliance.legalConsentVersion"
    /// 协议文案重大变更时递增，已同意用户需重新确认。
    static let currentVersion = 1

    static var needsConsent: Bool {
        guard UserDefaults.standard.bool(forKey: acceptedKey) else { return true }
        return UserDefaults.standard.integer(forKey: versionKey) < currentVersion
    }

    static var isAccepted: Bool { !needsConsent }

    static func accept() {
        UserDefaults.standard.set(true, forKey: acceptedKey)
        UserDefaults.standard.set(currentVersion, forKey: versionKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: acceptedKey)
        UserDefaults.standard.removeObject(forKey: versionKey)
    }
}

private enum LegalConsentDocument: String, Identifiable {
    case agreement
    case privacy

    var id: String { rawValue }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .agreement: UserAgreementView()
        case .privacy: PrivacyPolicyView()
        }
    }
}

private enum LegalConsentCopy {
    static var checkboxLabel: AttributedString {
        linked(
            "同意《用户协议》和《隐私政策》",
            agreement: "《用户协议》",
            privacy: "《隐私政策》"
        )
    }

    static let alertMessage = """
    感谢你选择坐标系！我们非常重视你的个人信息和隐私保护：

    1. 我们将遵循合法、正当、必要和诚信原则收集、使用信息。例如为完成账号登录与安全保障，可能收集手机号码等。

    2. 基于你的授权，我们可能申请位置、相机、相册、日历与通知等权限；默认不开启。你可拒绝或在系统设置中关闭，拒绝不影响浏览基本内容。

    请阅读《用户协议》与《隐私政策》。点击「同意」即表示你已阅读并同意上述内容。
    """

    private static func linked(
        _ raw: String,
        agreement: String,
        privacy: String
    ) -> AttributedString {
        var text = AttributedString(raw)
        if let range = text.range(of: agreement) {
            text[range].foregroundColor = .accentColor
            text[range].link = URL(string: "legal://agreement")
        }
        if let range = text.range(of: privacy) {
            text[range].foregroundColor = .accentColor
            text[range].link = URL(string: "legal://privacy")
        }
        return text
    }

    static func open(_ url: URL, into document: Binding<LegalConsentDocument?>) -> OpenURLAction.Result {
        switch url.absoluteString {
        case "legal://agreement":
            document.wrappedValue = .agreement
            return .handled
        case "legal://privacy":
            document.wrappedValue = .privacy
            return .handled
        default:
            return .systemAction
        }
    }
}

private extension View {
    func legalDocumentSheet(_ document: Binding<LegalConsentDocument?>) -> some View {
        sheet(item: document) { doc in
            NavigationStack {
                doc.destination
                    .toolbarVisibility(.hidden, for: .tabBar)
                    .platformSheetConfirmationToolbar("完成") {
                        document.wrappedValue = nil
                    }
            }
            .platformSheet(.browser)
        }
    }
}

extension View {
    /// 合规确认：系统 `.alert`（同意 / 拒绝）；完整协议经勾选行链接查看。
    func legalConsentAlert(
        isPresented: Binding<Bool>,
        onAgree: @escaping () -> Void,
        onReject: @escaping () -> Void
    ) -> some View {
        alert("用户协议与隐私保护", isPresented: isPresented) {
            Button("同意") {
                LegalConsentPreference.accept()
                onAgree()
            }
            Button("拒绝", role: .cancel) {
                onReject()
            }
        } message: {
            Text(LegalConsentCopy.alertMessage)
        }
    }
}

/// 登录 / 创建账号：勾选「同意用户协议和隐私政策」；点选未勾状态时先出协议弹窗。
struct LegalConsentCheckbox: View {
    @Binding var isChecked: Bool
    @Binding var showAlert: Bool
    var centersContent = true

    @State private var document: LegalConsentDocument?

    var body: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.minContentGap) {
            Button(action: toggleOrPrompt) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(isChecked ? Color.accentColor : Color(.tertiaryLabel))
                    .frame(
                        width: PlatformMetrics.navigationBarButtonSide * 0.6,
                        height: PlatformMetrics.navigationBarButtonSide * 0.6
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isChecked ? "已同意用户协议和隐私政策" : "同意用户协议和隐私政策")
            .accessibilityValue(isChecked ? "已勾选" : "未勾选")
            .accessibilityHint(isChecked ? "再次点击可取消勾选" : "打开用户协议与隐私保护说明")

            Text(LegalConsentCopy.checkboxLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .environment(\.openURL, OpenURLAction { url in
                    LegalConsentCopy.open(url, into: $document)
                })
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(Rectangle())
                .onTapGesture(perform: toggleOrPrompt)
        }
        .frame(maxWidth: .infinity, alignment: centersContent ? .center : .leading)
        .legalDocumentSheet($document)
    }

    private func toggleOrPrompt() {
        if isChecked {
            isChecked = false
        } else {
            showAlert = true
        }
    }
}

/// 已登录用户遇协议版本升级：系统 Alert 确认，拒绝可退出。
struct LegalConsentGate: View {
    var onAccepted: () -> Void

    @State private var showAlert = true
    @State private var confirmExit = false

    var body: some View {
        LaunchStageBackground()
            .legalConsentAlert(
                isPresented: $showAlert,
                onAgree: onAccepted,
                onReject: { confirmExit = true }
            )
            .alert("确认退出？", isPresented: $confirmExit) {
                Button("再想想", role: .cancel) {
                    showAlert = true
                }
                Button("退出应用", role: .destructive) {
                    exit(0)
                }
            } message: {
                Text("拒绝将无法使用坐标系。你可以稍后再打开应用并重新阅读协议。")
            }
    }
}

// MARK: - Lifecycle banner

struct ProductLifecycleBanner: View {
    let tip: ProductLifecycleTip
    var onDismiss: () -> Void
    var onOpenSettings: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
            HStack(alignment: .top) {
                Label(tip.title, systemImage: tip.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .platformContentSymbolStyle()
                Spacer(minLength: 8)
                Button("关闭", action: onDismiss)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(tip.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if tip.id == "privacy", let onOpenSettings {
                Button("去设置", action: onOpenSettings)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(PlatformMetrics.contentInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: PlatformMetrics.radiusCard, style: .continuous)
                .fill(PlatformSurface.elevated)
        )
        .padding(.horizontal, PlatformMetrics.contentInset)
    }
}

// MARK: - Help & feedback

struct SettingsHelpFeedbackView: View {
    @State private var category = "体验建议"
    @State private var content = ""
    @State private var contact = ""
    @State private var didSubmit = false
    @State private var showError = false

    private let categories = ["体验建议", "功能故障", "支付与订单", "安全与举报", "其他"]

    var body: some View {
        Form {
            Section("常见问题") {
                DisclosureGroup("如何参加付费活动？") {
                    Text("在活动详情确认费用后完成支付；订单可在「我的订单」查看。游客需先创建账号。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                DisclosureGroup("陪玩预约如何退款？") {
                    Text("在陪玩凭证页点「申请退款」，填写原因与说明并确认后，金额退回本地钱包。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                DisclosureGroup("如何管理隐私？") {
                    Text("设置 → 隐私，可关闭距离、在线展示与陌生人邀约偏好。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                DisclosureGroup("举报后多久处理？") {
                    Text("本机演示会生成举报工单；正式版由运营审核。可在设置 → 举报记录查看状态。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Picker("类型", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                }
                TextField("描述问题或建议", text: $content, axis: .vertical)
                    .lineLimit(3...8)
                TextField("联系方式（选填）", text: $contact)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
            } header: {
                Text("提交反馈")
            } footer: {
                Text("反馈保存在本机，便于演示运营闭环；正式版将同步客服工单。")
            }

            if !OpsContentStore.shared.feedback.isEmpty {
                Section("我提交过的") {
                    ForEach(OpsContentStore.shared.feedback.prefix(8)) { item in
                        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                            LabeledContent(item.category, value: item.status)
                            Text(item.content)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(Formatters.conversationListTime(from: item.createdAt))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .navigationTitle("帮助与反馈")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("提交") {
                    if OpsContentStore.shared.submitFeedback(
                        category: category,
                        content: content,
                        contact: contact
                    ) {
                        content = ""
                        contact = ""
                        didSubmit = true
                    } else {
                        showError = true
                    }
                }
                .fontWeight(.semibold)
            }
        }
        .alert("已收到反馈", isPresented: $didSubmit) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("感谢你的建议，运营同学（演示）已记录。")
        }
        .alert("请写得更具体一些", isPresented: $showError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("反馈至少 4 个字，方便我们理解问题。")
        }
    }
}

// MARK: - Permissions

struct SettingsPermissionsView: View {
    @State private var notificationStatus = "读取中…"
    @State private var locationStatus = "—"
    @State private var trackingStatus = "—"

    var body: some View {
        Form {
            Section {
                permissionRow(
                    title: "通知",
                    systemImage: "bell.badge",
                    status: notificationStatus,
                    detail: "活动提醒、预约与消息"
                )
                permissionRow(
                    title: "跟踪",
                    systemImage: "hand.raised.fill",
                    status: trackingStatus,
                    detail: "个性化推荐与内容体验"
                )
                permissionRow(
                    title: "定位",
                    systemImage: "location",
                    status: locationStatus,
                    detail: "附近活动距离与推荐"
                )
                permissionRow(
                    title: "相册",
                    systemImage: "photo",
                    status: "按系统授权",
                    detail: "发布封面与分享图片"
                )
                permissionRow(
                    title: "日历",
                    systemImage: "calendar",
                    status: "按系统授权",
                    detail: "写入已报名活动"
                )
            } footer: {
                Text("坐标系不会在未授权时读取敏感数据。通知与跟踪会在你同意用户协议后按需请求；更改权限请前往系统设置。")
            }

            Section {
                Button("打开系统设置") {
                    NotificationService.openSystemSettings()
                }
            }
        }
        .navigationTitle("系统权限")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .task { await refresh() }
    }

    private func permissionRow(
        title: String,
        systemImage: String,
        status: String,
        detail: String
    ) -> some View {
        LabeledContent {
            Text(status)
                .foregroundStyle(.secondary)
        } label: {
            Label {
                VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                    Text(title)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } icon: {
                Image(systemName: systemImage)
            }
            .platformContentSymbolStyle()
        }
        .accessibilityElement(children: .combine)
    }

    private func refresh() async {
        let status = await NotificationService.authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral: notificationStatus = "已允许"
        case .denied: notificationStatus = "已拒绝"
        case .notDetermined: notificationStatus = "未请求"
        @unknown default: notificationStatus = "未知"
        }
        trackingStatus = PermissionLaunchPrompts.trackingStatusText
        locationStatus = LocationService.shared.coordinate == nil ? "未定位 / 未授权" : "已授权"
    }
}

// MARK: - Storage & export

struct SettingsStorageView: View {
    @Environment(AppModel.self) private var app
    @State private var confirmClear = false
    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section {
                LabeledContent("安装日", value: Formatters.conversationListTime(from: ProductLifecycleStore.shared.installAt))
                LabeledContent("打开次数", value: "\(ProductLifecycleStore.shared.openCount)")
                LabeledContent("生命周期", value: phaseLabel)
            } header: {
                Text("本机使用")
            }

            Section {
                Button("导出本机数据摘要") {
                    exportSummary()
                }
                Button("清理本地缓存", role: .destructive) {
                    confirmClear = true
                }
            } footer: {
                Text("清理会移除待发送本地通知、拉黑与举报工单中的演示噪音，并清空图片临时缓存；不会退出登录。导出为 JSON，可分享到文件 App。")
            }
        }
        .navigationTitle("存储与导出")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .alert("清理本地缓存？", isPresented: $confirmClear) {
            Button("清理", role: .destructive) {
                app.clearLocalCaches()
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                statusMessage = "已清理通知队列、拉黑与举报工单。"
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("不会删除账号、钱包余额与活动报名记录。")
        }
        .alert("提示", isPresented: Binding(
            get: { statusMessage != nil },
            set: { if !$0 { statusMessage = nil } }
        )) {
            Button("好的", role: .cancel) { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
        .sheet(isPresented: $showExporter) {
            if let exportURL {
                PlatformShareSheet(items: [exportURL])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
    }

    private var phaseLabel: String {
        switch ProductLifecycleStore.shared.phase {
        case .new: "新用户"
        case .active: "活跃"
        case .returning: "回流"
        }
    }

    private func exportSummary() {
        struct ExportPayload: Encodable {
            let exportedAt: Date
            let userID: String
            let nickname: String
            let isGuest: Bool
            let openCount: Int
            let version: String
            let blockedCount: Int
            let ticketCount: Int
            let feedbackCount: Int
        }

        let payload = ExportPayload(
            exportedAt: .now,
            userID: app.user.id.uuidString,
            nickname: app.user.name,
            isGuest: app.auth.isGuest,
            openCount: ProductLifecycleStore.shared.openCount,
            version: ProductLifecycleStore.shared.versionLabel,
            blockedCount: app.blockedUserNames.count,
            ticketCount: app.moderationTickets.count,
            feedbackCount: OpsContentStore.shared.feedback.count
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else {
            statusMessage = "导出失败"
            return
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("coordinate-export-\(UUID().uuidString.prefix(8)).json")
        do {
            try data.write(to: url, options: [.atomic])
            exportURL = url
            showExporter = true
            statusMessage = "已生成导出文件"
        } catch {
            statusMessage = "写入导出文件失败"
        }
    }
}

// MARK: - Announcements

struct SettingsAnnouncementsView: View {
    private var store: OpsContentStore { OpsContentStore.shared }

    var body: some View {
        List {
            if store.announcements.isEmpty {
                ContentUnavailableView("暂无公告", systemImage: "megaphone")
            } else {
                Section {
                    ForEach(store.announcements.sorted {
                        if $0.pin != $1.pin { return $0.pin && !$1.pin }
                        return $0.publishedAt > $1.publishedAt
                    }) { item in
                        VStack(alignment: .leading, spacing: PlatformMetrics.detailMicroSpacing) {
                            HStack {
                                Text(item.title)
                                    .font(.body.weight(.semibold))
                                if item.pin {
                                    Text("置顶")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(item.body)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(Formatters.conversationListTime(from: item.publishedAt))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("标为已读") {
                                store.dismissAnnouncement(item.id)
                            }
                        }
                    }
                } footer: {
                    Text("左右滑动可标为已读。正式版将支持定向推送与活动运营位。")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("运营公告")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
    }
}

// MARK: - Acknowledgments

struct SettingsAcknowledgmentsView: View {
    var body: some View {
        Form {
            Section("声明") {
                Text("坐标系当前为本地演示构建，未嵌入第三方广告或统计分析 SDK。系统框架（SwiftUI、UserNotifications、PassKit 等）遵循 Apple 许可。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Section("设计参考") {
                Text("交互与信息架构借鉴成熟社交与本地生活产品的常见设置 / 合规分区，文案与流程已按本产品场景改写。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("开源与致谢")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
    }
}

// MARK: - Youth mode

struct SettingsYouthModeView: View {
    @AppStorage(YouthModePreference.key) private var enabled = false

    var body: some View {
        Form {
            Section {
                Toggle("开启青少年模式", isOn: $enabled)
            } footer: {
                Text("开启后将限制会员开通与钱包充值入口（本地演示）。正式版将支持监护人验证与时段限制。")
            }
            if enabled {
                Section("当前限制") {
                    Label("不可开通会员", systemImage: "checkmark.seal")
                    Label("不可钱包充值与付费预约", systemImage: "creditcard")
                    Label("仍可浏览活动与社区", systemImage: "eye")
                }
                .platformContentSymbolStyle()
            }
        }
        .navigationTitle("青少年模式")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
    }
}

enum YouthModePreference {
    static let key = "settings.compliance.youthMode"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}
