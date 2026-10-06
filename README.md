# KeepMacAudioAlive
Keep Mac audio alive to prevent delays or pops with some DACs.

This is a fork of [openmac/KeepMacAudioAlive](https://github.com/openmac/KeepMacAudioAlive) by Ali Rastegar. It turns the original windowed app into a menu bar utility with a lower memory footprint (see [Credits](#credits)).

## How to use
1. Download the app from [releases](https://github.com/jd200172/KeepMacAudioAlive/releases), or build it with Xcode (see [How to build](#how-to-build)).
2. The release build is ad-hoc signed and not notarized. Follow the install steps in the release notes to allow it on macOS.
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
- **Ali Rastegar** created KeepMacAudioAlive and holds the original copyright (MIT License, see [LICENSE](LICENSE)). Original repository: [openmac/KeepMacAudioAlive](https://github.com/openmac/KeepMacAudioAlive).
- The original app and its icon were made using Gemini 3 Pro.
- **JIW** contributed to the original app: the UI improvements and launch at startup.
- The menu bar rewrite in this fork (AppKit status item, device state handling, sleep/wake handling, lower memory use) was implemented by Claude Sonnet 5.5, from Anthropic, using Claude Code.

Use it at your own risk.
