// Module: SparkProfileTests

import SparkProfile
import SparkTrust
import Testing

@Suite struct ProfileViewModelTests {
    @Test @MainActor func loadsTrustProfile() async {
        let viewModel = ProfileViewModel(trustRepository: MockTrustRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .loaded)
    }
}
