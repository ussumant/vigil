import AppKit

@main
@MainActor
enum CaffeinateBarApp {
    private static var appDelegate: AppDelegate?

    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()

        appDelegate = delegate
        application.delegate = delegate
        application.run()
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController(manager: CaffeinateController())
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusBarController?.stop()
    }
}
