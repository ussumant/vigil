import Foundation

struct VigilMenuState: Equatable {
    let isActive: Bool
    let headerText: String
    let statusText: String
    let batteryText: String?
    let thresholdText: String
    let warningText: String?
    let launchAtLoginText: String
    let launchAtLoginEnabled: Bool
    let aboutText: String
    let toggleText: String
}

enum VigilMenuViewModel {
    static func make(
        state: VigilState,
        activeSince: Date?,
        batterySnapshot: BatterySnapshot?,
        batteryThreshold: Int,
        launchAtLoginEnabled: Bool,
        appVersion: String,
        buildNumber: String,
        osVersion: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
    ) -> VigilMenuState {
        let isActive = state == .active
        let headerText: String
        if isActive, let activeSince {
            headerText = "Vigil · Active since \(timeString(from: activeSince))"
        } else {
            headerText = "Vigil · Idle"
        }

        return VigilMenuState(
            isActive: isActive,
            headerText: headerText,
            statusText: statusText(for: state),
            batteryText: batteryText(from: batterySnapshot),
            thresholdText: "\(batteryThreshold)",
            warningText: batteryThreshold > 0 ? "Below \(batteryThreshold)% — wakelock will release." : nil,
            launchAtLoginText: launchAtLoginEnabled ? "Launch at login enabled" : "Launch at login disabled",
            launchAtLoginEnabled: launchAtLoginEnabled,
            aboutText: "\(appVersion) (\(buildNumber)) · macOS \(osVersion.majorVersion).\(osVersion.minorVersion)",
            toggleText: isActive ? "Disable Wakelock" : "Enable Wakelock"
        )
    }

    private static func statusText(for state: VigilState) -> String {
        switch state {
        case .active:
            return "Wakelock active."
        case .inactive:
            return "Wakelock idle."
        case .blockedByBattery(let percentage, let threshold):
            return "Released at \(percentage)% battery. Limit \(threshold)%."
        case .failed(let message):
            return "Failed. \(message)"
        }
    }

    private static func batteryText(from snapshot: BatterySnapshot?) -> String? {
        guard let snapshot else {
            return nil
        }

        let source = snapshot.isOnBatteryPower ? "battery power" : "power adapter"
        return "Battery \(snapshot.percentage)% · \(source)"
    }

    private static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
