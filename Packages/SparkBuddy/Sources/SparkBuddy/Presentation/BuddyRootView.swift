// Module: SparkBuddy — Tab root: companion browse.

import SparkDesignSystem
import SwiftUI

public struct BuddyRootView: View {
    @Binding private var pendingBuddyListingID: String?
    @State var viewModel: BuddyViewModel
    @State private var pushedListingID: String?
    @State var showBrowseOptions = false

    private let coordinator: BuddyCoordinator
    private let onOpenMessages: ((String) -> Void)?
    private let fetchRecommendedActivity: (() async -> (id: String, title: String)?)?
    private let onOpenActivity: ((String) -> Void)?

    public init(
        coordinator: BuddyCoordinator,
        pendingBuddyListingID: Binding<String?> = .constant(nil),
        onOpenMessages: ((String) -> Void)? = nil,
        fetchRecommendedActivity: (() async -> (id: String, title: String)?)? = nil,
        onOpenActivity: ((String) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        _pendingBuddyListingID = pendingBuddyListingID
        _viewModel = State(initialValue: coordinator.makeBrowseViewModel())
        self.onOpenMessages = onOpenMessages
        self.fetchRecommendedActivity = fetchRecommendedActivity
        self.onOpenActivity = onOpenActivity
    }

    public init(
        viewModel: BuddyViewModel,
        coordinator: BuddyCoordinator,
        pendingBuddyListingID: Binding<String?> = .constant(nil),
        onOpenMessages: ((String) -> Void)? = nil,
        fetchRecommendedActivity: (() async -> (id: String, title: String)?)? = nil,
        onOpenActivity: ((String) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        _pendingBuddyListingID = pendingBuddyListingID
        _viewModel = State(initialValue: viewModel)
        self.onOpenMessages = onOpenMessages
        self.fetchRecommendedActivity = fetchRecommendedActivity
        self.onOpenActivity = onOpenActivity
    }

    public var body: some View {
        NavigationStack {
            SparkScreenContainer(
                navigationTitle: String(
                    localized: "screen.buddy",
                    defaultValue: "搭子",
                    comment: "Buddy tab title"
                ),
                titleDisplayMode: .inline,
                embedding: .none
            ) {
                listContent
                    .navigationDestination(item: $pushedListingID) { listingID in
                        BuddyDetailView(
                            viewModel: coordinator.makeDetailViewModel(listingID: listingID),
                            onOpenMessages: onOpenMessages,
                            fetchRecommendedActivity: fetchRecommendedActivity,
                            onOpenActivity: onOpenActivity
                        )
                        .toolbar(.hidden, for: .tabBar)
                    }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    buddyBrowseOptionsButton
                }
            }
            .sparkPhoneStyleNavigationBar()
        }
        .sheet(isPresented: $showBrowseOptions) {
            BuddyBrowseOptionsSheet(viewModel: viewModel)
        }
        .task { await viewModel.loadIfNeeded() }
        .onChange(of: pendingBuddyListingID) { _, listingID in
            guard let listingID else { return }
            openPendingListing(listingID: listingID)
        }
        .onAppear {
            if let listingID = pendingBuddyListingID {
                openPendingListing(listingID: listingID)
            }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        @Bindable var vm = viewModel
        buddyList(viewModel: vm)
            .sparkTabTopAccessory(isEnabled: true) {
                BuddyBrowseFilterBar(viewModel: vm)
            }
    }

    @ViewBuilder
    private func buddyList(viewModel: BuddyViewModel) -> some View {
        List {
            switch viewModel.loadState {
            case .idle, .loading:
                buddyLoadingRow
            case .empty:
                buddyEmptyState
                    .sparkFlatTabListRow()
            case .failure(let message):
                buddyErrorRow(message: message)
            case .loaded:
                ForEach(viewModel.items) { listing in
                    Button {
                        pushedListingID = listing.id
                    } label: {
                        BuddyListRow(listing: listing, showsChevron: true)
                    }
                    .buttonStyle(.sparkPressable)
                    .sparkFlatTabListRow()
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(currentItemID: listing.id) }
                    }
                }
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, SparkLayoutMetrics.inboxRowVerticalPadding)
                    .sparkFlatTabListRow()
                }
            }
        }
        .sparkFlatTabListStyle()
        .refreshable {
            await viewModel.reload()
        }
    }

    private func openPendingListing(listingID: String) {
        pushedListingID = listingID
        pendingBuddyListingID = nil
    }

    private var buddyLoadingRow: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .padding(.vertical, SparkLayoutMetrics.inboxRowVerticalPadding)
        .sparkFlatTabListRow()
        .sparkLoadingAccessibilityLabel(
            String(
                localized: "buddy.loading.a11y",
                defaultValue: "正在加载搭子",
                comment: "Buddy list loading"
            )
        )
    }

    private var buddyEmptyState: some View {
        ContentUnavailableView {
            Label(
                String(
                    localized: "buddy.empty.title",
                    defaultValue: "暂无陪玩",
                    comment: "Buddy empty title"
                ),
                systemImage: "line.3.horizontal.decrease.circle"
            )
        } description: {
            Text(
                String(
                    localized: "buddy.empty.subtitle",
                    defaultValue: "试试其他分类或筛选条件，或稍后再来。",
                    comment: "Buddy empty hint"
                )
            )
        } actions: {
            if viewModel.browseOptions.hasActiveSecondaryFilters {
                Button {
                    viewModel.resetBrowseOptions()
                } label: {
                    Text(
                        String(
                            localized: "buddy.options.reset",
                            defaultValue: "恢复默认筛选",
                            comment: "Reset browse options"
                        )
                    )
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .sparkContentUnavailableCanvas()
    }

    private func buddyErrorRow(message: String) -> some View {
        SparkRetryUnavailableView(
            title: String(
                localized: "buddy.error.title",
                defaultValue: "无法加载",
                comment: "Buddy list error"
            ),
            description: message
        ) {
            Task { await viewModel.reload() }
        }
        .sparkFlatTabListRow()
    }
}

#Preview("Buddy tab") {
    BuddyRootView(coordinator: BuddyCoordinator(repository: MockBuddyRepository()))
}

#Preview("Buddy tab — dark") {
    SparkPreviewSupport.darkMode {
        BuddyRootView(coordinator: BuddyCoordinator(repository: MockBuddyRepository()))
    }
}

#Preview("Buddy tab — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        BuddyRootView(coordinator: BuddyCoordinator(repository: MockBuddyRepository()))
    }
}
