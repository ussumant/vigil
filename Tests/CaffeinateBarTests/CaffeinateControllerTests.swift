import XCTest
@testable import CaffeinateBar

final class CaffeinateControllerTests: XCTestCase {
    func testStartActivatesPowerAssertions() {
        let assertions = FakePowerAssertions()
        let controller = CaffeinateController(assertionManager: assertions)

        let state = controller.start()

        XCTAssertEqual(state, .active)
        XCTAssertEqual(assertions.activateCount, 1)
        XCTAssertTrue(controller.isActive)
    }

    func testToggleDeactivatesPowerAssertions() {
        let assertions = FakePowerAssertions()
        let controller = CaffeinateController(assertionManager: assertions)

        _ = controller.start()
        let state = controller.toggle()

        XCTAssertEqual(state, .inactive)
        XCTAssertFalse(controller.isActive)
        XCTAssertEqual(assertions.deactivateCount, 1)
    }

    func testRefreshPreservesNativeAssertionState() {
        let assertions = FakePowerAssertions()
        let controller = CaffeinateController(assertionManager: assertions)

        _ = controller.start()
        controller.refreshState()

        XCTAssertEqual(controller.state, .active)
        XCTAssertTrue(controller.isActive)
    }

    func testAssertionFailureSurfacesFailedState() {
        let assertions = FakePowerAssertions()
        assertions.error = PowerAssertionError.failed(type: "test", code: kIOReturnError)
        let controller = CaffeinateController(assertionManager: assertions)

        let state = controller.start()

        guard case .failed(let message) = state else {
            XCTFail("Expected failed state")
            return
        }

        XCTAssertFalse(message.isEmpty)
        XCTAssertFalse(controller.isActive)
    }
}

private final class FakePowerAssertions: PowerAssertionManaging {
    var activateCount = 0
    var deactivateCount = 0
    var error: Error?

    func activate() throws {
        activateCount += 1

        if let error {
            throw error
        }
    }

    func deactivate() {
        deactivateCount += 1
    }
}
