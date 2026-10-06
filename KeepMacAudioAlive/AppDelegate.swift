import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var keeper: AudioKeeper?
    private var statusMenu: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let keeper = AudioKeeper()
        statusMenu = StatusMenuController(keeper: keeper)
        self.keeper = keeper
    }

    func applicationWillTerminate(_ notification: Notification) {
        keeper?.shutdown()
    }
}
