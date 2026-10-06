import Foundation

enum Preferences {
    private static let uidKey = "LastSelectedDeviceUID"
    private static let nameKey = "LastSelectedDeviceName"

    static var selectedDeviceUID: String? {
        UserDefaults.standard.string(forKey: uidKey)
    }

    /// Last known name of the selected device, so the menu can still show it while it is unplugged.
    static var selectedDeviceName: String? {
        UserDefaults.standard.string(forKey: nameKey)
    }

    static func saveSelection(uid: String, name: String) {
        UserDefaults.standard.set(uid, forKey: uidKey)
        UserDefaults.standard.set(name, forKey: nameKey)
    }
}
