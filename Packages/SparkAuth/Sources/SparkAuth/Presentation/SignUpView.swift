// Module: SparkAuth — Email registration screen.

import SparkDesignSystem
import SwiftUI

public struct SignUpView: View {
    @Bindable var viewModel: AuthViewModel

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            fieldsSection
            actionSection
            legalSection
        }
        .formStyle(.grouped)
        .sparkDismissesKeyboardOnScroll()
        .navigationTitle(SignUpCopy.title)
        .navigationBarTitleDisplayMode(.inline)
        .authFailureAlert(viewModel: viewModel)
    }
}

// MARK: - Sections

private extension SignUpView {
    var fieldsSection: some View {
        Section {
            TextField(SignUpCopy.displayNamePlaceholder, text: $viewModel.signUpDisplayName)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            TextField(SignUpCopy.emailPlaceholder, text: $viewModel.signUpEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            SecureField(SignUpCopy.passwordPlaceholder, text: $viewModel.signUpPassword)
                .textContentType(.newPassword)
        } footer: {
            Text(SignUpCopy.passwordFooter)
        }
    }

    var actionSection: some View {
        Section {
            Button {
                Task { await viewModel.signUpWithEmailTapped() }
            } label: {
                Group {
                    if viewModel.isSigningUp {
                        ProgressView()
                            .controlSize(.regular)
                    } else {
                        Text(SignUpCopy.signUpButton)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .loginPrimaryButtonChrome()
            .disabled(!viewModel.canSignUp || viewModel.isSigningUp)
            .loginActionRowChrome()
        }
    }

    var legalSection: some View {
        Section {
            AuthLegalFooter()
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .listRowInsets(SparkAuthLayout.legalRowInsets)
                .listRowBackground(Color.clear)
        }
    }
}

#Preview("Default") {
    NavigationStack {
        SignUpView(viewModel: AuthPreviewSupport.makeViewModel())
    }
}

#Preview("Dark") {
    NavigationStack {
        SparkPreviewSupport.darkMode {
            SignUpView(viewModel: AuthPreviewSupport.makeViewModel())
        }
    }
}
