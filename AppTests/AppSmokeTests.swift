import XCTest
@testable import Pose

final class AppSmokeTests: XCTestCase {
    func testAppStatePersistsOnboarding() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let state = AppState(defaults: defaults)
        XCTAssertFalse(state.hasCompletedOnboarding)
        state.completeOnboarding()
        XCTAssertTrue(state.hasCompletedOnboarding)
    }
}
