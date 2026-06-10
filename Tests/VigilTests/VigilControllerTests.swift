import XCTest
@testable import Vigil

final class VigilControllerTests: XCTestCase {
    func testStartActivatesPowerAssertions() {
        let assertions = FakePowerAssertions()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let controller = VigilController(
            assertionManager: assertions,
            batteryMonitor: FakeBatteryMonitor(snapshot: nil),
            batterySettings: settings(),
            dateProvider: FakeDateProvider(now: now)
        )

        let state = controller.start()

        XCTAssertEqual(state, .active)
        XCTAssertEqual(assertions.activateCount, 1)
        XCTAssertTrue(controller.isActive)
        XCTAssertEqual(controller.activeSince, now)
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
        XCTAssertNil(controller.activeSince)
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
        XCTAssertNil(controller.activeSince)
    }

    func testThresholdEditsPersistAndClamp() {
        let defaults = UserDefaults(suiteName: "VigilTests-\(UUID().uuidString)")!
        var settings = BatteryGuardSettings(defaults: defaults)

        settings.threshold = 37
        XCTAssertEqual(BatteryGuardSettings(defaults: defaults).threshold, 37)

        settings.threshold = -8
        XCTAssertEqual(BatteryGuardSettings(defaults: defaults).threshold, 0)

        settings.threshold = 108
        XCTAssertEqual(BatteryGuardSettings(defaults: defaults).threshold, 100)
    }

    func testViewModelUsesExactStatusAndThresholdCopy() {
        let state = VigilMenuViewModel.make(
            state: .blockedByBattery(percentage: 19, threshold: 20),
            activeSince: nil,
            batterySnapshot: BatterySnapshot(percentage: 19, isOnBatteryPower: true),
            batteryThreshold: 20,
            launchAtLoginEnabled: false,
            appVersion: "1.0.2",
            buildNumber: "42",
            osVersion: OperatingSystemVersion(majorVersion: 14, minorVersion: 4, patchVersion: 0)
        )

        XCTAssertEqual(state.headerText, "Vigil · Idle")
        XCTAssertEqual(state.statusText, "Released at 19% battery. Limit 20%.")
        XCTAssertEqual(state.batteryText, "Battery 19% · battery power")
        XCTAssertEqual(state.warningText, "Below 20% — wakelock will release.")
        XCTAssertEqual(state.aboutText, "1.0.2 (42) · macOS 14.4")
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

private struct FakeDateProvider: DateProviding {
    let now: Date
}
