# AppleTV / tvOS Client Bootstrap (Phase 0)

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

## Next phase

Add a dedicated `WorldMonitorTVApp` target in Xcode (tvOS) and wire these calls into:

1. A TV-friendly home screen (top modules)
2. Module-specific card renderer
3. Profile switcher (`full` / `tech` / `finance` / `happy`)
4. Background refresh loop using `refreshSeconds`
5. Key/remote controls and focus behavior

## Next actions

- `cd apple-tv`
- `swift build`
- `swift run world-monitor-tv`
- Continue adding real UX:
  1. Home screen module cards
  2. TV-style remote/Focus controls
  3. Profile-specific theming and module deep-link pages
- Wire any production signing/profile settings into Xcode when packaging for store builds
