import AppKit
import ServiceManagement

@MainActor
final class StatusBarController: NSObject {
    private let manager: VigilController
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let popoverView: VigilPopoverView
    private var refreshTimer: Timer?

    init(manager: VigilController) {
        self.manager = manager
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.popover = NSPopover()
        self.popoverView = VigilPopoverView()

        super.init()

        configureStatusItem()
        configurePopover()
        refreshPopoverState()
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
        button.target = self
        button.action = #selector(togglePopover)
        updateStatusIcon()
    }

    private func configurePopover() {
        let controller = NSViewController()
        controller.view = popoverView

        popover.contentViewController = controller
        popover.contentSize = NSSize(width: 336, height: 392)
        popover.behavior = .transient
        popover.animates = false

        popoverView.onToggleWakelock = { [weak self] in
            guard let self else { return }
            _ = manager.toggle()
            refreshPopoverState()
        }

        popoverView.onThresholdChange = { [weak self] threshold in
            guard let self else { return }
            manager.batteryThreshold = threshold
            refreshPopoverState()
        }

        popoverView.onToggleLaunchAtLogin = { [weak self] in
            guard let self else { return }
            toggleLaunchAtLogin()
            refreshPopoverState()
        }

        popoverView.onQuit = { [weak self] in
            guard let self else { return }
            stop()
            NSApp.terminate(nil)
        }
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPopoverState()
            }
        }
    }

    private func updateStatusIcon() {
        statusItem.button?.image = VigilIconFactory.statusIcon(active: manager.isActive)
    }

    private func refreshPopoverState() {
        manager.refreshState()
        updateStatusIcon()
        popoverView.configure(with: makeMenuState())
    }

    private func makeMenuState() -> VigilMenuState {
        VigilMenuViewModel.make(
            state: manager.state,
            activeSince: manager.activeSince,
            batterySnapshot: manager.batterySnapshot,
            batteryThreshold: manager.batteryThreshold,
            launchAtLoginEnabled: launchAtLoginEnabled,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        )
    }

    private var launchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    private func toggleLaunchAtLogin() {
        do {
            if launchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            _ = manager.stop()
        }
    }

    @objc
    private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        refreshPopoverState()

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
