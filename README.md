# Caffeinate

A tiny open-source macOS menu bar app for keeping the machine awake.

![Caffeinate app icon](Assets/AppIcon-1024.png)

Click the bolt in the menu bar and choose **Keep Awake**. While enabled, the app uses native IOKit power assertions to prevent idle display sleep, idle system sleep, and supported system sleep.

macOS may still enforce hardware lid-close sleep on some MacBooks. The system-sleep assertion is strongest when the Mac is on AC power and in a supported clamshell setup.

## Features

- Menu bar only, no persistent window
- Native IOKit power assertions
- Minimal toggle: `Keep Awake`, `Stop Keeping Awake`, `Quit`
- Generated coffee travel cup app icon
- SwiftPM build, test, run, and release scripts

## Build and Run

```sh
./script/build_and_run.sh
```

The built app bundle is staged at `dist/Caffeinate.app`.

## Test

```sh
swift test
```

## Package

```sh
./script/package_release.sh
```

The release script builds the generated coffee-cup icon, stages `dist/release/Caffeinate.app`, signs it with the configured Developer ID identity, verifies the signature, and creates `dist/Caffeinate-1.0.0-notarization.zip`.

Set `NOTARYTOOL_PROFILE` to a configured `xcrun notarytool` keychain profile to submit and staple notarization.

## Privacy

Caffeinate does not collect analytics, store user data, or make network requests.

## License

MIT
