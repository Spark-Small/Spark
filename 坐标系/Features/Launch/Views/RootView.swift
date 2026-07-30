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
        NavigationStack {
            ZStack {
                LaunchSurface.stage
                    .ignoresSafeArea()

                launchContent
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: LaunchState.self) { destination in
                switch destination {
                case .login:
                    LoginView(session: session)
                        .navigationTransition(
                            .zoom(
                                sourceID: LaunchGeometry.invitationSurface,
                                in: launchNamespace
                            )
                        )
                        .toolbar(.hidden, for: .navigationBar)
                default:
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    private var launchContent: some View {
        let state = viewModel.state

        EnvelopeView(
            isFlapOpen: state == .opening || state == .invitationOpened,
            isLetterInteractive: state == .invitationOpened,
            letterRise: state == .invitationReady ? 0 : 0.9,
            isFloating: state == .invitationReady,
            namespace: launchNamespace,
            onTap: { viewModel.openInvitation(reduceMotion: reduceMotion) },
            onOpenFinished: { viewModel.envelopeOpenFinished() }
        )
        .animation(LaunchMotion.letterRise, value: state)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Launch Root") {
    RootView(session: LocalAuthSession())
}
