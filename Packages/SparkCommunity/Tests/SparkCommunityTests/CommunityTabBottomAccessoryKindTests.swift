// Module: SparkCommunityTests — Community tab bottom accessory copy.

import SparkCommunity
import Testing

@Suite struct CommunityTabBottomAccessoryKindTests {
    @Test func composePostCopy() {
        let signedIn = CommunityTabBottomAccessoryKind.composePost(guest: false)
        #expect(signedIn.title == "发帖")
        #expect(signedIn.systemImage == "square.and.pencil")

        let guest = CommunityTabBottomAccessoryKind.composePost(guest: true)
        #expect(guest.title == "登录后发帖")
    }

    @Test func hiddenIsNotVisible() {
        #expect(CommunityTabBottomAccessoryKind.hidden.isVisible == false)
        #expect(CommunityTabBottomAccessoryKind.composePost(guest: false).isVisible)
    }
}
