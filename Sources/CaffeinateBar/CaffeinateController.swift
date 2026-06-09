import Foundation
import IOKit.pwr_mgt

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

enum CaffeinateState: Equatable {
    case inactive
    case active
    case failed(String)
}

final class CaffeinateController {
    private let assertionManager: PowerAssertionManaging

    private(set) var state: CaffeinateState = .inactive

    init(assertionManager: PowerAssertionManaging = IOKitPowerAssertionManager()) {
        self.assertionManager = assertionManager
    }

    var isActive: Bool {
        return state == .active
    }

    @discardableResult
    func toggle() -> CaffeinateState {
        isActive ? stop() : start()
    }

    @discardableResult
    func start() -> CaffeinateState {
        guard state != .active else {
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
    func stop() -> CaffeinateState {
        assertionManager.deactivate()
        state = .inactive
        return state
    }

    func refreshState() {
        // IOKit assertions remain active until released or the process exits.
    }
}

private final class IOKitPowerAssertionManager: PowerAssertionManaging {
    private var assertionIDs: [IOPMAssertionID] = []

    func activate() throws {
        deactivate()

        let assertionTypes = [
            kIOPMAssertionTypePreventUserIdleSystemSleep,
            kIOPMAssertionTypePreventUserIdleDisplaySleep,
            kIOPMAssertionTypePreventSystemSleep
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
            "Caffeinate is keeping this Mac awake." as CFString,
            &assertionID
        )

        guard result == kIOReturnSuccess else {
            throw PowerAssertionError.failed(type: type, code: result)
        }

        return assertionID
    }
}
