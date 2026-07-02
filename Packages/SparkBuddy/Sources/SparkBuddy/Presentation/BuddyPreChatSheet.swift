// Module: SparkBuddy — 15-minute voice pre-chat sheet (wired to voice service).

import SparkDesignSystem
import SwiftUI

struct BuddyPreChatSheet: View {
    @Bindable var viewModel: BuddyDetailViewModel
    let listing: BuddyListing
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SparkLayoutMetrics.sectionVerticalPadding) {
                    Text(
                        String(
                            localized: "buddy.prechat.intro",
                            defaultValue: "下单前可先进行 15 分钟语音预聊，建立初步信任。",
                            comment: "Pre-chat intro"
                        )
                    )
                    .font(.body)
                    featureRow(
                        icon: "phone.fill",
                        text: String(
                            localized: "buddy.prechat.inApp",
                            defaultValue: "全程在平台内进行，不暴露私人联系方式",
                            comment: "In-app voice"
                        )
                    )
                    featureRow(
                        icon: "waveform",
                        text: String(
                            localized: "buddy.prechat.recording",
                            defaultValue: "通话自动录音存档，保障双方权益",
                            comment: "Recording policy"
                        )
                    )
                    featureRow(
                        icon: "clock.fill",
                        text: String(
                            localized: "buddy.prechat.duration",
                            defaultValue: "单次预聊限时 15 分钟",
                            comment: "Duration limit"
                        )
                    )
                    if let session = viewModel.activeVoiceSession {
                        Label(
                            String(
                                localized: "buddy.prechat.active",
                                defaultValue: "通话进行中",
                                comment: "Active voice session"
                            ),
                            systemImage: "phone.connection.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        Button(role: .destructive) {
                            Task {
                                await viewModel.endPreChatSession()
                                dismiss()
                            }
                        } label: {
                            Text(
                                String(
                                    localized: "buddy.prechat.end",
                                    defaultValue: "结束通话",
                                    comment: "End pre-chat"
                                )
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            Task { await viewModel.startPreChatSession(for: listing) }
                        } label: {
                            Label(
                                String(
                                    localized: "buddy.prechat.start",
                                    defaultValue: "开始语音预聊",
                                    comment: "Start pre-chat CTA"
                                ),
                                systemImage: "phone.arrow.up.right.fill"
                            )
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding + 2)
                        }
                        .buttonStyle(.borderedProminent)
                        .sparkMinimumTouchTarget()
                    }
                }
                .padding(SparkLayoutMetrics.standardHorizontalPadding)
            }
            .navigationTitle(
                String(
                    localized: "buddy.prechat.title",
                    defaultValue: "语音预聊",
                    comment: "Pre-chat sheet title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        String(localized: "common.close", defaultValue: "关闭", comment: "Close")
                    ) {
                        Task {
                            await viewModel.endPreChatSession()
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func featureRow(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
    }
}
