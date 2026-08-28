//
//  RootView.swift
//  坐标系
//

import SwiftUI

struct RootView: View {
    @Bindable var session: LocalAuthSession

    @Namespace private var launchNamespace
    @State private var viewModel = LaunchViewModel()
    @State private var path = NavigationPath()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LaunchStageBackground()

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
                case .invitationReady, .opening, .invitationOpened:
                    EmptyView()
                }
            }
        }
        .onChange(of: viewModel.state) { _, state in
            presentLoginIfNeeded(for: state)
        }
        .task(id: viewModel.state) {
            presentLoginIfNeeded(for: viewModel.state)
        }
    }

    private func presentLoginIfNeeded(for state: LaunchState) {
        guard state == .login, path.isEmpty else { return }
        path.append(LaunchState.login)
    }

    @ViewBuilder
    private var launchContent: some View {
        let state = viewModel.state
        let showsEnvelope = path.isEmpty

        EnvelopeView(
            isFlapOpen: state == .opening || state == .invitationOpened || state == .login,
            letterRise: state == .invitationReady ? 0 : 0.9,
            isFloating: state == .invitationReady,
            namespace: launchNamespace,
            onTap: { viewModel.openInvitation(reduceMotion: reduceMotion) },
            onOpenFinished: {
                viewModel.envelopeOpenFinished(reduceMotion: reduceMotion)
            }
        )
        .opacity(showsEnvelope ? 1 : 0)
        .allowsHitTesting(showsEnvelope && state == .invitationReady)
        .accessibilityHidden(!showsEnvelope)
        .animation(LaunchMotion.letterRise, value: state)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Launch Root") {
    RootView(session: LocalAuthSession())
}
