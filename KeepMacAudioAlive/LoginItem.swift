import ServiceManagement
import os

enum LoginItem {
    private static let log = Logger(subsystem: "com.github.openmac.KeepMacAudioAlive", category: "LoginItem")

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func toggle() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            log.error("Could not change login item: \(error.localizedDescription)")
        }
        if service.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
