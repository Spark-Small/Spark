import SparkProfile
import Testing

@Test func mockPrepareAvatarUploadReturnsURL() async throws {
    let repository = MockProfileRepository()
    let prepared = try await repository.prepareAvatarUpload(contentType: "image/jpeg")
    #expect(prepared.avatarURL.absoluteString.contains("picsum"))
    #expect(prepared.uploadURL == nil)
}
