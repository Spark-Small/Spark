//
//  WalletPassKit.swift
//  坐标系
//
//  兼容入口：实现已拆至 Services/PassKit/。
//  链路：Source → Define/Build → Distribute → Update Web Service → System Wallet。
//

import Foundation

/// 模块文档锚点。具体类型见：
/// - `PassConfiguration` / `PassModels` / `PassSourceFactory`
/// - `PassPackageBuilder` / `PassStore` / `PassDistribution`
/// - `PassUpdateWebService` / `PassKitLoader`
enum WalletPassKitModule {
    static let pipelineSummary = """
    Source(PassSourceFactory) → Record(PassStore) → pass.json(PassPackageBuilder) \
    → Channels(PassDistribution) → Update(PassUpdateWebService) → PKPass(PassKitLoader)
    """
}
