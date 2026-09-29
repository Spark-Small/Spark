//
//  CallHistorySheet.swift
//  坐标系
//
//  会话内通话记录：查看历史、一键回拨。
//

import SwiftUI
import CoordinateModels

struct CallHistorySheet: View {
    let conversationID: ChatConversation.ID
    var onRedial: (CallSessionKind) -> Void

    @Environment(MessagesModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private var calls: [CallSessionRecord] {
        model.recentCalls(for: conversationID)
    }

    var body: some View {
        MessagesBrowserSheet(title: MessagesCopy.callHistoryTitle) {
            List {
                if calls.isEmpty {
                    Text(MessagesCopy.callHistoryEmpty)
                        .foregroundStyle(.secondary)
                        .messagesListRow()
                } else {
                    ForEach(calls) { call in
                        CallHistoryRow(call: call)
                            .messagesListRow()
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if !call.status.isLive {
                                    Button(MessagesCopy.callHistoryRedial) {
                                        dismiss()
                                        onRedial(call.kind)
                                    }
                                    .tint(.accentColor)
                                }
                            }
                    }
                }
            }
        }
    }
}

private struct CallHistoryRow: View {
    let call: CallSessionRecord

    var body: some View {
        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
            Image(systemName: call.kind.systemImage)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: PlatformConversationListRow.imageSide)

            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(call.kind.rawValue)
                    .font(.body)
                Text(call.historyDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(Formatters.shortTime.string(from: call.startedAt))
                .font(PlatformListTypography.trailing)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
