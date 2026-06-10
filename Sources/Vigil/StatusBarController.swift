import AppKit
import ServiceManagement

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let manager: VigilController
    private let statusItem: NSStatusItem
    private var refreshTimer: Timer?
    private weak var statusRowItem: NSMenuItem?
    private weak var batteryRowItem: NSMenuItem?
    private weak var toggleItem: NSMenuItem?
    private weak var launchAtLoginItem: NSMenuItem?

    init(manager: VigilController) {
        self.manager = manager
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        super.init()

        configureStatusItem()
        rebuildMenu()
        startRefreshTimer()
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        manager.stop()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.imagePosition = .imageOnly
        button.toolTip = "Vigil"
        updateStatusIcon()
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshMenuState()
            }
        }
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else {
            return
        }

        let symbolName = manager.isActive ? "eye" : "eye.slash"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Vigil")

        button.image = image
        button.image?.isTemplate = true
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self

        menu.addItem(headerItem())
        menu.addItem(subtitleItem())
        menu.addItem(NSMenuItem.separator())

        let statusRowItem = statusItemRow()
        self.statusRowItem = statusRowItem
        menu.addItem(statusRowItem)

        let batteryRowItem = batteryItemRow()
        self.batteryRowItem = batteryRowItem
        menu.addItem(batteryRowItem)

        menu.addItem(NSMenuItem.separator())

        let toggleItem = NSMenuItem(
            title: manager.isActive ? "Disable Wakelock" : "Enable Wakelock",
            action: #selector(toggleWakelock),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = manager.isActive ? .on : .off
        self.toggleItem = toggleItem
        menu.addItem(toggleItem)

        let thresholdMenu = NSMenu()
        for threshold in BatteryGuardSettings.allowedThresholds {
            let title = threshold == 0 ? "Off" : "\(threshold)%"
            let item = NSMenuItem(title: title, action: #selector(setBatteryThreshold), keyEquivalent: "")
            item.target = self
            item.representedObject = threshold
            item.state = manager.batteryThreshold == threshold ? .on : .off
            thresholdMenu.addItem(item)
        }
        let thresholdItem = NSMenuItem(title: "Auto-disable below", action: nil, keyEquivalent: "")
        thresholdItem.submenu = thresholdMenu
        menu.addItem(thresholdItem)

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = launchAtLoginEnabled ? .on : .off
        self.launchAtLoginItem = launchAtLoginItem
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshMenuState()
    }

    private func refreshMenuState() {
        manager.refreshState()
        updateStatusIcon()
        statusRowItem?.title = statusText()
        batteryRowItem?.title = batteryText()
        toggleItem?.title = manager.isActive ? "Disable Wakelock" : "Enable Wakelock"
        toggleItem?.state = manager.isActive ? .on : .off
        launchAtLoginItem?.state = launchAtLoginEnabled ? .on : .off
    }

    private func headerItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(
            string: "Vigil",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ]
        )
        return item
    }

    private func subtitleItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(
            string: "Menu-bar wakelock for long-running work.",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        return item
    }

    private func statusItemRow() -> NSMenuItem {
        let item = NSMenuItem()
        item.isEnabled = false
        item.title = statusText()
        return item
    }

    private func batteryItemRow() -> NSMenuItem {
        let item = NSMenuItem()
        item.isEnabled = false
        item.title = batteryText()
        return item
    }

    private func statusText() -> String {
        switch manager.state {
        case .active:
            return "Status: Wakelock active"
        case .inactive:
            return "Status: Off"
        case .blockedByBattery(let percentage, let threshold):
            return "Status: Disabled at \(percentage)% battery (limit \(threshold)%)"
        case .failed(let message):
            return "Status: Failed - \(message)"
        }
    }

    private func batteryText() -> String {
        let threshold = manager.batteryThreshold
        let thresholdText = threshold == 0 ? "off" : "\(threshold)%"

        guard let snapshot = manager.batterySnapshot else {
            return "Battery guard: \(thresholdText)"
        }

        let source = snapshot.isOnBatteryPower ? "battery" : "power"
        return "Battery guard: \(thresholdText) · \(snapshot.percentage)% on \(source)"
    }

    private var launchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @objc
    private func toggleWakelock() {
        _ = manager.toggle()
        refreshMenuState()
    }

    @objc
    private func setBatteryThreshold(_ sender: NSMenuItem) {
        guard let threshold = sender.representedObject as? Int else {
            return
        }

        manager.batteryThreshold = threshold
        rebuildMenu()
        refreshMenuState()
    }

    @objc
    private func toggleLaunchAtLogin() {
        do {
            if launchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            manager.stop()
        }

        refreshMenuState()
    }

    @objc
    private func quit() {
        stop()
        NSApp.terminate(nil)
    }
}
