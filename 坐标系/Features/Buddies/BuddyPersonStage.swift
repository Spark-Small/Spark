//
//  BuddyPersonStage.swift
//  坐标系
//
//  舞台主角是人像大图（可左右翻多图）；底栏叠字 + glass CTA，节奏对齐精选 Hero。
//

import SwiftUI

struct BuddyPersonStage<Card: View>: View {
    let items: [DiscoverBuddyItem]
    @Binding var focusedID: DiscoverBuddyItem.ID?
    @ViewBuilder var card: (_ item: DiscoverBuddyItem) -> Card

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var focusedItem: DiscoverBuddyItem? {
        guard let focusedID else { return items.first }
        return items.first { $0.id == focusedID } ?? items.first
    }

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // 主视觉：照片 / 多图翻页（视频位预留同层）
                backgroundMedia(size: geo.size)
                    .frame(width: geo.size.width, height: geo.size.height)

                // 底栏信息区（与精选 Hero 叠字同系）
                foregroundInfoRail
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .padding(.bottom, PlatformMetrics.contentInset)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .modifier(BuddyPersonStageAspectModifier(prefersStacked: prefersStacked))
        .frame(maxWidth: .infinity)
        .clipped()
        .onAppear { syncFocusIfNeeded() }
        .onChange(of: items.map(\.id)) { _, _ in
            syncFocusIfNeeded(preferExisting: true)
        }
    }

    // MARK: - Hero media（看人看图的主区域）

    @ViewBuilder
    private func backgroundMedia(size: CGSize) -> some View {
        ZStack {
            PlatformSurface.groupedPage

            if let item = focusedItem {
                // 主视觉：多图可左右翻。视频日后同层替换。
                HeroPersonCover(
                    name: item.profile.nickname,
                    photos: item.profile.photoRefs,
                    allowsPaging: item.profile.photoRefs.count > 1
                )
                .frame(width: size.width, height: size.height)
                .clipped()
                .scaleEffect(
                    reduceMotion ? 1 : PlatformMetrics.personStageBackgroundScale
                )
                .id(item.id)
                .transition(backgroundTransition)
                .accessibilityLabel("\(item.profile.nickname)的照片")
                .accessibilityHint(
                    item.profile.photoRefs.count > 1
                        ? "左右滑动查看更多照片"
                        : "在下方信息区打开资料"
                )
            }

            // 底栏可读性：轻 scrim，中间大图保持清晰
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: size.height * 0.22)
                .allowsHitTesting(false)
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: focusedID)
    }

    private var backgroundTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 1.02)),
                removal: .opacity
            )
    }

    // MARK: - Bottom info rail（精选式叠字底栏）

    private var foregroundInfoRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: PlatformMetrics.railCardSpacing) {
                ForEach(items) { item in
                    card(item)
                        .id(item.id)
                        // 系统页边之后的可视全宽（由 contentMargins = contentInset 决定）
                        .containerRelativeFrame(.horizontal) { length, _ in length }
                        .buddyStageCardScrollTransition()
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $focusedID)
        .contentMargins(.horizontal, PlatformMetrics.contentInset, for: .scrollContent)
    }

    private func syncFocusIfNeeded(preferExisting: Bool = false) {
        guard !items.isEmpty else {
            focusedID = nil
            return
        }
        if preferExisting,
           let focusedID,
           items.contains(where: { $0.id == focusedID }) {
            return
        }
        focusedID = items.first?.id
    }
}

private struct BuddyPersonStageAspectModifier: ViewModifier {
    var prefersStacked: Bool

    func body(content: Content) -> some View {
        if prefersStacked {
            content
        } else {
            content.aspectRatio(PlatformMetrics.personStageAspectRatio, contentMode: .fit)
        }
    }
}

private extension View {
    func buddyStageCardScrollTransition() -> some View {
        modifier(BuddyStageCardScrollTransitionModifier())
    }
}

private struct BuddyStageCardScrollTransitionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.scrollTransition(.animated(.smooth)) { view, phase in
                view
                    .scaleEffect(phase.isIdentity ? 1 : 0.96)
                    .opacity(phase.isIdentity ? 1 : 0.8)
            }
        }
    }
}

#Preview("舞台 · 人像为主") {
    @Previewable @State var focused: DiscoverBuddyItem.ID?
    let items = SampleData.circleBuddies.prefix(4).map(DiscoverBuddyItem.free)

    BuddyPersonStage(items: Array(items), focusedID: $focused) { item in
        BuddyDiscoverCard(
            item: item,
            onGreet: {},
            onInvite: {}
        )
    }
    .ignoresSafeArea(edges: .top)
}
