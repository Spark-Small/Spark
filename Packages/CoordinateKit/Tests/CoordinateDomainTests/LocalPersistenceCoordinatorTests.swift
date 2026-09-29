import CoordinateDomain
import XCTest

final class LocalPersistenceCoordinatorTests: XCTestCase {
    func testInvalidateBumpsGeneration() {
        let key: LocalPersistenceKey = .activities
        let before = LocalPersistenceCoordinator.currentGeneration(for: key)
        let bumped = LocalPersistenceCoordinator.invalidate(key)
        XCTAssertEqual(bumped, before + 1)
        XCTAssertEqual(LocalPersistenceCoordinator.currentGeneration(for: key), bumped)
    }

    func testStaleGenerationIsNotCurrent() {
        let key: LocalPersistenceKey = .messages
        let generation = LocalPersistenceCoordinator.currentGeneration(for: key)
        LocalPersistenceCoordinator.invalidate(key)
        XCTAssertFalse(LocalPersistenceCoordinator.isCurrent(generation, for: key))
    }
}
