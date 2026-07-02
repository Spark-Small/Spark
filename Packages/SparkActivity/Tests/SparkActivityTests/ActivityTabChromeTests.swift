// Module: SparkActivityTests — Tab chrome reconcile (single source of truth).

import SparkActivity
import Testing

@MainActor
@Suite struct ActivityTabChromeTests {
  @Test func discoverListShowsCreateWhenAtRoot() {
        let chrome = ActivityTabChrome()
        chrome.navigation.isActivityTabSelected = true
        chrome.navigation.isAtHomeRoot = true
        chrome.navigation.isDiscoverSegmentActive = true
        chrome.navigation.hasBrowseCatalog = true
        chrome.navigation.isGuest = false
        chrome.reconcile()

        #expect(chrome.kind == .createActivity(guest: false))
        #expect(chrome.isBottomAccessoryEnabled)
    }

    @Test func mapSegmentHidesCreateAtRoot() {
        let chrome = ActivityTabChrome()
        chrome.navigation.isActivityTabSelected = true
        chrome.navigation.isAtHomeRoot = true
        chrome.navigation.isDiscoverSegmentActive = false
        chrome.navigation.hasBrowseCatalog = true
        chrome.reconcile()

        #expect(chrome.kind == .hidden)
    }

    @Test func detailRSVPTakesPriorityOverList() {
        let chrome = ActivityTabChrome()
        chrome.navigation.isActivityTabSelected = true
        chrome.navigation.isAtHomeRoot = false
        chrome.navigation.isDiscoverSegmentActive = true
        chrome.navigation.hasBrowseCatalog = true
        chrome.detail.isActive = true
        chrome.detail.canChangeRSVP = true
        chrome.detail.rsvpStatus = .invited
        chrome.detail.canSelectGoing = true
        chrome.reconcile()

        #expect(chrome.kind == .rsvpGoing(isEnabled: true))
    }

    @Test func guestDetailShowsSignIn() {
        let chrome = ActivityTabChrome()
        chrome.navigation.isActivityTabSelected = true
        chrome.navigation.isGuest = true
        chrome.detail.isActive = true
        chrome.detail.canChangeRSVP = true
        chrome.detail.rsvpStatus = .invited
        chrome.reconcile()

        #expect(chrome.kind == .signInToRSVP)
    }

    @Test func leavingActivityTabHidesAccessory() {
        let chrome = ActivityTabChrome()
        chrome.navigation.isActivityTabSelected = false
        chrome.navigation.isAtHomeRoot = true
        chrome.navigation.isDiscoverSegmentActive = true
        chrome.navigation.hasBrowseCatalog = true
        chrome.reconcile()

        #expect(chrome.kind == .hidden)
    }

    @Test func clearDetailRestoresDiscoverCreate() {
        let chrome = ActivityTabChrome()
        chrome.navigation.isActivityTabSelected = true
        chrome.navigation.isAtHomeRoot = true
        chrome.navigation.isDiscoverSegmentActive = true
        chrome.navigation.hasBrowseCatalog = true
        chrome.detail.isActive = true
        chrome.detail.canChangeRSVP = true
        chrome.detail.rsvpStatus = .invited
        chrome.clearDetailAccessory()
        chrome.reconcile()

        #expect(chrome.kind == .createActivity(guest: false))
    }

    @Test func performPrimaryActionUsesDetailHandler() {
        let chrome = ActivityTabChrome()
        var didSubmit = false
        chrome.detail.isActive = true
        chrome.detail.canChangeRSVP = true
        chrome.detail.rsvpStatus = .invited
        chrome.registerDetailHandlers(signIn: nil) {
            didSubmit = true
        }
        chrome.reconcile()
        chrome.performPrimaryAction { }
        #expect(didSubmit)
    }

    @Test func performPrimaryActionUsesCreateFallback() {
        let chrome = ActivityTabChrome()
        var didCreate = false
        chrome.navigation.isActivityTabSelected = true
        chrome.navigation.isAtHomeRoot = true
        chrome.navigation.isDiscoverSegmentActive = true
        chrome.navigation.hasBrowseCatalog = true
        chrome.reconcile()
        chrome.performPrimaryAction { didCreate = true }
        #expect(didCreate)
    }

    @Test func homeObscuredBySheetHidesAccessory() {
        let chrome = ActivityTabChrome()
        chrome.navigation.isActivityTabSelected = true
        chrome.navigation.isAtHomeRoot = true
        chrome.navigation.isHomeObscured = true
        chrome.navigation.isDiscoverSegmentActive = true
        chrome.navigation.hasBrowseCatalog = true
        chrome.reconcile()

        #expect(chrome.kind == .hidden)
        #expect(chrome.showsDiscoverTopFilter == false)
    }

    @Test func discoverListShowsTopFilterAccessory() {
        let chrome = ActivityTabChrome()
        chrome.navigation.isActivityTabSelected = true
        chrome.navigation.isAtHomeRoot = true
        chrome.navigation.isDiscoverSegmentActive = true
        chrome.navigation.hasBrowseCatalog = true
        chrome.reconcile()

        #expect(chrome.showsDiscoverTopFilter)
        #expect(chrome.isTopAccessoryEnabled)
    }

    @Test func mapSegmentHidesTopFilterAccessory() {
        let chrome = ActivityTabChrome()
        chrome.navigation.isActivityTabSelected = true
        chrome.navigation.isAtHomeRoot = true
        chrome.navigation.isDiscoverSegmentActive = false
        chrome.navigation.hasBrowseCatalog = true
        chrome.reconcile()

        #expect(chrome.showsDiscoverTopFilter == false)
    }

    @Test func detailHidesTopFilterAccessory() {
        let chrome = ActivityTabChrome()
        chrome.navigation.isActivityTabSelected = true
        chrome.navigation.isAtHomeRoot = false
        chrome.navigation.isDiscoverSegmentActive = true
        chrome.navigation.hasBrowseCatalog = true
        chrome.detail.isActive = true
        chrome.detail.canChangeRSVP = true
        chrome.detail.rsvpStatus = .invited
        chrome.reconcile()

        #expect(chrome.showsDiscoverTopFilter == false)
    }

    @Test func tabReselectRestoresDetailRSVPAccessory() {
        let chrome = ActivityTabChrome()
        chrome.navigation.isActivityTabSelected = true
        chrome.navigation.isAtHomeRoot = false
        chrome.detail.isActive = true
        chrome.detail.canChangeRSVP = true
        chrome.detail.rsvpStatus = .invited
        chrome.detail.canSelectGoing = true
        chrome.reconcile()

        #expect(chrome.kind == .rsvpGoing(isEnabled: true))

        chrome.navigation.isActivityTabSelected = false
        chrome.reconcile()
        #expect(chrome.kind == .hidden)

        chrome.navigation.isActivityTabSelected = true
        chrome.reconcile()
        #expect(chrome.kind == .rsvpGoing(isEnabled: true))
    }
}
