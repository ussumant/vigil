import Foundation
import IOKit.pwr_mgt
import IOKit.ps

protocol PowerAssertionManaging {
    func activate() throws
    func deactivate()
}

enum PowerAssertionError: LocalizedError {
    case failed(type: String, code: IOReturn)

    var errorDescription: String? {
        switch self {
        case .failed(let type, let code):
            return "Unable to create \(type) power assertion (\(code))."
        }
    }
}

struct BatterySnapshot: Equatable {
    let percentage: Int
    let isOnBatteryPower: Bool
}

protocol BatteryMonitoring {
    func snapshot() -> BatterySnapshot?
}

struct BatteryGuardSettings {
    static let allowedThresholds = [0, 10, 20, 30, 40, 50]
    static let defaultThreshold = 20

    private let defaults: UserDefaults
    private let key = "batteryDisableThreshold"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var threshold: Int {
        get {
            let value = defaults.object(forKey: key) as? Int ?? Self.defaultThreshold
            return Self.allowedThresholds.contains(value) ? value : Self.defaultThreshold
        }
        set {
            let sanitized = Self.allowedThresholds.contains(newValue) ? newValue : Self.defaultThreshold
            defaults.set(sanitized, forKey: key)
        }
    }

    var isEnabled: Bool {
        threshold > 0
    }
}

enum VigilState: Equatable {
    case inactive
    case active
    case blockedByBattery(percentage: Int, threshold: Int)
    case failed(String)
}

final class VigilController {
    private let assertionManager: PowerAssertionManaging
    private let batteryMonitor: BatteryMonitoring
    private var batterySettings: BatteryGuardSettings

    private(set) var state: VigilState = .inactive

    init(
        assertionManager: PowerAssertionManaging = IOKitPowerAssertionManager(),
        batteryMonitor: BatteryMonitoring = IOKitBatteryMonitor(),
        batterySettings: BatteryGuardSettings = BatteryGuardSettings()
    ) {
        self.assertionManager = assertionManager
        self.batteryMonitor = batteryMonitor
        self.batterySettings = batterySettings
    }

    var isActive: Bool {
        return state == .active
    }

    var batteryThreshold: Int {
        get {
            batterySettings.threshold
        }
        set {
            batterySettings.threshold = newValue
            refreshState()
        }
    }

    var batterySnapshot: BatterySnapshot? {
        batteryMonitor.snapshot()
    }

    @discardableResult
    func toggle() -> VigilState {
        isActive ? stop() : start()
    }

    @discardableResult
    func start() -> VigilState {
        guard state != .active else {
            return state
        }

        if let blockedState = batteryBlockedState() {
            state = blockedState
            return state
        }

        do {
            try assertionManager.activate()
            state = .active
        } catch {
            state = .failed(error.localizedDescription)
        }

        return state
    }

    @discardableResult
    func stop() -> VigilState {
        assertionManager.deactivate()
        state = .inactive
        return state
    }

    func refreshState() {
        guard isActive, let blockedState = batteryBlockedState() else {
            return
        }

        assertionManager.deactivate()
        state = blockedState
    }

    private func batteryBlockedState() -> VigilState? {
        let threshold = batterySettings.threshold
        guard threshold > 0,
              let snapshot = batteryMonitor.snapshot(),
              snapshot.isOnBatteryPower,
              snapshot.percentage <= threshold else {
            return nil
        }

        return .blockedByBattery(percentage: snapshot.percentage, threshold: threshold)
    }
}

private final class IOKitPowerAssertionManager: PowerAssertionManaging {
    private var assertionIDs: [IOPMAssertionID] = []

    func activate() throws {
        deactivate()

        let assertionTypes = [
            kIOPMAssertionTypePreventUserIdleSystemSleep,
            kIOPMAssertionTypePreventUserIdleDisplaySleep
        ]

        do {
            for assertionType in assertionTypes {
                assertionIDs.append(try createAssertion(type: assertionType))
            }
        } catch {
            deactivate()
            throw error
        }
    }

    func deactivate() {
        for assertionID in assertionIDs {
            IOPMAssertionRelease(assertionID)
        }
        assertionIDs.removeAll()
    }

    private func createAssertion(type: String) throws -> IOPMAssertionID {
        var assertionID = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Vigil is keeping this Mac awake." as CFString,
            &assertionID
        )

        guard result == kIOReturnSuccess else {
            throw PowerAssertionError.failed(type: type, code: result)
        }

        return assertionID
    }
}

private struct IOKitBatteryMonitor: BatteryMonitoring {
    func snapshot() -> BatterySnapshot? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  let isPresent = description[kIOPSIsPresentKey] as? Bool,
                  isPresent,
                  let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int,
                  let maxCapacity = description[kIOPSMaxCapacityKey] as? Int,
                  maxCapacity > 0,
                  let powerSourceState = description[kIOPSPowerSourceStateKey] as? String else {
                continue
            }

            let percentage = Int((Double(currentCapacity) / Double(maxCapacity) * 100).rounded())
            return BatterySnapshot(
                percentage: percentage,
                isOnBatteryPower: powerSourceState == kIOPSBatteryPowerValue
            )
        }

        return nil
    }
}
