import XCTest
@testable import Vigil

final class VigilControllerTests: XCTestCase {
    func testStartActivatesPowerAssertions() {
        let assertions = FakePowerAssertions()
        let controller = VigilController(
            assertionManager: assertions,
            batteryMonitor: FakeBatteryMonitor(snapshot: nil),
            batterySettings: settings()
        )

        let state = controller.start()

        XCTAssertEqual(state, .active)
        XCTAssertEqual(assertions.activateCount, 1)
        XCTAssertTrue(controller.isActive)
    }

    func testToggleDeactivatesPowerAssertions() {
        let assertions = FakePowerAssertions()
        let controller = VigilController(
            assertionManager: assertions,
            batteryMonitor: FakeBatteryMonitor(snapshot: nil),
            batterySettings: settings()
        )

        _ = controller.start()
        let state = controller.toggle()

        XCTAssertEqual(state, .inactive)
        XCTAssertFalse(controller.isActive)
        XCTAssertEqual(assertions.deactivateCount, 1)
    }

    func testRefreshPreservesNativeAssertionState() {
        let assertions = FakePowerAssertions()
        let controller = VigilController(
            assertionManager: assertions,
            batteryMonitor: FakeBatteryMonitor(snapshot: nil),
            batterySettings: settings()
        )

        _ = controller.start()
        controller.refreshState()

        XCTAssertEqual(controller.state, .active)
        XCTAssertTrue(controller.isActive)
    }

    func testAssertionFailureSurfacesFailedState() {
        let assertions = FakePowerAssertions()
        assertions.error = PowerAssertionError.failed(type: "test", code: kIOReturnError)
        let controller = VigilController(
            assertionManager: assertions,
            batteryMonitor: FakeBatteryMonitor(snapshot: nil),
            batterySettings: settings()
        )

        let state = controller.start()

        guard case .failed(let message) = state else {
            XCTFail("Expected failed state")
            return
        }

        XCTAssertFalse(message.isEmpty)
        XCTAssertFalse(controller.isActive)
    }

    func testStartBlocksWhenBatteryIsBelowConfiguredThreshold() {
        let assertions = FakePowerAssertions()
        let controller = VigilController(
            assertionManager: assertions,
            batteryMonitor: FakeBatteryMonitor(snapshot: BatterySnapshot(percentage: 19, isOnBatteryPower: true)),
            batterySettings: settings(threshold: 20)
        )

        let state = controller.start()

        XCTAssertEqual(state, .blockedByBattery(percentage: 19, threshold: 20))
        XCTAssertEqual(assertions.activateCount, 0)
        XCTAssertFalse(controller.isActive)
    }

    func testRefreshAutoDisablesWhenBatteryFallsBelowThreshold() {
        let assertions = FakePowerAssertions()
        let battery = FakeBatteryMonitor(snapshot: BatterySnapshot(percentage: 80, isOnBatteryPower: true))
        let controller = VigilController(
            assertionManager: assertions,
            batteryMonitor: battery,
            batterySettings: settings(threshold: 20)
        )

        _ = controller.start()
        battery.currentSnapshot = BatterySnapshot(percentage: 20, isOnBatteryPower: true)
        controller.refreshState()

        XCTAssertEqual(controller.state, .blockedByBattery(percentage: 20, threshold: 20))
        XCTAssertEqual(assertions.deactivateCount, 1)
        XCTAssertFalse(controller.isActive)
    }
}

private func settings(threshold: Int = BatteryGuardSettings.defaultThreshold) -> BatteryGuardSettings {
    let defaults = UserDefaults(suiteName: "VigilTests-\(UUID().uuidString)")!
    let settings = BatteryGuardSettings(defaults: defaults)
    var mutableSettings = settings
    mutableSettings.threshold = threshold
    return mutableSettings
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

private final class FakeBatteryMonitor: BatteryMonitoring {
    var currentSnapshot: BatterySnapshot?

    init(snapshot: BatterySnapshot?) {
        self.currentSnapshot = snapshot
    }

    func snapshot() -> BatterySnapshot? {
        currentSnapshot
    }
}
