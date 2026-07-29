//
//  BrandSplashView.swift
//  坐标系
//

import SwiftUI

struct BrandSplashView: View {
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var markVisible = false
    @State private var didFinish = false

    var body: some View {
        ZStack {
            InvitationPaper.stage
                .ignoresSafeArea()

            BrandLogo(size: 88)
                .scaleEffect(markVisible ? 1 : (reduceMotion ? 1 : 0.985))
                .opacity(markVisible ? 1 : 0)
                .offset(y: -12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("坐标系")
        .accessibilityAddTraits(.isHeader)
        .task { await runIntro() }
    }

    @MainActor
    private func runIntro() async {
        guard !didFinish else { return }

        if reduceMotion {
            markVisible = true
            finish()
            return
        }

        withAnimation(LaunchMotion.logoReveal) {
            markVisible = true
        }

        try? await Task.sleep(for: LaunchMotion.logoIntro)
        finish()
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}

#Preview("Brand Splash") {
    BrandSplashView(onFinished: {})
}
