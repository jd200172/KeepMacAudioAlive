import Foundation

enum Preferences {
    private static let uidKey = "LastSelectedDeviceUID"
    private static let nameKey = "LastSelectedDeviceName"
    private static let runningKey = "WantsRunning"

    static var selectedDeviceUID: String? {
        UserDefaults.standard.string(forKey: uidKey)
    }

    /// Last known name of the selected device, so the menu can still show it while it is unplugged.
    static var selectedDeviceName: String? {
        UserDefaults.standard.string(forKey: nameKey)
    }

    /// Whether the user last left the app running or stopped. `nil` until the user first chooses.
    static var wantsRunning: Bool? {
        get { UserDefaults.standard.object(forKey: runningKey) as? Bool }
        set { UserDefaults.standard.set(newValue, forKey: runningKey) }
    }

    static func saveSelection(uid: String, name: String) {
        UserDefaults.standard.set(uid, forKey: uidKey)
        UserDefaults.standard.set(name, forKey: nameKey)
    }
}
