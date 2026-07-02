// Module: SparkActivity — App Store–style join confirmation from discover feed.

import SparkDesignSystem
import SwiftUI

struct ActivityBrowseJoinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ActivityBrowseJoinViewModel
    let isAuthenticated: Bool
    let onSignInRequired: () -> Void
    let onViewDetail: () -> Void
    let onJoined: (ActivityDetail) async -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SparkLayoutMetrics.sectionVerticalPadding) {
                    summaryCard
                    joinFootnote
                }
                .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
                .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
            }
            .background(.background)
            .navigationTitle(
                String(
                    localized: "activity.join.sheet.title",
                    defaultValue: "加入活动",
                    comment: "Discover join confirmation sheet"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(
                        String(localized: "action.close", defaultValue: "关闭", comment: "Close")
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewDetailAction) {
                        Text(
                            String(
                                localized: "activity.join.sheet.viewDetail",
                                defaultValue: "查看详情",
                                comment: "Open detail from join sheet"
                            )
                        )
                    }
                    .disabled(viewModel.isSubmitting)
                    .accessibilityHint(
                        String(
                            localized: "activity.row.openDetail.hint",
                            defaultValue: "查看活动详情",
                            comment: "Activity row opens detail"
                        )
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
            .alert(
                String(
                    localized: "activity.join.error.title",
                    defaultValue: "无法加入",
                    comment: "Join error alert"
                ),
                isPresented: showsErrorAlert
            ) {
                Button(String(localized: "action.ok", defaultValue: "好", comment: "OK"), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                coverThumbnail

                VStack(alignment: .leading, spacing: 6) {
                    if !viewModel.summary.category.isEmpty {
                        Text(viewModel.summary.category.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text(viewModel.summary.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                if let scheduleLine = viewModel.summary.scheduleLine {
                    ActivityBrowseSummaryMetadataRow(
                        systemImage: "calendar",
                        text: scheduleLine,
                        emphasis: .primary
                    )
                }
                if let locationLine = viewModel.summary.locationLine {
                    ActivityBrowseSummaryMetadataRow(
                        systemImage: "mappin.and.ellipse",
                        text: locationLine,
                        emphasis: .primary
                    )
                }
                if let hostLine = viewModel.summary.hostLine {
                    ActivityBrowseSummaryMetadataRow(
                        systemImage: "person.crop.circle",
                        text: hostLine,
                        emphasis: .primary
                    )
                }
                ActivityBrowseSummaryMetadataRow(
                    systemImage: "person.2",
                    text: viewModel.summary.attendeeLine,
                    emphasis: .primary
                )
            }

            if let teaserLine = viewModel.summary.teaserLine {
                Text(teaserLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(SparkLayoutMetrics.standardHorizontalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var coverThumbnail: some View {
        SparkCachedRemoteImage(
            url: ActivityCoverImage.url(
                activityID: viewModel.item.id,
                coverURL: viewModel.item.coverURL,
                coverPosterURL: viewModel.item.coverPosterURL,
                coverIsVideo: viewModel.item.coverIsVideo
            ),
            maxPixelSize: 240,
            content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            },
            placeholder: {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
            }
        )
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var joinFootnote: some View {
        Text(
            String(
                localized: "activity.join.sheet.footnote",
                defaultValue: "加入后可进入活动群聊并接收开始提醒。",
                comment: "Join sheet footnote"
            )
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var actionBar: some View {
        Button(action: primaryAction) {
            Group {
                if viewModel.isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(primaryButtonTitle)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isSubmitting)
        .accessibilityHint(primaryAccessibilityHint)
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        .background(.bar)
    }

    private var primaryButtonTitle: String {
        if isAuthenticated {
            return String(
                localized: "activity.join.sheet.confirm",
                defaultValue: "确认加入",
                comment: "Confirm join from discover sheet"
            )
        }
        return String(
            localized: "activity.join.sheet.signInAndJoin",
            defaultValue: "登录并加入",
            comment: "Sign in then join from discover sheet"
        )
    }

    private var primaryAccessibilityHint: String {
        if isAuthenticated {
            return String(
                localized: "activity.join.sheet.confirm.hint",
                defaultValue: "确认后将报名并加入活动群聊",
                comment: "Confirm join accessibility hint"
            )
        }
        return String(
            localized: "activity.join.sheet.signIn.hint",
            defaultValue: "登录后返回并完成报名",
            comment: "Sign in to join accessibility hint"
        )
    }

    private var showsErrorAlert: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
    }

    private func primaryAction() {
        if !isAuthenticated {
            onSignInRequired()
            dismiss()
            return
        }

        Task {
            do {
                let detail = try await viewModel.confirmJoin()
                await onJoined(detail)
                dismiss()
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }
    }

    private func viewDetailAction() {
        onViewDetail()
        dismiss()
    }
}

// MARK: - Previews

#Preview("Join sheet") {
    if let detail = MockActivityCatalog.detail(id: "act_1") {
        let item = detail.asBrowseListItem()
        ActivityBrowseJoinSheet(
            viewModel: ActivityBrowseJoinViewModel(
                item: item,
                updateRSVP: UpdateActivityRSVPUseCase(repository: MockActivityFeedRepository())
            ),
            isAuthenticated: true,
            onSignInRequired: {},
            onViewDetail: {},
            onJoined: { _ in }
        )
    }
}

#Preview("Join sheet — guest") {
    SparkPreviewSupport.darkMode {
        if let detail = MockActivityCatalog.detail(id: "act_1") {
            ActivityBrowseJoinSheet(
                viewModel: ActivityBrowseJoinViewModel(
                    item: detail.asBrowseListItem(),
                    updateRSVP: UpdateActivityRSVPUseCase(repository: MockActivityFeedRepository())
                ),
                isAuthenticated: false,
                onSignInRequired: {},
                onViewDetail: {},
                onJoined: { _ in }
            )
        }
    }
}

#Preview("Join sheet — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        if let detail = MockActivityCatalog.detail(id: "act_1") {
            ActivityBrowseJoinSheet(
                viewModel: ActivityBrowseJoinViewModel(
                    item: detail.asBrowseListItem(),
                    updateRSVP: UpdateActivityRSVPUseCase(repository: MockActivityFeedRepository())
                ),
                isAuthenticated: true,
                onSignInRequired: {},
                onViewDetail: {},
                onJoined: { _ in }
            )
        }
    }
}
