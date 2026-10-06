import AppKit

/// Menu bar item. The menu is rebuilt only while it is open, so nothing runs when the user is not looking.
final class StatusMenuController: NSObject, NSMenuDelegate {
    private let keeper: AudioKeeper
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private var isMenuOpen = false

    init(keeper: AudioKeeper) {
        self.keeper = keeper
        super.init()

        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
        statusItem.behavior = []

        keeper.onChange = { [weak self] in
            self?.updateIcon()
            if self?.isMenuOpen == true { self?.rebuildMenu() }
        }
        updateIcon()
    }

    // MARK: - Icon

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let symbol = keeper.state == .waiting ? "cable.connector.slash" : "waveform"
        let label = "KeepMacAudioAlive: \(statusDescription)"

        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        button.appearsDisabled = keeper.state == .stopped
        button.toolTip = label
    }

    private var statusDescription: String {
        switch keeper.state {
        case .running: "active"
        case .stopped: "stopped"
        case .waiting: "waiting for device"
        }
    }

    // MARK: - Menu

    func menuWillOpen(_ menu: NSMenu) {
        isMenuOpen = true
        rebuildMenu()
    }

    func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false
    }

    /// Green while running, red when stopped, amber while waiting for the selected device.
    private func statusDot() -> NSImage {
        let color: NSColor = switch keeper.state {
        case .running: .systemGreen
        case .stopped: .systemRed
        case .waiting: .systemOrange
        }
        return NSImage(size: NSSize(width: 8, height: 8), flipped: false) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let toggle = NSMenuItem(title: keeper.state == .stopped ? "Start" : "Stop",
                                action: #selector(toggleRunning), keyEquivalent: "s")
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())

        // The status dot takes the place of the checkmark on the selected device.
        let dot = statusDot()
        let selectedIsPresent = keeper.devices.contains { $0.uid == keeper.selectedUID }
        if let name = keeper.selectedName, !selectedIsPresent {
            let missing = NSMenuItem()
            missing.attributedTitle = NSAttributedString(
                string: name,
                attributes: [.font: NSFont.menuFont(ofSize: 0), .foregroundColor: NSColor.tertiaryLabelColor]
            )
            missing.onStateImage = dot
            missing.state = .on
            menu.addItem(missing)
        }
        for (index, device) in keeper.devices.enumerated() {
            let item = NSMenuItem(title: device.name, action: #selector(selectDevice(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            if device.uid == keeper.selectedUID {
                item.onStateImage = dot
                item.state = .on
            }
            menu.addItem(item)
        }
        if keeper.devices.isEmpty && keeper.selectedName == nil {
            let none = NSMenuItem(title: "No Output Devices", action: nil, keyEquivalent: "")
            none.isEnabled = false
            menu.addItem(none)
        }
        menu.addItem(.separator())

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        login.target = self
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)

        let about = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    // MARK: - Actions

    @objc private func toggleRunning() {
        if keeper.state == .stopped { keeper.start() } else { keeper.stop() }
    }

    @objc private func selectDevice(_ sender: NSMenuItem) {
        guard keeper.devices.indices.contains(sender.tag) else { return }
        keeper.select(keeper.devices[sender.tag])
    }

    @objc private func toggleLoginItem() {
        LoginItem.toggle()
    }

    @objc private func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
