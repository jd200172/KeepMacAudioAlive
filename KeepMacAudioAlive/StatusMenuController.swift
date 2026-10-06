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
        let label = "KeepMacAudioAlive: \(statusDescription)"

        button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: label)
        button.appearsDisabled = keeper.state != .running
        button.toolTip = label
    }

    private var statusDescription: String {
        switch keeper.state {
        case .running: "active"
        case .stopped: "stopped"
        case .waiting: "waiting for device"
        }
    }

    // MARK: - Markers

    /// Every item gets a marker image of this size (dot, checkmark, or blank). AppKit only reserves the
    /// leading state column while some item shows a state, so a uniform marker keeps the text aligned
    /// no matter which items are checked.
    ///
    /// The glyph sits `markerInset` points inside the image so the gap from the menu's left edge to the glyph
    /// matches the gap from the shortcut text to the right edge (about 18.5 pt on macOS 26).
    private static let markerGlyphWidth: CGFloat = 14
    private static let markerInset: CGFloat = 4
    private static let markerSize = NSSize(width: markerInset + markerGlyphWidth, height: 14)

    private static let blankMarker = NSImage(size: markerSize, flipped: false) { _ in true }

    private static let checkMarker: NSImage = {
        let symbol = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 11, weight: .semibold))
        let image = NSImage(size: markerSize, flipped: false) { rect in
            if let symbol {
                let size = symbol.size
                symbol.draw(in: NSRect(x: markerInset + (markerGlyphWidth - size.width) / 2,
                                       y: (rect.height - size.height) / 2,
                                       width: size.width, height: size.height))
            }
            return true
        }
        image.isTemplate = true
        return image
    }()

    private static func dotMarker(_ color: NSColor) -> NSImage {
        NSImage(size: markerSize, flipped: false) { rect in
            color.setFill()
            NSBezierPath(ovalIn: NSRect(x: markerInset + (markerGlyphWidth - 8) / 2,
                                        y: (rect.height - 8) / 2, width: 8, height: 8)).fill()
            return true
        }
    }

    /// Green while running, red when stopped, amber while waiting for the selected device.
    private var statusMarker: NSImage {
        switch keeper.state {
        case .running: Self.dotMarker(.systemGreen)
        case .stopped: Self.dotMarker(.systemRed)
        case .waiting: Self.dotMarker(.systemOrange)
        }
    }

    private func setMarker(_ image: NSImage, on item: NSMenuItem) {
        item.onStateImage = image
        item.state = .on
    }

    // MARK: - Menu

    func menuWillOpen(_ menu: NSMenu) {
        isMenuOpen = true
        rebuildMenu()
    }

    func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let toggle = NSMenuItem(title: keeper.state == .stopped ? "Start" : "Stop",
                                action: #selector(toggleRunning), keyEquivalent: "s")
        toggle.target = self
        setMarker(Self.blankMarker, on: toggle)
        menu.addItem(toggle)
        menu.addItem(.separator())

        // The status dot takes the place of the checkmark on the selected device.
        let selectedIsPresent = keeper.devices.contains { $0.uid == keeper.selectedUID }
        if let name = keeper.selectedName, !selectedIsPresent {
            let missing = NSMenuItem()
            missing.attributedTitle = NSAttributedString(
                string: name,
                attributes: [.font: NSFont.menuFont(ofSize: 0), .foregroundColor: NSColor.tertiaryLabelColor]
            )
            setMarker(statusMarker, on: missing)
            menu.addItem(missing)
        }
        for (index, device) in keeper.devices.enumerated() {
            let item = NSMenuItem(title: device.name, action: #selector(selectDevice(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            setMarker(device.uid == keeper.selectedUID ? statusMarker : Self.blankMarker, on: item)
            menu.addItem(item)
        }
        if keeper.devices.isEmpty && keeper.selectedName == nil {
            let none = NSMenuItem(title: "No Output Devices", action: nil, keyEquivalent: "")
            none.isEnabled = false
            setMarker(Self.blankMarker, on: none)
            menu.addItem(none)
        }
        menu.addItem(.separator())

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        login.target = self
        setMarker(LoginItem.isEnabled ? Self.checkMarker : Self.blankMarker, on: login)
        menu.addItem(login)

        let about = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        setMarker(Self.blankMarker, on: about)
        menu.addItem(about)

        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        setMarker(Self.blankMarker, on: quit)
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
