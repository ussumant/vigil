import AppKit

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let manager: CaffeinateController
    private let statusItem: NSStatusItem
    private weak var statusRowItem: NSMenuItem?
    private weak var toggleItem: NSMenuItem?

    init(manager: CaffeinateController) {
        self.manager = manager
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        super.init()

        configureStatusItem()
        rebuildMenu()
    }

    func stop() {
        manager.stop()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.imagePosition = .imageOnly
        button.toolTip = "Caffeinate"
        updateStatusIcon()
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else {
            return
        }

        let symbolName = manager.isActive ? "bolt.fill" : "bolt"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Caffeinate")

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

        let toggleItem = NSMenuItem(
            title: manager.isActive ? "Stop Keeping Awake" : "Keep Awake",
            action: #selector(toggleKeepAwake),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = manager.isActive ? .on : .off
        self.toggleItem = toggleItem
        menu.addItem(toggleItem)

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
        toggleItem?.title = manager.isActive ? "Stop Keeping Awake" : "Keep Awake"
        toggleItem?.state = manager.isActive ? .on : .off
    }

    private func headerItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(
            string: "Caffeinate",
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
            string: "Keeps macOS awake while active.",
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

    private func statusText() -> String {
        switch manager.state {
        case .active:
            return "Status: Awake"
        case .inactive:
            return "Status: Off"
        case .failed(let message):
            return "Status: Failed - \(message)"
        }
    }

    @objc
    private func toggleKeepAwake() {
        _ = manager.toggle()
        refreshMenuState()
    }

    @objc
    private func quit() {
        stop()
        NSApp.terminate(nil)
    }
}
