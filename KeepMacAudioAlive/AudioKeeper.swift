import AppKit
import CoreAudio
import os

/// Plays digital silence on the selected output device so DACs never go idle.
///
/// State is derived from three inputs: whether the user wants audio running, which device is selected,
/// and which devices exist. `reconcile()` is the only place that starts or stops the IOProc.
final class AudioKeeper {
    enum State {
        case running
        case stopped
        /// The user wants audio running but the selected device is not connected.
        case waiting
    }

    private static let log = Logger(subsystem: "com.github.openmac.KeepMacAudioAlive", category: "Audio")

    private(set) var state: State = .stopped
    private(set) var devices: [AudioDevice] = []
    private(set) var selectedUID: String?
    private(set) var selectedName: String?

    /// Called on the main thread after every state, device, or selection change.
    var onChange: (() -> Void)?

    private var wantsRunning = Preferences.wantsRunning ?? true
    private var isSleeping = false
    private var ioProcID: AudioDeviceIOProcID?
    private var activeDeviceID: AudioDeviceID?

    init() {
        selectedUID = Preferences.selectedDeviceUID
        selectedName = Preferences.selectedDeviceName
        devices = CoreAudioDevices.outputDevices()

        if selectedUID == nil, let uid = CoreAudioDevices.defaultOutputDeviceUID(),
           let device = devices.first(where: { $0.uid == uid }) {
            remember(device)
        }

        CoreAudioDevices.addDeviceListListener { [weak self] _, _ in
            MainActor.assumeIsolated { self?.devicesDidChange() }
        }

        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isSleeping = true
                self?.reconcile()
            }
        }
        center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isSleeping = false
                self?.reconcile()
            }
        }

        reconcile()
    }

    // MARK: - Commands

    func start() {
        wantsRunning = true
        Preferences.wantsRunning = true
        reconcile()
    }

    func stop() {
        wantsRunning = false
        Preferences.wantsRunning = false
        reconcile()
    }

    func select(_ device: AudioDevice) {
        remember(device)
        reconcile()
    }

    func shutdown() {
        wantsRunning = false
        teardown()
    }

    // MARK: - State

    private func devicesDidChange() {
        devices = CoreAudioDevices.outputDevices()
        reconcile()
    }

    private func remember(_ device: AudioDevice) {
        selectedUID = device.uid
        selectedName = device.name
        Preferences.saveSelection(uid: device.uid, name: device.name)
    }

    private func reconcile() {
        let target = devices.first { $0.uid == selectedUID }
        if let target, target.name != selectedName {
            remember(target)
        }

        if !wantsRunning {
            teardown()
            state = .stopped
        } else if isSleeping {
            teardown()
        } else if let target {
            if activeDeviceID != target.id {
                teardown()
                if startIO(on: target) {
                    state = .running
                } else {
                    wantsRunning = false
                    state = .stopped
                }
            } else {
                state = .running
            }
        } else {
            teardown()
            state = .waiting
        }

        onChange?()
    }

    // MARK: - IOProc

    private func startIO(on device: AudioDevice) -> Bool {
        var procID: AudioDeviceIOProcID?
        let createStatus = AudioDeviceCreateIOProcID(device.id, silenceIOProc, nil, &procID)
        guard createStatus == noErr, let procID else {
            Self.log.error("Could not create IOProc on \(device.name): \(createStatus)")
            return false
        }

        let startStatus = AudioDeviceStart(device.id, procID)
        guard startStatus == noErr else {
            Self.log.error("Could not start \(device.name): \(startStatus)")
            AudioDeviceDestroyIOProcID(device.id, procID)
            return false
        }

        ioProcID = procID
        activeDeviceID = device.id
        return true
    }

    private func teardown() {
        guard let deviceID = activeDeviceID, let procID = ioProcID else { return }
        AudioDeviceStop(deviceID, procID)
        AudioDeviceDestroyIOProcID(deviceID, procID)
        ioProcID = nil
        activeDeviceID = nil
    }
}

/// Runs on the real-time audio thread: no allocation, no locks, no Swift runtime calls beyond the loop.
private nonisolated func silenceIOProc(
    _ device: AudioObjectID,
    _ now: UnsafePointer<AudioTimeStamp>,
    _ inputData: UnsafePointer<AudioBufferList>,
    _ inputTime: UnsafePointer<AudioTimeStamp>,
    _ outputData: UnsafeMutablePointer<AudioBufferList>,
    _ outputTime: UnsafePointer<AudioTimeStamp>,
    _ clientData: UnsafeMutableRawPointer?
) -> OSStatus {
    for buffer in UnsafeMutableAudioBufferListPointer(outputData) {
        if let data = buffer.mData {
            memset(data, 0, Int(buffer.mDataByteSize))
        }
    }
    return noErr
}
