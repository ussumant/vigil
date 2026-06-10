# Release Checklist

## Current Artifact

- App bundle: `dist/release/Vigil.app`
- Notarization ZIP: `dist/Vigil-1.0.0-notarization.zip`
- DMG: `dist/Vigil-1.0.0.dmg`
- Bundle ID: `dev.sumant.vigil`
- Signing identity: `Developer ID Application: Sumant Subrahmanya (9J372EUGY8)`

## Verified

- Generated Vigil eye icon source: `Assets/AppIcon-1024.png`
- App icon: `Resources/AppIcon.icns`
- Release build succeeds
- Developer ID signing succeeds with hardened runtime
- Signature verification succeeds
- Release app launches
- `auc-notary` profile works for Apple notarization
- Stapled app validates as `source=Notarized Developer ID`
- Stapled DMG validates as `source=Notarized Developer ID`

## Notarization

The current working notarytool profile is `auc-notary`.

Create one:

```sh
xcrun notarytool store-credentials "sumant-notary" \
  --apple-id "<apple-id>" \
  --team-id "9J372EUGY8" \
  --password "<app-specific-password>"
```

Then submit and staple:

```sh
NOTARY_PROFILE=auc-notary ./script/package_release.sh
```

## App Store Notes

Developer ID notarization is for direct distribution outside the Mac App Store. App Store submission still requires the App Store Connect flow, Apple Distribution signing/provisioning, screenshots, metadata, pricing, privacy answers, and manual review.

## Clamshell Override Note

Public IOKit assertions can prevent idle sleep but Apple documents that they may still sleep for lid close, Apple menu sleep, low battery, and other system sleep reasons. A true no-display clamshell override would require a separate privileged/direct-distribution approach and should not be marketed as part of the public-API build until that path is implemented and tested.
