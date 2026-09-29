//
//  PassDemoBootstrap.swift
//  坐标系
//
//  DEBUG only：「剧本杀：情感本」演示参加 → 已支付 → 签发 Pass。
//  Release 不得注入，避免污染真实用户行程与订单（审核 2.3.1）。
//

#if DEBUG
import Foundation
import CoordinateModels

@MainActor
enum PassDemoBootstrap {
  private static let installKey = "pass.demo.scriptMurderJourney.installed"

  /// App 启动后调用：保证「我的行程」可打开，且 Pass 记录与未签名包就绪。
  static func installScriptMurderJourneyDemoIfNeeded(app: AppModel) {
    app.activities.ensureDemoScriptMurderJourneyJoined()

    guard let activity = app.activities.activity(id: SampleData.demoJourneyActivityID) else {
      return
    }

    let order = ActivityPaymentStore.installDemoPaidOrder(
      activity: activity,
      orderID: SampleData.demoJourneyOrderID,
      passStore: app.walletPassStore
    )

    guard let pass = app.walletPassStore.pass(relatedID: order.id) else { return }

    installSignedPackageIfAvailable(for: pass)

    if !UserDefaults.standard.bool(forKey: installKey) {
      _ = try? PassDistribution.writeUnsignedToDocuments(for: pass)
      UserDefaults.standard.set(true, forKey: installKey)
    }
  }

  /// 优先使用 App Bundle 内 `DemoWalletPasses/{serialNumber}.pkpass`（须已签名）。
  private static func installSignedPackageIfAvailable(for pass: PassRecord) {
    let destination = PassDistribution.signedPassURL(for: pass)
    guard !PassDistribution.hasSignedPackage(for: pass) else { return }

    PassConfiguration.ensureDirectories()

    if let bundled = Bundle.main.url(
      forResource: pass.serialNumber,
      withExtension: "pkpass",
      subdirectory: "DemoWalletPasses"
    ) {
      try? FileManager.default.copyItem(at: bundled, to: destination)
      return
    }

    if let bundled = Bundle.main.url(
      forResource: "script-murder-journey-demo",
      withExtension: "pkpass",
      subdirectory: "DemoWalletPasses"
    ) {
      try? FileManager.default.copyItem(at: bundled, to: destination)
    }
  }
}
#endif
