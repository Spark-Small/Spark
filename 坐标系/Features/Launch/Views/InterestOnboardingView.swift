//
//  InterestOnboardingView.swift
//  坐标系
//
//  登录成功后的喜好选择（与欢迎意图半屏分离；硬门槛，无跳过）。
//  主目标：采集兴趣信号，进入活动推荐主页。
//

import SwiftUI

struct InterestOnboardingView: View {
    var onComplete: ([String]) -> Void

    @State private var selected: Set<String>
    @State private var statusPulse = 0
    @State private var didTrackPresent = false

    init(
        initialInterests: [String] = [],
        onComplete: @escaping ([String]) -> Void
    ) {
        self.onComplete = onComplete
        let draft = InterestSelectionDraftStore.load() ?? []
        let seed = draft.isEmpty ? initialInterests : draft
        _selected = State(initialValue: Set(seed))
    }

    private var canContinue: Bool {
        InterestSelectionLimits.meetsMinimum(selected.count)
    }

    private var statusText: String {
        InterestSelectionLimits.progressText(count: selected.count)
    }

    var body: some View {
        NavigationStack {
            InterestTaxonomyFormEditor(
                selected: $selected,
                showsSelectionProgress: false,
                onLimitReached: handleLimitReached
            )
            .safeAreaInset(edge: .bottom) {
                bottomChrome
            }
            .onAppear {
                guard !didTrackPresent else { return }
                didTrackPresent = true
                InterestAnalytics.onboardingPresented(draftCount: selected.count)
            }
            .onChange(of: selected) { _, newValue in
                InterestSelectionDraftStore.save(Array(newValue))
            }
        }
    }

    private var bottomChrome: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
            Text(statusText)
                .font(.footnote.weight(
                    InterestSelectionLimits.isAtMaximum(selected.count) || !canContinue
                        ? .semibold
                        : .regular
                ))
                .foregroundStyle(
                    canContinue && !InterestSelectionLimits.isAtMaximum(selected.count)
                        ? Color.secondary
                        : Color.primary
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(statusPulse)
                .accessibilityLabel(statusText)

            Button(InterestTaxonomyCopy.onboardingContinue) {
                guard canContinue else { return }
                let interests = selected.sorted()
                InterestAnalytics.onboardingCompleted(count: interests.count)
                InterestSelectionDraftStore.clear()
                onComplete(interests)
            }
            .activityPrimaryCTA(controlSize: .large)
            .buttonSizing(.flexible)
            .disabled(!canContinue)
            .accessibilityHint(
                canContinue
                    ? InterestTaxonomyCopy.onboardingContinueHint
                    : statusText
            )
        }
        .activityDetailBottomBarChrome()
        .padding(.bottom, PlatformMetrics.sectionSpacing)
    }

    private func handleLimitReached() {
        InterestAnalytics.selectionLimitReached(count: selected.count)
        statusPulse += 1
    }
}

#Preview {
    InterestOnboardingView { _ in }
}
