// Module: SparkAuth — Shared failure alert for auth screens.

import SwiftUI

extension View {
    func authFailureAlert(viewModel: AuthViewModel) -> some View {
        alert(LoginCopy.errorTitle, isPresented: viewModel.failureAlertIsPresented) {
            Button(LoginCopy.errorOK) { viewModel.dismissFailure() }
        } message: {
            if case let .failure(message) = viewModel.authState {
                Text(message)
            }
        }
    }
}
