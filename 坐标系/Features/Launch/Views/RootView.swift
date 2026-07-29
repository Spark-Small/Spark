//
//  RootView.swift
//  坐标系
//

import SwiftUI

struct RootView: View {
    @Bindable var session: LocalAuthSession

    @Namespace private var launchNamespace
    @State private var viewModel = LaunchViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            InvitationPaper.stage
                .ignoresSafeArea()

            RadialGradient(
                colors: [Color.white.opacity(0.28), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.28),
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            launchContent
        }
    }

    @ViewBuilder
    private var launchContent: some View {
        let state = viewModel.state

        ZStack {
            BrandSplashView {
                viewModel.brandSplashFinished(reduceMotion: reduceMotion)
            }
            .opacity(state == .brandSplash ? 1 : 0)
            .allowsHitTesting(false)
            .zIndex(6)

            if showsEnvelope(state) {
                envelopeStage
                    .opacity(state == .letterExpanding || state == .login ? 0 : 1)
                    .zIndex(2)
            }

            if state == .letterExpanding {
                InvitationLetterView(expansion: 1, namespace: launchNamespace)
                    .zIndex(3)
            }

            if state == .login {
                LoginView(session: session, namespace: launchNamespace)
                    .zIndex(5)
            }
        }
        .animation(LaunchMotion.stateCrossfade, value: state)
    }

    private func showsEnvelope(_ state: LaunchState) -> Bool {
        switch state {
        case .brandTransition, .invitationReady, .opening, .letterExpanding:
            true
        default:
            false
        }
    }

    private var envelopeStage: some View {
        let state = viewModel.state
        let flapOpen = state == .opening || state == .letterExpanding
        let rise: CGFloat = switch state {
        case .opening: 0.9
        case .letterExpanding: 1
        default: 0
        }

        return EnvelopeView(
            isFlapOpen: flapOpen,
            letterRise: rise,
            showsLetter: state == .invitationReady || state == .opening,
            isFloating: state == .invitationReady,
            isArriving: state == .brandTransition,
            namespace: launchNamespace,
            onTap: { viewModel.openInvitation(reduceMotion: reduceMotion) },
            onOpenFinished: { viewModel.envelopeOpenFinished() }
        )
        .animation(LaunchMotion.letterRise, value: rise)
        .allowsHitTesting(state == .invitationReady)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Launch Root") {
    RootView(session: LocalAuthSession())
}
