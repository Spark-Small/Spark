//
//  ProfileCredentialCards.swift
//  坐标系
//
//  Wallet 风格凭证条 / 陪玩展开票面（活动展开票面见行程 CredentialFace）。
//

import SwiftUI
import CoordinateModels

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

    @Environment(\.platformChromeMeasurements) private var chromeMeasurements

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
            minHeight: fillsCanonicalHeight
                ? PlatformMetrics.walletPassStripBarHeight(
                    navigationBarButtonSide: chromeMeasurements.navigationBarButtonSide
                )
                : nil,
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
                    .platformUltraThinMaterialBackground(in: Capsule())
            }
        }
        .colorScheme(.dark)
        .contentShape(PlatformMetrics.walletPassStripBarShape)
    }
}

// MARK: - Activity strip / card

/// 长条凭证（未展开）。
/// - `titleOnly`：首页堆叠预览，标题下露一行日程；有地点时右下「导航」
/// - 默认：清单密度——标题 + 一行时间 + 一行地点 + 右下「导航」
struct ProfileActivityCredentialStrip: View {
    let activity: Activity
    var voided: Bool = false
    var titleOnly: Bool = false

    @Environment(WalletPassStore.self) private var passStore
    @State private var showNavigationPicker = false

    private var isVoided: Bool {
        voided || passStore.resolvedActivityPass(for: activity, voided: true)?.voided == true
    }

    private var content: WalletPassFaceContent {
        var face = WalletPassFaceFactory.activity(activity, voided: isVoided)
        face.subtitleText = ""
        face.showsDetailButton = false
        let schedule = WalletPassFaceFactory.listScheduleLine(from: activity.date)
        if titleOnly {
            face.subtitleText = schedule
            face.headerLabel = ""
            face.headerValue = ""
            face.locationText = ""
            face.locationLabel = ""
        } else {
            face.headerLabel = schedule
            face.headerValue = ""
            face.locationLabel = ""
        }
        if let pass = passStore.resolvedActivityPass(for: activity, voided: voided) {
            face.voided = pass.voided || voided
        }
        return face
    }

    var body: some View {
        let face = content
        WalletPassCredentialStripChrome(
            content: face,
            photo: activity.coverPhoto,
            onNavigate: face.showsNavigateButton ? { showNavigationPicker = true } : nil,
            fillsCanonicalHeight: titleOnly
        )
        .activityMapNavigationSheet(
            activity: Binding(
                get: { showNavigationPicker ? activity : nil },
                set: { showNavigationPicker = $0 != nil }
            )
        )
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
    @State private var peerContactRoute: PeerContactRoute?

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
        .peerContactDestination(route: $peerContactRoute)
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
        peerContactRoute = app.openPeerContact(
            with: record.companionNickname,
            context: .forBooking(record)
        )
    }
}
