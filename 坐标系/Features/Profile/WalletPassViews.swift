//
//  WalletPassViews.swift
//  坐标系
//
//  PassKit 通行证 Form：分发通道 + 本机更新 Web Service + AddPassToWalletButton。
//

import PassKit
import SwiftUI
import CoordinateModels

struct WalletPassesSection: View {
    @Environment(WalletPassStore.self) private var passStore

    var body: some View {
        Section {
            if passStore.passes.isEmpty {
                ContentUnavailableView {
                    Label("暂无通行证", systemImage: "wallet.bifold")
                } description: {
                    Text("支付活动或开通会员后，可在「我的」凭证夹与详情中加入 Apple Wallet。")
                }
                .platformContentSymbolStyle()
            } else {
                ForEach(passStore.passes) { pass in
                    NavigationLink {
                        WalletPassDetailView(passID: pass.id)
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text(pass.title)
                                Text(passLifecycleSubtitle(pass))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: pass.style.systemImage)
                        }
                        .platformContentSymbolStyle()
                    }
                }
            }
        } header: {
            Text("Apple Wallet")
        } footer: {
            Text(WalletPassKitCopy.sectionFooter)
        }
    }

    private func passLifecycleSubtitle(_ pass: PassRecord) -> String {
        var parts = [pass.style.displayName, pass.distributionState.displayName]
        if pass.voided { parts.append("已作废") }
        return parts.joined(separator: " · ")
    }
}

struct WalletPassDetailView: View {
    let passID: UUID

    @Environment(WalletPassStore.self) private var passStore
    @Environment(ActivitiesModel.self) private var activities
    #if DEBUG
    @Environment(PassUpdateWebService.self) private var updateService
    @State private var exportedFile: ExportedPassFile?
    @State private var showExportError = false
    @State private var exportError: String?
    @State private var pullResult: String?
    @State private var showPullResult = false
    #endif

    private var pass: PassRecord? {
        passStore.pass(id: passID)
    }

    var body: some View {
        Group {
            if let pass,
               pass.style == .eventTicket,
               let activityID = activityID(for: pass) {
                ActivityCredentialExpandedView(activityID: activityID)
            } else {
                passDetailForm
            }
        }
        #if DEBUG
        .alert("无法导出", isPresented: $showExportError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
        .alert("模拟拉取结果", isPresented: $showPullResult) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(pullResult ?? "")
        }
        .sheet(item: $exportedFile) { file in
            SharePassFileSheet(url: file.url)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        #endif
    }

    @ViewBuilder
    private var passDetailForm: some View {
        Form {
            if let pass {
                if pass.voided {
                    Section {
                        Label("此通行证已作废", systemImage: "xmark.seal")
                            .foregroundStyle(PlatformStatus.warning)
                    }
                }

                Section {
                    WalletPassRecordFace(pass: pass)
                    .listRowInsets(PlatformWalletPassListRow.insets)
                    .listRowBackground(Color.clear)
                } header: {
                    Text("票面")
                }

                Section {
                    WalletPassAddToWalletControl(pass: pass)
                } header: {
                    Text("加入 Apple Wallet")
                } footer: {
                    Text(WalletPassKitCopy.addFooter)
                }

                identitySection(pass)

                if !pass.primaryFields.isEmpty {
                    Section("主要信息") {
                        ForEach(pass.primaryFields) { field in
                            LabeledContent(field.label, value: field.value)
                        }
                    }
                }

                if !pass.secondaryFields.isEmpty {
                    Section("次要信息") {
                        ForEach(pass.secondaryFields) { field in
                            LabeledContent(field.label, value: field.value)
                        }
                    }
                }

                if !pass.auxiliaryFields.isEmpty {
                    Section("附加信息") {
                        ForEach(pass.auxiliaryFields) { field in
                            LabeledContent(field.label, value: field.value)
                        }
                    }
                }

                if !pass.backFields.isEmpty {
                    Section("背面") {
                        ForEach(pass.backFields) { field in
                            LabeledContent(field.label, value: field.value)
                        }
                    }
                }

                #if DEBUG
                distributionSection(pass)
                webServiceSection(pass)
                updateLogSection
                developerSection(pass)
                #endif
            } else {
                ContentUnavailableView("通行证不存在", systemImage: "ticket")
            }
        }
        .listSectionSpacing(.compact)
        .navigationTitle(pass?.style.displayName ?? "通行证")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func activityID(for pass: PassRecord) -> Activity.ID? {
        guard let relatedID = pass.relatedID else { return nil }
        if activities.activity(id: relatedID) != nil {
            return relatedID
        }
        if let order = ActivityPaymentStore.order(id: relatedID) {
            return order.activityID
        }
        return nil
    }

    @ViewBuilder
    private func identitySection(_ pass: PassRecord) -> some View {
        Section("通行证") {
            LabeledContent("类型", value: pass.style.displayName)
            LabeledContent("说明", value: pass.description)
            LabeledContent(
                "系统 Wallet",
                value: pass.addedToSystemWallet || PassKitLoader.isInSystemWallet(pass)
                    ? "已添加"
                    : "未添加"
            )
            LabeledContent("作废", value: pass.voided ? "是" : "否")
            if let relevant = pass.relevantDate {
                LabeledContent("相关时间", value: Formatters.activityEventTime(from: relevant))
            }
            if let expires = pass.expirationDate {
                LabeledContent("过期", value: Formatters.activityEventTime(from: expires))
            }
            #if DEBUG
            LabeledContent("序列号", value: pass.serialNumber)
            LabeledContent("Pass Type ID", value: pass.passTypeIdentifier)
            LabeledContent("分发状态", value: pass.distributionState.displayName)
            LabeledContent("最近更新", value: pass.lastUpdatedTag)
            #endif
        }
    }

    #if DEBUG
    @ViewBuilder
    private func distributionSection(_ pass: PassRecord) -> some View {
        Section {
            Button("导出未签名 Pass 包") {
                exportUnsigned(pass)
            }
            Button("写入 Documents/UnsignedWalletPasses") {
                writeUnsigned(pass)
            }
            Button("导出多票包 (.pkpasses)") {
                exportBundle(including: pass)
            }
            LabeledContent(
                "已签名落盘",
                value: PassDistribution.hasSignedPackage(for: pass) ? "有" : "无"
            )
        } header: {
            Text("分发 · 通道")
        } footer: {
            Text(WalletPassKitCopy.distributionFooter)
        }
    }

    @ViewBuilder
    private func webServiceSection(_ pass: PassRecord) -> some View {
        Section {
            LabeledContent("webServiceURL", value: pass.webServiceURL)
            LabeledContent("authenticationToken", value: String(pass.authenticationToken.prefix(12)) + "…")
            Button("模拟设备注册更新") {
                updateService.simulateDeviceRegister(for: pass)
            }
            Button("模拟设备拉取更新") {
                simulateDevicePull(for: pass)
            }
        } header: {
            Text("更新 · Web Service（本机）")
        } footer: {
            Text(WalletPassKitCopy.webServiceFooter)
        }
    }

    @ViewBuilder
    private var updateLogSection: some View {
        let events = Array(updateService.events.prefix(12))
        Section {
            if events.isEmpty {
                Text("暂无更新事件")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(events) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.kind.displayName)
                            .font(.subheadline.weight(.semibold))
                        Text(event.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Formatters.activityEventTime(from: event.at))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            Text("更新 · 事件日志")
        }
    }

    @ViewBuilder
    private func developerSection(_ pass: PassRecord) -> some View {
        Section {
            LabeledContent("Team ID", value: PassConfiguration.teamIdentifier)
            LabeledContent("条码", value: pass.barcodeMessage)
            LabeledContent("签名包目录", value: "Documents/SignedWalletPasses/")
        } header: {
            Text("开发 / Pass Builder")
        } footer: {
            Text(WalletPassKitCopy.exportFooter)
        }
    }

    private func exportUnsigned(_ pass: PassRecord) {
        do {
            let url = try PassDistribution.exportUnsignedTemporary(for: pass)
            passStore.markExported(pass.id)
            exportedFile = ExportedPassFile(url: url)
        } catch {
            exportError = error.localizedDescription
            showExportError = true
        }
    }

    private func writeUnsigned(_ pass: PassRecord) {
        do {
            let url = try PassDistribution.writeUnsignedToDocuments(for: pass)
            passStore.markExported(pass.id)
            pullResult = "已写入\n\(url.lastPathComponent)"
            showPullResult = true
        } catch {
            exportError = error.localizedDescription
            showExportError = true
        }
    }

    private func exportBundle(including pass: PassRecord) {
        do {
            let peers = passStore.activePasses.prefix(10)
            let url = try PassDistribution.makePassBundle(passes: Array(peers))
            passStore.markExported(pass.id)
            exportedFile = ExportedPassFile(url: url)
        } catch {
            exportError = error.localizedDescription
            showExportError = true
        }
    }

    private func simulateDevicePull(for pass: PassRecord) {
        let deviceID = LocalUserIdentity.current.uuidString
        if !updateService.registrations.contains(where: {
            $0.deviceLibraryIdentifier == deviceID && $0.serialNumber == pass.serialNumber
        }) {
            updateService.simulateDeviceRegister(for: pass)
        }
        let previous = pass.lastUpdated.addingTimeInterval(-1)
        let list = updateService.serialNumbersUpdatedSince(
            deviceLibraryIdentifier: deviceID,
            passesUpdatedSince: PassDateFormatting.tag(from: previous),
            passes: passStore.passes
        )
        do {
            let data = try updateService.latestPassPackage(
                serialNumber: pass.serialNumber,
                authenticationToken: pass.authenticationToken,
                pass: pass
            )
            pullResult = """
            可更新序列号：\(list.serialNumbers.isEmpty ? "（无）" : list.serialNumbers.joined(separator: ", "))
            lastUpdated：\(list.lastUpdated)
            最新包大小：\(data.count) 字节
            """
            showPullResult = true
        } catch {
            exportError = error.localizedDescription
            showExportError = true
        }
    }    #endif

}

/// WWDC22 官方 SwiftUI：`AddPassToWalletButton`；无已签名包时走系统说明回退。
struct WalletPassAddToWalletControl: View {
    let pass: PassRecord

    @Environment(WalletPassStore.self) private var passStore
    @State private var showSetupHelp = false

    private var pkPass: PKPass? {
        PassKitLoader.loadPKPass(for: pass)
    }

    var body: some View {
        Group {
            if pass.voided {
                Text("已作废，无法加入 Wallet")
                    .foregroundStyle(.secondary)
            } else if let pkPass, PassKitLoader.canAddPasses() {
                AddPassToWalletButton([pkPass]) { success in
                    if success {
                        passStore.markAddedToSystemWallet(pass.id)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .addPassToWalletButtonStyle(.blackOutline)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } else {
                Button {
                    showSetupHelp = true
                } label: {
                    Label("加入 Apple Wallet", systemImage: "wallet.bifold")
                }
            }
        }
        .alert("需要签名通行证", isPresented: $showSetupHelp) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(WalletPassKitCopy.signingHelp)
        }
        .onAppear {
            if !pass.addedToSystemWallet, PassKitLoader.isInSystemWallet(pass) {
                passStore.markAddedToSystemWallet(pass.id)
            }
        }
    }
}

enum WalletPassKitCopy {
    static let sectionFooter =
        "通行证遵循 PassKit：源 → 构建 → 分发 → 更新 Web Service → 系统 Wallet。"

    static let addFooter =
        "将 Pass Builder 签好的 .pkpass 放入 Documents/SignedWalletPasses/，文件名与序列号一致后，此处显示系统「加入 Apple Wallet」按钮。"

    static let distributionFooter =
        "官方分发：App 内加入、网页下载、邮件附件、多票 .pkpasses。本机可导出未签名包供 Pass Builder 签名。"

    static let webServiceFooter =
        "真机更新需 HTTPS webServiceURL + APNs。此处用本机模拟 register / list serials / get latest，不发起真实网络。"

    static let exportFooter =
        "导出未签名包 → Pass Designer / Pass Builder 签名 → 放回 SignedWalletPasses。签名证书勿打进 App。"

    static var signingHelp: String {
        """
        当前没有可用的已签名通行证。

        1. 在 Apple Developer 注册 Pass Type ID（\(PassConfiguration.passTypeIdentifier)）
        2. 用 Pass Designer 出模板，Pass Builder 签名
        3. 将「序列号.pkpass」放入 Documents/SignedWalletPasses/

        也可先「导出未签名 Pass 包」再签名。
        """
    }
}

private struct ExportedPassFile: Identifiable {
    let id = UUID()
    let url: URL
}

private struct SharePassFileSheet: View {
    let url: URL

    var body: some View {
        NavigationStack {
            List {
                ShareLink(item: url) {
                    Label("分享 Pass 包", systemImage: "square.and.arrow.up")
                }
                LabeledContent("文件", value: url.lastPathComponent)
            }
            .navigationTitle("导出")
            .navigationBarTitleDisplayMode(.inline)
            .platformSheetConfirmationToolbar()
        }
        .platformSheet(.confirm)
    }
}
