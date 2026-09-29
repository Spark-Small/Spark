import Foundation

public enum TransferLifecycle {
    /// 本地演示：待收款有效期（正式版由服务端 TTL 下发）
    public static let pendingTTL: TimeInterval = 24 * 3600
}
