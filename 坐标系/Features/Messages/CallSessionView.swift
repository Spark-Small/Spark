//
//  CallSessionView.swift
//  坐标系
//

import SwiftUI
import CoordinateModels

struct CallSessionView: View {
    let conversationID: ChatConversation.ID
    let callID: CallSessionRecord.ID

    @Environment(MessagesModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var isMuted = false
    @State private var speakerOn = false
    @State private var cameraOn = true

    private var conversation: ChatConversation? {
        model.conversations.first { $0.id == conversationID }
    }

    private var call: CallSessionRecord? {
        model.recentCalls(for: conversationID).first { $0.id == callID }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: PlatformMetrics.sectionHeaderSpacing) {
                Spacer(minLength: 0)
                Image(systemName: call?.kind.systemImage ?? "phone.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.accentColor)
                Text(conversation?.title ?? MessagesCopy.voiceCall)
                    .font(.title2.weight(.semibold))
                Text(statusText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text(MessagesCopy.callLocalModeHint)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PlatformMetrics.contentInset)

                Spacer(minLength: 0)

                HStack(spacing: PlatformMetrics.railCardSpacing) {
                    toggleButton(MessagesCopy.callMuted, systemImage: isMuted ? "mic.slash.fill" : "mic.fill") {
                        isMuted.toggle()
                    }
                    toggleButton(MessagesCopy.callSpeaker, systemImage: speakerOn ? "speaker.wave.3.fill" : "speaker.slash.fill") {
                        speakerOn.toggle()
                    }
                    if call?.kind == .video {
                        toggleButton(MessagesCopy.callCamera, systemImage: cameraOn ? "video.fill" : "video.slash.fill") {
                            cameraOn.toggle()
                        }
                    }
                }

                Button(MessagesCopy.callEnd, role: .destructive) {
                    model.endCall(callID)
                    dismiss()
                }
                .activityPrimaryCTA(controlSize: .large)

                Button(MessagesCopy.callBackToChat) {
                    dismiss()
                }
                .activitySecondaryCTA(controlSize: .large)
            }
            .padding(PlatformMetrics.contentInset)
            .navigationBarTitleDisplayMode(.inline)
            .task(id: call?.status) {
                guard let call, call.status == .ringing else { return }
                try? await Task.sleep(for: .milliseconds(900))
                model.connectCall(callID)
            }
        }
    }

    private var statusText: String {
        guard let call else { return MessagesCopy.callConnecting }
        switch call.status {
        case .ringing: return MessagesCopy.callRinging
        case .connecting: return MessagesCopy.callConnecting
        case .active:
            if let connectedAt = call.connectedAt {
                let duration = Int(Date.now.timeIntervalSince(connectedAt))
                let minute = max(duration, 0) / 60
                let second = max(duration, 0) % 60
                return String(format: "%02d:%02d", minute, second)
            }
            return call.status.rawValue
        case .ended, .missed, .cancelled, .rejected:
            return call.status.rawValue
        }
    }

    private func toggleButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: PlatformMetrics.hairlineSpacing) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}
