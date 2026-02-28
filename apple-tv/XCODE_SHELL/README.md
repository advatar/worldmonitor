# Xcode Shell Assets for World Monitor TV

This folder contains the launch + bundle templates you can drop into an Xcode tvOS app shell target.

## Included

- `LaunchScreen.storyboard`
- `WorldMonitorTV-Info.plist`
- `WorldMonitorTV.entitlements`
- `Assets.xcassets/` with `AccentColor`
- `Assets.xcassets/AppIcon.appiconset/` with placeholder TV icon files

## How to use

1. In Xcode, open the `apple-tv` package as a project (`File` ➜ `Open` ➜ `Package.swift`).
2. Duplicate this directory contents into a dedicated Xcode wrapper project if you need App Store signing assets.
3. Point your tvOS target settings:
   - **Info.plist File**: `WorldMonitorTV-Info.plist`
   - **Signing & Capabilities**: attach your team + profile
   - **App Icon Set Name**: `AppIcon`
   - **Launch Screen File**: `LaunchScreen`

   The icon files in `Assets.xcassets/AppIcon.appiconset/` are placeholders. Replace them with your production art at the same filename before signing.
4. Replace `CFBundleIdentifier` with your production identifier.
5. Run on Apple TV simulator first, then device.

## Reminder

`WorldMonitorTV.entitlements` is intentionally minimal. Add keys only when you enable optional capabilities (CloudKit, App Groups, Apple Push, etc.).
