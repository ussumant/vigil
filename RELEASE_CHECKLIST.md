# Release Checklist

## Current Artifact

- App bundle: `dist/release/Caffeinate.app`
- Notarization ZIP: `dist/Caffeinate-1.0.0-notarization.zip`
- Bundle ID: `dev.sumant.caffeinatebar`
- Signing identity: `Developer ID Application: Sumant Subrahmanya (9J372EUGY8)`

## Verified

- Generated coffee travel cup icon source: `Assets/AppIcon-1024.png`
- App icon: `Resources/AppIcon.icns`
- Release build succeeds
- Developer ID signing succeeds with hardened runtime
- Signature verification succeeds
- Release app launches

## Notarization

Notarization is blocked until a notarytool keychain profile exists.

Create one:

```sh
xcrun notarytool store-credentials "sumant-notary" \
  --apple-id "<apple-id>" \
  --team-id "9J372EUGY8" \
  --password "<app-specific-password>"
```

Then submit and staple:

```sh
NOTARYTOOL_PROFILE=sumant-notary ./script/package_release.sh
```

## App Store Notes

Developer ID notarization is for direct distribution outside the Mac App Store. App Store submission still requires the App Store Connect flow, Apple Distribution signing/provisioning, screenshots, metadata, pricing, privacy answers, and manual review.
