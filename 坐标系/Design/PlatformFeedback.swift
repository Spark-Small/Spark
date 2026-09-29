//
//  PlatformFeedback.swift
//  坐标系
//
//  系统反馈：Alert 告知 vs 轻量触觉（HIG §9.8）。
//

import SwiftUI

enum PlatformFeedback {
    static let dismissTitle = "好的"
}

extension View {
    /// 绑定反馈文案：系统 `.alert` 告知，单一「好的」关闭；禁止自定义 Toast 浮层。
    func platformFeedbackAlert(
        _ message: Binding<String?>,
        title: String = "",
        dismissTitle: String = PlatformFeedback.dismissTitle
    ) -> some View {
        alert(
            title,
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            )
        ) {
            Button(dismissTitle, role: .cancel) {
                message.wrappedValue = nil
            }
        } message: {
            if let text = message.wrappedValue {
                Text(text)
            }
        }
    }

    /// 轻量反馈：复制、收藏等无需打断操作的结果，仅触觉 + 自动清空绑定。
    func platformLightFeedback(_ message: Binding<String?>) -> some View {
        modifier(PlatformLightFeedbackModifier(message: message))
    }

    /// 状态切换反馈：控件自身 scale 弹动 + 触觉（收藏、候补 chip 等）。
    func platformStateFeedback(_ pulse: Binding<Int>) -> some View {
        modifier(PlatformStateFeedbackModifier(pulse: pulse))
    }
}

private struct PlatformLightFeedbackModifier: ViewModifier {
    @Binding var message: String?
    @State private var feedbackPulse = 0

    func body(content: Content) -> some View {
        content
            .onChange(of: message) { _, newValue in
                guard newValue != nil else { return }
                feedbackPulse += 1
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    if message == newValue {
                        message = nil
                    }
                }
            }
            .sensoryFeedback(.success, trigger: feedbackPulse)
    }
}

private struct PlatformStateFeedbackModifier: ViewModifier {
    @Binding var pulse: Int
    @State private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: pulse) { _, _ in
                PlatformMotion.withAnimation(.snappy(duration: 0.22)) {
                    scale = 1.18
                }
                PlatformMotion.withAnimation(.snappy(duration: 0.28).delay(0.08)) {
                    scale = 1
                }
            }
            .sensoryFeedback(.success, trigger: pulse)
    }
}
