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
        let waiting = keeper.state == .waiting
        let symbol = waiting ? "cable.connector.slash" : "waveform"
        let label = "KeepMacAudioAlive: \(status.title)"

        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        button.appearsDisabled = keeper.state == .stopped
        button.toolTip = label
    }

    // MARK: - Menu

    func menuWillOpen(_ menu: NSMenu) {
        isMenuOpen = true
        rebuildMenu()
    }

    func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false
    }

    private var status: (title: String, detail: String, color: NSColor) {
        let name = keeper.selectedName
        switch keeper.state {
        case .running:
            return ("Keeping Audio Alive", name ?? "", .systemGreen)
        case .stopped:
            return ("Stopped", name ?? "No output device selected", .tertiaryLabelColor)
        case .waiting:
            return ("Waiting for Device", name.map { "\($0) not connected" } ?? "No output device", .systemOrange)
        }
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        menu.addItem(headerItem())
        menu.addItem(.separator())

        let toggle = NSMenuItem(title: keeper.state == .stopped ? "Start" : "Stop",
                                action: #selector(toggleRunning), keyEquivalent: "s")
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())

        menu.addItem(.sectionHeader(title: "Output Device"))
        let selectedIsPresent = keeper.devices.contains { $0.uid == keeper.selectedUID }
        if let name = keeper.selectedName, !selectedIsPresent {
            let missing = NSMenuItem(title: name, action: nil, keyEquivalent: "")
            missing.state = .on
            missing.isEnabled = false
            missing.badge = NSMenuItemBadge(string: "Disconnected")
            menu.addItem(missing)
        }
        for (index, device) in keeper.devices.enumerated() {
            let item = NSMenuItem(title: device.name, action: #selector(selectDevice(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.state = device.uid == keeper.selectedUID ? .on : .off
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

        let about = NSMenuItem(title: "About KeepMacAudioAlive", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit KeepMacAudioAlive", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func headerItem() -> NSMenuItem {
        let status = status
        let dot = NSImageView(image: NSImage(size: NSSize(width: 8, height: 8), flipped: false) { rect in
            status.color.setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        })
        let title = NSTextField(labelWithString: status.title)
        title.font = .menuFont(ofSize: 0)
        let stack = NSStackView(views: [title])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        if !status.detail.isEmpty {
            let detail = NSTextField(labelWithString: status.detail)
            detail.font = .menuFont(ofSize: 11)
            detail.textColor = .secondaryLabelColor
            detail.lineBreakMode = .byTruncatingTail
            stack.addArrangedSubview(detail)
        }

        let view = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 38))
        for subview in [dot, stack] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            dot.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -14),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        let item = NSMenuItem()
        item.view = view
        return item
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
