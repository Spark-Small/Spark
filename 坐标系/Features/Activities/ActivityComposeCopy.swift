//
//  ActivityComposeCopy.swift
//  坐标系
//
//  发起 / 编辑活动文案（单页快发）。
//

import Foundation

enum ActivityComposeCopy {
    static let createTitle = "发起活动"
    static let editTitle = "编辑活动"
    static let cancel = "取消"
    static let publishAction = "发布"
    static let saveAction = "保存"
    static let confirmPublish = "确认发布"
    static let confirmSave = "确认保存"
    static let discardEditsTitle = "要放弃修改吗？"
    static let discardEditsAction = "放弃修改"
    static let discardCreateTitle = "要放弃这次发起吗？"
    static let discardCreateAction = "不保存并离开"
    static let saveDraftAndLeave = "保存草稿并离开"
    static let keepEditing = "继续编辑"
    static let draftSaved = "草稿已保存"

    static let coverSection = "照片与视频"
    static let addMedia = "添加活动封面或视频"
    static let addMoreMedia = "继续添加"
    static let removeMedia = "移除"
    static let preparingMedia = "正在处理…"
    static let maxMediaCount = 6
    static let coverBadge = "封面"
    static let videoBadge = "视频"

    static let basicsSection = "活动详情"
    static let titlePlaceholder = "活动名称"
    static let categoryLabel = "类型"
    static let locationPlaceholder = "地点"
    static let mapPick = "在地图上选点"
    static let mapPicked = "已选地图位置"
    static let startsLabel = "开始时间"
    static let capacityLabel = "人数"

    static let feeSection = "费用"
    static let feeKindLabel = "收费方式"
    static var feeKindFree: String { ActivityCardStatus.free }
    static let feeKindPaid = "收费"
    static let feeKindAA = "现场 AA"
    static let feeAmountLabel = "人均"
    static let feeAmountPlaceholder = "金额"
    static let feeAAEstimateLabel = "大约人均"
    static let feeAAEstimatePlaceholder = "可选"
    static var feeResolvedFree: String { ActivityCardStatus.free }
    static let feeResolvedPending = "待定"
    static let feeResolvedVenueAA = "AA · 店内自费"
    static let feeResolvedVenueAAPrefix = "AA · 约"
    static let feeResolvedPaidSuffix = "/人"
    static let keyboardDone = "完成"

    static let aboutSection = "活动介绍"
    static let summaryPlaceholder = "为什么值得来？"

    // MARK: - 发布预览

    /// 发起人尚未填写的详情分区：预览用诚实空态，不用类别模板冒充。
    static let pendingFillTitle = "待补充"
    static let pendingFillSummary = "待补充"
    static func pendingFillHint(categoryTitle: String) -> String {
        "发布后将先展示「\(categoryTitle)」类型参考安排，可在活动管理中随时完善"
    }

    /// 预览顶栏：未完善分区行动清单（Settings 式建议，不拦发布）。
    static let pendingChecklistHeader = "建议完善"
    static let pendingChecklistFooter = "未完善项会先按活动类型展示参考安排，并标明「类型参考」。"
    static func pendingChecklistRowTitle(sectionTitle: String) -> String {
        "待补充 · \(sectionTitle)"
    }
    static let pendingChecklistPaidEmphasis = "收费活动建议补全费用说明与退改规则"

    static let publishBlockedPrefix = "还需填写："
    static let blockerTitle = "活动名称"
    static let blockerLocation = "地点"
    static let blockerSummary = "活动介绍"
    static let blockerMedia = "等待媒体处理完成"
    static let blockerFeeAmount = "人均金额"
}
