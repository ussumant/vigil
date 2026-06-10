import AppKit

@main
@MainActor
enum VigilApp {
    private static var appDelegate: AppDelegate?

    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()

        FontLoader.registerBundledFonts()
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
        statusBarController = StatusBarController(manager: VigilController())
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusBarController?.stop()
    }
}
