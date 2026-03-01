// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "WorldMonitorTVClient",
  platforms: [
    .iOS(.v26),
    .tvOS(.v26),
    .macOS(.v26),
  ],
  products: [
    .library(
      name: "WorldMonitorTVClient",
      targets: ["WorldMonitorTVClient"]
    ),
    .executable(
      name: "world-monitor-tv",
      targets: ["WorldMonitorTVApp"]
    ),
  ],
  targets: [
    .target(
      name: "WorldMonitorTVClient",
      dependencies: [],
      path: "Sources/WorldMonitorTVClient"
    ),
    .executableTarget(
      name: "WorldMonitorTVApp",
      dependencies: ["WorldMonitorTVClient"],
      path: "Sources/WorldMonitorTVApp"
    ),
    .testTarget(
      name: "WorldMonitorTVClientTests",
      dependencies: ["WorldMonitorTVClient"],
      path: "Tests/WorldMonitorTVClientTests"
    ),
  ]
)
