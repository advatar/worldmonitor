# Apple TV Xcode Shell Setup (Package-based)

This project is a SwiftPM tvOS app target (`world-monitor-tv`) and can be run from Xcode without a separate `.xcodeproj`.

## 1) Add app icons and launch resources

1. In Xcode, create a new tvOS-focused app shell project (or add an Xcode package scheme target wrapper).
2. Add an asset catalog `Assets.xcassets` with:
   - `AppIcon` app icon set for tvOS
   - Optional `LaunchImage` / storyboard if you use static launch screen
3. Create a launch storyboard (`LaunchScreen.storyboard`) with a single full-screen branded view.
4. Point target “App Icon Set Name” and “Launch Screen File” in target settings.

## 2) Run / package

- Run on simulator: pick your `Apple TV` destination and execute the `world-monitor-tv` scheme.
- For device/ad-hoc/App Store:
  - Set bundle ID in target capabilities
  - Configure team + provisioning profile
  - Archive and submit normally from Xcode

## 3) Optional polish hooks already present

- Remote controls: Play/Pause toggles auto-refresh
- Remote hints overlay
- Module card focus ring and keyboard/remote movement handling
- Module detail route for endpoint-level inspection

