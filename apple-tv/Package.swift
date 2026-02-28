// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "WorldMonitorTVClient",
  platforms: [
    .iOS(.v17),
    .tvOS(.v17),
    .macOS(.v13),
  ],
  products: [
    .library(
      name: "WorldMonitorTVClient",
      targets: ["WorldMonitorTVClient"]
    ),
  ],
  targets: [
    .target(
      name: "WorldMonitorTVClient",
      dependencies: [],
      path: "Sources/WorldMonitorTVClient"
    ),
  ]
)
