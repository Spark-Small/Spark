// Module: SparkActivityTests — Tab bottom accessory copy per context.

import SparkActivity
import Testing

@Suite struct ActivityTabBottomAccessoryKindTests {
    @Test func createActivityCopy() {
        let signedIn = ActivityTabBottomAccessoryKind.createActivity(guest: false)
        #expect(signedIn.title == "发起活动")
        #expect(signedIn.systemImage == "plus.circle.fill")

        let guest = ActivityTabBottomAccessoryKind.createActivity(guest: true)
        #expect(guest.title == "登录后发起活动")
    }

    @Test func detailRSVPCopy() {
        #expect(ActivityTabBottomAccessoryKind.signInToRSVP.title == "登录后参加")
        #expect(ActivityTabBottomAccessoryKind.rsvpGoing(isEnabled: true).title == "参加")
        #expect(ActivityTabBottomAccessoryKind.rsvpGoing(isEnabled: false).isInteractionEnabled == false)
    }

    @Test func hiddenIsNotVisible() {
        #expect(ActivityTabBottomAccessoryKind.hidden.isVisible == false)
        #expect(ActivityTabBottomAccessoryKind.createActivity(guest: false).isVisible)
    }
}
