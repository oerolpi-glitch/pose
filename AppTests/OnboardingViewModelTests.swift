import XCTest
@testable import Pose

final class OnboardingViewModelTests: XCTestCase {
    func testStepsAdvanceInOrder() {
        let vm = OnboardingViewModel()
        XCTAssertEqual(vm.step, .intro)
        vm.advance(); XCTAssertEqual(vm.step, .goals)
        vm.advance(); XCTAssertEqual(vm.step, .analyzing)
        vm.advance(); XCTAssertEqual(vm.step, .socialProof)
        vm.advance(); XCTAssertEqual(vm.step, .featureReveal)
        vm.advance(); XCTAssertEqual(vm.step, .customPlan)
        vm.advance(); XCTAssertEqual(vm.step, .customPlan) // terminal
    }

    func testSelectionsPersistAcrossSteps() {
        let vm = OnboardingViewModel()
        vm.selectedStruggles.insert("stiff posture")
        vm.advance()
        XCTAssertTrue(vm.selectedStruggles.contains("stiff posture"))
    }
}
