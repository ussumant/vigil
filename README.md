# Vigil

A tiny open-source macOS menu bar app for keeping the machine awake during long-running work.

![Vigil app icon](Assets/AppIcon-1024.png)
![Vigil nocturnal background](Assets/Brand/vigil-nocturnal-background.png)

Click the eye in the menu bar and toggle **Enable Wakelock**. While enabled, the app uses native IOKit power assertions to prevent idle display sleep and idle system sleep.

macOS public power assertions may still sleep for lid close, Apple menu sleep, low battery, and other system sleep reasons. True no-display clamshell override without an external display is not available through the public IOKit assertion API alone.

## Features

- Menu bar only, no persistent window
- Native IOKit power assertions
- State-aware menu bar icon: open eye when active, closed/slashed eye when inactive
- Battery guard with configurable auto-disable threshold
- Launch-at-login toggle in the menu
- Minimal commands: `Enable Wakelock`, `Disable Wakelock`, `Quit`
- Branded AppKit popover with bundled Syne, Inter, and JetBrains Mono fonts
- Geometric Vigil eye app icon
- SwiftPM build, test, run, and release scripts

## Build and Run

```sh
./script/build_and_run.sh
```

The built app bundle is staged at `dist/Vigil.app`.

## Test

```sh
swift test
```

## Package

```sh
./script/package_release.sh
```

The release script builds the Vigil eye icon, stages `dist/release/Vigil.app`, signs it with the configured Developer ID identity, verifies the signature, and creates:

- `dist/Vigil-1.0.0-notarization.zip`
- `dist/Vigil-1.0.0.dmg`

Set `NOTARY_PROFILE=auc-notary` or `NOTARYTOOL_PROFILE=<profile>` to submit and staple notarization.

## Homebrew Cask

A cask template lives at `packaging/homebrew/vigil.rb`. Replace the release URL/checksum after publishing a notarized DMG.

## Privacy

Vigil does not collect analytics, store user data, or make network requests.

## License

MIT
