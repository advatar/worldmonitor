# AppleTV / tvOS Client Bootstrap (Phase 1)

This folder contains a reusable Swift package for consuming the new `api/tv/v1/*` endpoints.

## What is included

- `Package.swift` (SwiftPM package definition)
- `Sources/WorldMonitorTVClient/WorldMonitorTVClient.swift` (HTTP client)
- `Sources/WorldMonitorTVClient/Models.swift` (shared models + JSON compatibility types)

## Quick usage

```swift
import WorldMonitorTVClient

let client = try WorldMonitorTVClient(baseURLString: "https://worldmonitor-finance.showntell.dev")

let manifest = try await client.fetchManifest()
let bootstrap = try await client.fetchBootstrap(profile: .full)
let dashboard = try await client.fetchDashboard(profile: .full, modules: bootstrap.selectedModules)
```

## API contract this client targets

- `GET /api/tv/v1/manifest`
- `GET /api/tv/v1/bootstrap?profile={full|tech|finance|happy}&modules=...`
- `GET /api/tv/v1/dashboard?profile={...}&modules=...`

# Current status

This client and app are now implemented in:

- `apple-tv/Sources/WorldMonitorTVClient/*` (API model + client)
- `apple-tv/Sources/WorldMonitorTVApp/WorldMonitorTVApp.swift` (tvOS SwiftUI shell)

## Platform features

- Profile switching (`full` / `tech` / `finance` / `happy`)
- Focus-aware module cards
- Module detail route
- Remote controls (`Play/Pause` toggles auto-refresh, `Back/Menu` clears overlays)
- Dashboard auto-refresh driven by `refreshSeconds`
- Per-module refresh + payload preview

## Next actions

- `cd apple-tv`
- `swift build`
- `swift run world-monitor-tv`
- Open the package in Xcode:

  1. Xcode ➜ **Open** `apple-tv/` as a Swift package.
  2. Choose scheme `world-monitor-tv` and destination `Apple TV`.
  3. Configure Signing (`Bundle Identifier`, team, provisioning) in target settings if needed.
  4. Press run to test on simulator/device.

- Current tvOS app shell now includes:
  - Profile switching (`full` / `tech` / `finance` / `happy`)
  - Module cards with focus handling
  - Module detail route
  - Remote hints (Play/Pause pauses refresh; menu/back/exit closes overlay)
  - Auto refresh using `refreshSeconds` from bootstrap

- Recommended next steps
  - Add signing-capable Xcode wrapper + `Assets.xcassets` via `apple-tv/XCODE_SHELL`
  - Add App Store-level CI for archive validation
  - Add endpoint-specific detail renderers where full charts/maps are needed

## Rebase-friendly update workflow

Use `npm run sync:upstream:deploy` to:

1. Rebase onto `origin/main`
2. Preserve local files by auto-stashing
3. Deploy directly to Vercel if the rebase is clean
