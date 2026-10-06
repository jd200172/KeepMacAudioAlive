# KeepMacAudioAlive
Keep Mac audio alive to prevent delays or pops with some DACs.

## How to use
1. Download the app from [releases](https://github.com/openmac/KeepMacAudioAlive/releases).
2. Allow the app to run via security settings on macOS settings, or build the app yourself using Xcode.
3. Open the app. It lives in the menu bar (no Dock icon or window) and starts sending digital silence to the last used output device, or to the system default on first run.
4. Click the menu bar icon to:
   - **Stop / Start** the silence stream (⌘S). A manual stop is kept until you click Start.
   - **Switch the output device.** While running, the stream moves to the new device.
   - Enable **Launch at Login**.

If the selected device is unplugged, the app waits and resumes by itself when it comes back. It also releases the device while the Mac sleeps and restarts it on wake.

The app is idle between events: no timers or polling, only the audio callback while the stream is running.


## How to build
If you want to build it yourself:
1. Download the source code from this repository.
2. Download and install Xcode.
3. Open KeepMacAudioAlive.xcodeproj on Xcode.
4. Set your own signing profile.
5. Build or Run.

## Credits
This app and even its icon was made using Gemini 3 Pro, so all credits to them, and use it at your own risk.
