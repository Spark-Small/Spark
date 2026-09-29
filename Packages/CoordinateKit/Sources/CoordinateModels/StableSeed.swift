import Foundation

extension UUID {
    /// 由 UUID 字节派生的稳定非负种子（演示数据 / 占位指标用）
    public var stableSeed: Int {
        withUnsafeBytes(of: uuid) { raw in
            raw.reduce(into: 0) { partial, byte in
                partial = partial &* 31 &+ Int(byte)
            }
        }
    }
}
