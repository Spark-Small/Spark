// Module: SparkActivity — Read-only preview sheet (toolbar「预览」).

import SparkDesignSystem
import SwiftUI

struct ActivityCreatePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CreateActivityViewModel

    @State private var previewLayout: ActivityCreatePreviewLayout = .detail

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SparkLayoutMetrics.sectionVerticalPadding) {
                    Text(ActivityCreateBrandCopy.slogan)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker(
                        String(
                            localized: "activity.create.preview.layout",
                            defaultValue: "别人看到的样式",
                            comment: "Preview layout picker"
                        ),
                        selection: $previewLayout
                    ) {
                        Text(
                            String(
                                localized: "activity.create.preview.layout.detail",
                                defaultValue: "活动详情",
                                comment: "Detail preview"
                            )
                        )
                        .tag(ActivityCreatePreviewLayout.detail)
                        Text(
                            String(
                                localized: "activity.create.preview.layout.list",
                                defaultValue: "活动列表",
                                comment: "List card preview"
                            )
                        )
                        .tag(ActivityCreatePreviewLayout.listCard)
                    }
                    .pickerStyle(.segmented)

                    ActivityCreateDetailPreview(
                        draft: viewModel.draft,
                        coverPreviewImage: viewModel.coverPreviewImage,
                        coverIsVideo: viewModel.coverIsVideo,
                        layout: previewLayout
                    )
                }
                .padding(.horizontal, previewLayout == .detail ? 0 : SparkLayoutMetrics.standardHorizontalPadding)
                .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
            }
            .background(.background)
            .navigationTitle(
                String(
                    localized: "activity.create.preview.title",
                    defaultValue: "活动预览",
                    comment: "Preview sheet title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.done", defaultValue: "完成", comment: "Done")) {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                previewFooter
            }
        }
        .presentationDetents([.large])
    }

    private var previewFooter: some View {
        VStack(spacing: 8) {
            Text(
                String(
                    localized: "activity.create.preview.footer",
                    defaultValue: "确认无误后，关闭预览并点右上角「发布」。",
                    comment: "Preview sheet footer"
                )
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        .background(.bar)
    }
}

#Preview {
    @Previewable @State var viewModel = CreateActivityViewModel(repository: MockActivityFeedRepository())
    ActivityCreatePreviewSheet(viewModel: viewModel)
}
