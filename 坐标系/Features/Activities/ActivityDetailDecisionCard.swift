//
//  ActivityDetailDecisionCard.swift
//  坐标系
//
//  活动详情：首屏决策卡与主办信任行。
//

import SwiftUI
import CoordinateDomain
import CoordinateModels

/// 首屏决策卡：费用 / 时间 / 地点 / 名额 / 参加进度
struct ActivityDetailDecisionCard: View {
    @Environment(LocationService.self) private var location
    let activity: Activity
    var viewerWaitlisted: Bool
    /// 已参加或本人发起才露出日历提醒。
    var canAddCalendarReminder: Bool
    var hostNote: String? = nil
    /// 已报名好友名单；有值时在决策卡参加行内展示社交背书。
    var matchedFriends: [String] = []
    var experienceFeedbackTags: [(tag: String, count: Int)] = []
    var onPeople: () -> Void

    @State private var calendarMessage: String?
    @State private var showCalendarAccessAlert = false
    @State private var showNavigationPicker = false
    @State private var showsMapPreview = false
    @State private var isOnCalendar = false

    var body: some View {
        VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text(activity.fee)
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                    Spacer()
                    Text(spotsLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(spotsColor)
                        .monospacedDigit()
                }

                VStack(alignment: .leading) {
                    timeRow
                    locationModule
                }

                if let calendarMessage {
                    Text(calendarMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let hostNote, !hostNote.isEmpty {
                    Text(hostNote)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !experienceFeedbackTags.isEmpty {
                    VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                        Text(ActivityDetailCopy.experienceFeedbackTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(ActivityDetailCopy.experienceFeedbackLine(tags: experienceFeedbackTags))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(ActivityDetailCopy.experienceFeedbackTitle)，\(ActivityDetailCopy.experienceFeedbackLine(tags: experienceFeedbackTags))"
                    )
                }

                Divider()

                Button(action: onPeople) {
                    HStack(alignment: .center) {
                        ActivityParticipantAvatars(
                            names: matchedFriends.isEmpty
                                ? activity.displayParticipants
                                : matchedFriends
                        )
                        VStack(alignment: .leading) {
                            if let friendsLine = ActivityDetailCopy.friendsGoingLine(friends: matchedFriends) {
                                Text(friendsLine)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                            Text(ActivityDetailCopy.socialProof(
                                joined: activity.joined,
                                capacity: activity.capacity,
                                viewerWaitlisted: viewerWaitlisted
                            ))
                            .font(matchedFriends.isEmpty ? .subheadline.weight(.medium) : .subheadline)
                            .foregroundStyle(matchedFriends.isEmpty ? .primary : .secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(ActivityDetailCopy.peopleRowAccessibility)
                .accessibilityHint("查看参加成员")
        }
        .sheet(isPresented: $showNavigationPicker) {
            ActivityNavigationPickerSheet(activity: activity)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .activityCalendarAccessAlert(isPresented: $showCalendarAccessAlert)
        .onAppear {
            isOnCalendar = ActivityCalendar.isScheduled(activityID: activity.id)
        }
        .onChange(of: activity.id) { _, _ in
            isOnCalendar = ActivityCalendar.isScheduled(activityID: activity.id)
            calendarMessage = nil
        }
    }

    @MainActor
    private func toggleCalendarReminder() async {
        switch await ActivityCalendar.toggle(activity, withReminders: true) {
        case .added(let withReminders):
            isOnCalendar = true
            calendarMessage = ActivityCalendar.successMessage(withReminders: withReminders)
        case .removed:
            isOnCalendar = false
            calendarMessage = ActivityCalendar.removedMessage
        case .accessDenied:
            showCalendarAccessAlert = true
        case .failed:
            calendarMessage = isOnCalendar
                ? ActivityDetailCopy.calendarRemoveFailedMessage
                : ActivityDetailCopy.calendarFailedMessage
        }
    }

    @ViewBuilder
    private var timeRow: some View {
        let text = Formatters.activityEventTime(from: activity.date)
        let secondary = Formatters.activityStartCountdown(from: activity.date)
        if canAddCalendarReminder {
            decisionRow(
                title: "时间",
                text: text,
                secondary: secondary
            ) {
                Task { await toggleCalendarReminder() }
            }
        } else {
            decisionRow(title: "时间", text: text, secondary: secondary)
        }
    }

    private var locationModule: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Label {
                    VStack(alignment: .leading) {
                        Text(activity.location)
                            .font(.body)
                        Text(activity.distanceLabel(hasUserLocation: location.coordinate != nil))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Text("地点")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .labelStyle(.titleAndIcon)
                .font(.body)

                Spacer(minLength: 0)

                ActivityDetailControls.GlassIconButton(
                    systemImage: "arrow.triangle.turn.up.right.diamond",
                    accessibilityLabel: ActivityDetailCopy.navigationAction
                ) {
                    showNavigationPicker = true
                }
            }

            if activity.latitude != nil, activity.longitude != nil {
                if showsMapPreview {
                    Button {
                        showNavigationPicker = true
                    } label: {
                        ActivityDetailLocationPreview(activity: activity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(ActivityDetailCopy.mapPreviewAccessibility)
                } else {
                    Color.clear
                        .frame(height: PlatformMetrics.detailMapHeight)
                        .clipShape(PlatformMetrics.mediaShape)
                        .accessibilityHidden(true)
                }
            }
        }
        .task {
            guard !showsMapPreview else { return }
            await Task.yield()
            guard !Task.isCancelled else { return }
            showsMapPreview = true
        }
    }

    private var spotsLabel: String {
        if viewerWaitlisted, !activity.isFull, !activity.isLifecycleEnded {
            return ActivityCardStatus.waitlistSpotOpen
        }
        return ActivityDetailCopy.spotsLabel(
            full: activity.isFull,
            almostFull: activity.isAlmostFull,
            remaining: activity.remainingSpots
        )
    }

    private var spotsColor: Color {
        if viewerWaitlisted, !activity.isFull, !activity.isLifecycleEnded {
            return PlatformStatus.success
        }
        return activity.isAlmostFull || activity.isFull ? PlatformStatus.warning : PlatformStatus.success
    }

    private func decisionRow(
        title: String,
        text: String,
        secondary: String,
        calendarAction: (() -> Void)? = nil
    ) -> some View {
        HStack(alignment: .center) {
            Label {
                VStack(alignment: .leading) {
                    Text(text)
                        .font(.body)
                    Text(secondary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .labelStyle(.titleAndIcon)
            .font(.body)

            Spacer(minLength: 0)

            if let calendarAction {
                ActivityDetailControls.CalendarGlassButton(isScheduled: isOnCalendar, action: calendarAction)
            }
        }
    }
}

/// 发起人：Form 行内默认 VStack + 系统 HStack 间距（与资料页身份行一致）
struct ActivityDetailHostTrustRow: View {
    let trust: ActivityHostTrust
    var onHost: () -> Void
    var onChat: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Button(action: onHost) {
                HStack(alignment: .center) {
                    PlatformListAvatarView(name: trust.name)
                    VStack(alignment: .leading) {
                        HStack {
                            Text(trust.name)
                            Text(trust.levelText)
                                .foregroundStyle(.secondary)
                            if trust.isVerified {
                                Image(systemName: TrustBadgeKind.photoVerified.systemImage)
                                    .foregroundStyle(.tint)
                                    .symbolRenderingMode(.hierarchical)
                                    .accessibilityLabel(TrustBadgeKind.photoVerified.title)
                            }
                            if trust.isMember {
                                Image(systemName: TrustBadgeKind.activeMember.systemImage)
                                    .foregroundStyle(.secondary)
                                    .symbolRenderingMode(.hierarchical)
                                    .accessibilityLabel(TrustBadgeKind.activeMember.title)
                            }
                        }
                        .font(.body)
                        .lineLimit(1)
                        Text(trust.metricsLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilitySummary)

            ActivityDetailControls.GlassIconButton(
                systemImage: "bubble.left",
                accessibilityLabel: ActivityDetailCopy.askHostAction,
                action: onChat
            )
        }
    }

    private var accessibilitySummary: String {
        var parts = [trust.name]
        parts.append(trust.levelText)
        if trust.isVerified { parts.append(TrustBadgeKind.photoVerified.title) }
        if trust.isMember { parts.append(TrustBadgeKind.activeMember.title) }
        parts.append(trust.hostedText)
        parts.append(trust.completionText)
        return parts.joined(separator: "，")
    }
}


