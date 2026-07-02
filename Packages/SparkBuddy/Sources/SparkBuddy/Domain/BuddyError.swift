// Module: SparkBuddy — Typed errors for buddy flows.

import Foundation
import SparkCore

public enum BuddyError: LocalizedError, Sendable, Equatable {
    case invalidListingID
    case invalidPackageID
    case providerNotApproved
    case invalidApplication
    case underlying(AppError)

    public var errorDescription: String? {
        switch self {
        case .invalidListingID:
            String(
                localized: "buddy.error.invalidListing",
                defaultValue: "搭子信息无效",
                comment: "Invalid listing"
            )
        case .invalidPackageID:
            String(
                localized: "buddy.error.invalidPackage",
                defaultValue: "套餐无效",
                comment: "Invalid package"
            )
        case .providerNotApproved:
            String(
                localized: "buddy.error.providerNotApproved",
                defaultValue: "陪玩认证未通过，暂不可查看收益",
                comment: "Provider not approved"
            )
        case .invalidApplication:
            String(
                localized: "buddy.error.invalidApplication",
                defaultValue: "请完善陪玩认证资料",
                comment: "Invalid provider application"
            )
        case .underlying(let appError):
            appError.localizedDescription
        }
    }
}
