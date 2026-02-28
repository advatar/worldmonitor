# Xcode Shell Assets for World Monitor TV

This folder contains the launch + bundle templates you can drop into an Xcode tvOS app shell target.

## Included

- `LaunchScreen.storyboard`
- `WorldMonitorTV-Info.plist`
- `WorldMonitorTV.entitlements`
- `Assets.xcassets/` with `AccentColor`
- (No AppIcon PNGs are included; add your own icon set in the Xcode target)

## How to use

1. In Xcode, open the `apple-tv` package as a project (`File` ➜ `Open` ➜ `Package.swift`).
2. Duplicate this directory contents into a dedicated Xcode wrapper project if you need App Store signing assets.
3. Point your tvOS target settings:
   - **Info.plist File**: `WorldMonitorTV-Info.plist`
   - **Signing & Capabilities**: attach your team + profile
   - **App Icons / Launch Screen**: create an App Icon set, then set `LaunchScreen.storyboard` as launch file
4. Replace `CFBundleIdentifier` with your production identifier.
5. Run on Apple TV simulator first, then device.

## Reminder

`WorldMonitorTV.entitlements` is intentionally minimal. Add keys only when you enable optional capabilities (CloudKit, App Groups, Apple Push, etc.).
