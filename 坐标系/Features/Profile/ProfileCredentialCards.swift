//
//  ProfileCredentialCards.swift
//  坐标系
//
//  「我的」活动 / 陪玩 / 发布预览：统一 Wallet 风格票面（Design/WalletPassFace）。
//

import SwiftUI

// MARK: - Shared strip chrome

/// 长条凭证共用壳：顶栏 + 底栏叠在封面色带上（活动 / 陪玩同一套）。
struct WalletPassCredentialStripChrome: View {
    let content: WalletPassFaceContent
    var photo: CommunityPhotoRef? = nil
    var onNavigate: (() -> Void)? = nil
    var onMessage: (() -> Void)? = nil
    var onOpenDetail: (() -> Void)? = nil
    /// 文案精简时仍占满标准条高（堆叠预览与清单同尺寸）
    var fillsCanonicalHeight: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: WalletPassChromePadding.stackSpacing) {
            WalletPassFaceHeaderRow(content: content)
            if !content.locationText.isEmpty
                || content.showsNavigateButton
                || content.showsMessageButton
                || content.showsDetailButton {
                WalletPassFaceFooterRow(
                    content: content,
                    onNavigate: onNavigate,
                    onMessage: onMessage,
                    onOpenDetail: onOpenDetail
                )
            }
        }
        .padding(.horizontal, WalletPassChromePadding.horizontal)
        .padding(.vertical, WalletPassChromePadding.vertical)
        .frame(
            maxWidth: .infinity,
            minHeight: fillsCanonicalHeight ? PlatformMetrics.walletPassStripBarHeight : nil,
            alignment: .topLeading
        )
        .background {
            ZStack {
                content.stripColor
                if let photo {
                    CommunityRemotePhoto(ref: photo)
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.42),
                            Color.black.opacity(0.58)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    Color.black.opacity(0.12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipShape(PlatformMetrics.walletPassStripBarShape)
        .compositingGroup()
        .overlay {
            PlatformMetrics.walletPassStripBarShape
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .overlay {
            if content.voided {
                Color.black.opacity(0.45)
                Text("已作废")
                    .font(WalletPassTypography.headerValue)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, WalletPassChromePadding.horizontal)
                    .padding(.vertical, WalletPassChromePadding.vertical)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .colorScheme(.dark)
        .contentShape(PlatformMetrics.walletPassStripBarShape)
    }
}

// MARK: - Activity strip / card

/// 长条凭证（未展开）。
/// - `titleOnly`：首页堆叠预览，只露标题
/// - 默认：清单密度——标题 + 一行时间 + 一行地点
struct ProfileActivityCredentialStrip: View {
    let activity: Activity
    var voided: Bool = false
    var titleOnly: Bool = false

    @Environment(WalletPassStore.self) private var passStore

    private var isVoided: Bool {
        voided || passStore.resolvedActivityPass(for: activity, voided: true)?.voided == true
    }

    private var content: WalletPassFaceContent {
        var face = WalletPassFaceFactory.activity(activity, voided: isVoided)
        face.subtitleText = ""
        face.showsNavigateButton = false
        face.showsDetailButton = false
        if titleOnly {
            face.headerLabel = ""
            face.headerValue = ""
            face.locationText = ""
            face.locationLabel = ""
        } else {
            face.headerLabel = WalletPassFaceFactory.listScheduleLine(from: activity.date)
            face.headerValue = ""
            face.locationLabel = ""
        }
        if let pass = passStore.resolvedActivityPass(for: activity, voided: voided) {
            face.voided = pass.voided || voided
        }
        return face
    }

    var body: some View {
        WalletPassCredentialStripChrome(
            content: content,
            photo: activity.coverPhoto,
            fillsCanonicalHeight: titleOnly
        )
    }
}

/// 活动票面（展开态）。详情由外层 `navigationDestination` 承接，勿在 Form/List 内注册。
struct ProfileActivityCredentialCard: View {
    let activity: Activity
    var voided: Bool = false
    /// false：安排/细则由页面 Form 承接
    var embedsNotes: Bool = true
    /// false：标题/人数/日程由页面 List 承接
    var embedsHeader: Bool = true
    var onOpenDetail: (() -> Void)? = nil

    @Environment(WalletPassStore.self) private var passStore
    @State private var showNavigationPicker = false

    var body: some View {
        WalletPassFace(
            content: faceContent,
            photo: activity.coverPhoto,
            embedsNotes: embedsNotes,
            embedsHeader: embedsHeader,
            onNavigate: faceContent.showsNavigateButton ? { showNavigationPicker = true } : nil,
            onOpenDetail: faceContent.showsDetailButton ? onOpenDetail : nil
        )
        .activityMapNavigationDialog(
            activity: Binding(
                get: { showNavigationPicker ? activity : nil },
                set: { showNavigationPicker = $0 != nil }
            )
        )
    }

    private var faceContent: WalletPassFaceContent {
        var content = WalletPassFaceFactory.activity(activity, voided: voided)
        if let pass = passStore.resolvedActivityPass(for: activity, voided: voided) {
            content.voided = pass.voided || voided
            let message = pass.barcodeMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            if !message.isEmpty {
                content.barcodeMessage = message
            }
        }
        return content
    }
}

// MARK: - Booking strip / card

/// 陪玩长条凭证（未展开）：与活动长条同一套 chrome；右下聊天；点按进入展开票面。
struct ProfileBookingCredentialStrip: View {
    let record: BuddyBookingRecord
    var photo: CommunityPhotoRef? = nil
    var statusOverride: String? = nil
    var voided: Bool = false
    /// 由页面级承接聊天（避免嵌在外层 Button 内抢手势时也可直连 AppModel）
    var onRequestMessage: (() -> Void)? = nil

    @Environment(AppModel.self) private var app
    @Environment(WalletPassStore.self) private var passStore

    private var isVoided: Bool {
        voided || statusOverride == "已作废"
            || passStore.resolvedBookingPass(for: record.id, voided: true)?.voided == true
    }

    private var content: WalletPassFaceContent {
        var face = WalletPassFaceFactory.booking(
            record,
            statusOverride: statusOverride,
            voided: isVoided
        )
        face.showsDetailButton = false
        if let pass = passStore.resolvedBookingPass(for: record.id, voided: voided || isVoided) {
            face.voided = pass.voided || isVoided
        }
        return face
    }

    var body: some View {
        let face = content
        WalletPassCredentialStripChrome(
            content: face,
            photo: photo,
            onMessage: face.showsMessageButton ? { requestMessage() } : nil
        )
    }

    private func requestMessage() {
        if let onRequestMessage {
            onRequestMessage()
            return
        }
        if let convo = app.startDirectChat(
            with: record.companionNickname,
            greeting: "你好，想确认一下预约安排，最近方便吗？"
        ) {
            app.openMessages(conversationID: convo.id)
        }
    }
}

/// 陪玩预约票面（展开态）
struct ProfileBookingCredentialCard: View {
    let record: BuddyBookingRecord
    let photo: CommunityPhotoRef?
    var statusOverride: String? = nil
    var voided: Bool = false
    /// false：细则由页面 Form 承接
    var embedsNotes: Bool = true
    /// false：昵称/状态/日程由页面 Form 承接
    var embedsHeader: Bool = true
    var onOpenDetail: (() -> Void)? = nil

    @Environment(AppModel.self) private var app
    @Environment(WalletPassStore.self) private var passStore

    private var isVoided: Bool {
        voided || statusOverride == "已作废"
    }

    var body: some View {
        WalletPassFace(
            content: faceContent,
            photo: photo,
            embedsNotes: embedsNotes,
            embedsHeader: embedsHeader,
            onMessage: faceContent.showsMessageButton ? { openChat() } : nil,
            onOpenDetail: faceContent.showsDetailButton ? onOpenDetail : nil
        )
    }

    private var faceContent: WalletPassFaceContent {
        var content = WalletPassFaceFactory.booking(
            record,
            statusOverride: statusOverride,
            voided: isVoided
        )
        if let pass = passStore.resolvedBookingPass(for: record.id, voided: isVoided) {
            content.voided = pass.voided || isVoided
            let message = pass.barcodeMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            if !message.isEmpty {
                content.barcodeMessage = message
            }
        }
        return content
    }

    private func openChat() {
        if let convo = app.startDirectChat(
            with: record.companionNickname,
            greeting: "你好，想确认一下预约安排，最近方便吗？"
        ) {
            app.openMessages(conversationID: convo.id)
        }
    }
}

// MARK: - Published

/// 作品 / 发起卡片（App 内容卡外观，非可核验通行权）。
struct ProfilePublishedCredentialCard: View {
    enum Kind {
        case post
        case hostedActivity

        var passKind: WalletPassPublishedKind {
            switch self {
            case .post: .post
            case .hostedActivity: .hostedActivity
            }
        }
    }

    let kind: Kind
    let title: String
    let metaLine: String
    let photo: CommunityPhotoRef?
    var idHint: String = UUID().uuidString

    var body: some View {
        WalletPassFace(
            content: WalletPassFaceFactory.published(
                kind: kind.passKind,
                title: title,
                metaLine: metaLine,
                idHint: idHint
            ),
            photo: photo
        )
    }
}
