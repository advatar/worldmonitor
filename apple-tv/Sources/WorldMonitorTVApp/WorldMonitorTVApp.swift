import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
import WorldMonitorTVClient

#if canImport(SwiftUI)
private let defaultTVBaseURL = "https://worldmonitor-finance.showntell.dev"

@main
struct WorldMonitorTVApplication: App {
  var body: some Scene {
    WindowGroup {
      DashboardScene()
    }
  }
}

struct DashboardScene: View {
  @StateObject private var model = WorldMonitorTVModel()
  @State private var selectedProfile: TVProfile = .full

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          header

          if let error = model.errorMessage {
            Text(error)
              .foregroundColor(.red)
              .padding()
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
          }

          profilePicker
            .disabled(model.isLoading)

          if model.isLoading && model.dashboard == nil {
            ProgressView("Loading modules")
          } else {
            moduleGrid
          }

          Spacer()
        }
        .padding()
      }
      .navigationTitle("WORLDMONITOR TV")
      .background(Color.black.opacity(0.95))
    }
    .onAppear {
      selectedProfile = model.profile
    }
    .task {
      await model.load()
      selectedProfile = model.profile
    }
    .onChange(of: selectedProfile) { newProfile in
      Task {
        await model.updateProfile(newProfile)
      }
    }
    .onDisappear {
      model.stopRefreshLoop()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("WORLDMONITOR TV")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundStyle(.white)

      Text("Base URL: \(model.baseURL)")
        .font(.caption)
        .foregroundStyle(.gray)

      HStack {
        if let lastUpdated = model.lastUpdated {
          Text("Last update: \(RelativeDateTimeFormatter().localizedString(for: lastUpdated, relativeTo: Date()))")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Button("Refresh now") {
          Task {
            await model.refresh()
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var profilePicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Profile")
        .font(.headline)
        .foregroundStyle(.secondary)

      Picker("Profile", selection: $selectedProfile) {
        ForEach(TVProfile.allCases, id: \.self) { profile in
          Text(profile.rawValue.capitalized).tag(profile)
        }
      }
      .pickerStyle(.segmented)
    }
  }

  private var moduleGrid: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 460), spacing: 16)], spacing: 16) {
      if model.moduleCards.isEmpty {
        Text("No modules available for this profile.")
          .foregroundStyle(.secondary)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
      } else {
        ForEach(model.moduleCards) { card in
          ModuleCard(card: card)
        }
      }
    }
  }
}

struct ModuleCard: View {
  let card: ModuleCardModel

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Text(card.name)
            .font(.title2)
            .fontWeight(.semibold)
          Text("Key: \(card.key)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Text(card.statusText)
          .font(.subheadline.weight(.bold))
          .foregroundStyle(card.ok ? .green : .orange)
      }

      Text(card.description)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)

      Text("Latency: \(card.latencyMs) ms")
        .font(.caption2)
        .foregroundStyle(.secondary)

      Text(card.payloadPreview)
        .font(.system(.caption, design: .monospaced))
        .foregroundStyle(.white)
        .lineLimit(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(16)
    .background(Color(.secondarySystemBackground).opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(card.ok ? .green.opacity(0.35) : .orange.opacity(0.35), lineWidth: 1)
    )
  }
}

@MainActor
final class WorldMonitorTVModel: ObservableObject {
  @Published var profile: TVProfile
  @Published var manifest: TVManifest?
  @Published var bootstrap: TVBootstrap?
  @Published var dashboard: TVDashboardResponse?
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var lastUpdated: Date?

  let baseURL: String
  let client: WorldMonitorTVClient
  private var refreshTask: Task<Void, Never>?

  init(baseURLString: String? = nil) {
    let configured = baseURLString
      ?? ProcessInfo.processInfo.environment["WORLDMONITOR_TV_BASE_URL"]
      ?? defaultTVBaseURL

    baseURL = configured

    if let client = try? WorldMonitorTVClient(baseURLString: configured) {
      self.client = client
    } else {
      self.client = try! WorldMonitorTVClient(baseURLString: defaultTVBaseURL)
    }

    self.profile = .full
  }

  var moduleCards: [ModuleCardModel] {
    guard let bootstrap = bootstrap else { return [] }

    return bootstrap.panelOrder.compactMap { key in
      guard let def = bootstrap.moduleManifest[key] else { return nil }
      guard let result = dashboard?.modules[key] else { return nil }

      return ModuleCardModel(
        key: key,
        name: def.name.isEmpty ? key : def.name,
        description: def.description,
        statusText: result.ok ? "OK" : "ERROR",
        latencyMs: result.latencyMs,
        ok: result.ok,
        payloadPreview: result.prettyPayloadPreview()
      )
    }
  }

  func load() async {
    await refresh()
  }

  func updateProfile(_ nextProfile: TVProfile) async {
    guard nextProfile != profile else {
      return
    }
    profile = nextProfile
    await refresh()
  }

  func refresh() async {
    isLoading = true
    defer { isLoading = false }

    do {
      if manifest == nil {
        manifest = try await client.fetchManifest()
      }
      let newBootstrap = try await client.fetchBootstrap(profile: profile)
      bootstrap = newBootstrap
      let newDashboard = try await client.fetchDashboard(
        profile: profile,
        modules: newBootstrap.selectedModules
      )
      dashboard = newDashboard
      lastUpdated = Date()
      errorMessage = nil

      startRefreshLoop(intervalSeconds: newBootstrap.refreshSeconds)
    } catch {
      errorMessage = error.localizedDescription
      isLoading = false
    }
  }

  private func startRefreshLoop(intervalSeconds: Int) {
    refreshTask?.cancel()
    guard intervalSeconds > 0 else { return }

    refreshTask = Task {
      while !Task.isCancelled {
        do {
          try await Task.sleep(for: .seconds(intervalSeconds))
        } catch {
          return
        }

        if Task.isCancelled {
          return
        }

        await refresh()
      }
    }
  }

  func stopRefreshLoop() {
    refreshTask?.cancel()
    refreshTask = nil
  }
}

struct ModuleCardModel: Identifiable {
  let key: String
  let name: String
  let description: String
  let statusText: String
  let latencyMs: Int
  let ok: Bool
  let payloadPreview: String

  var id: String { key }
}

private extension TVDashboardResponse.ModuleResult {
  func prettyPayloadPreview() -> String {
    guard ok else {
      return error ?? "No payload"
    }

    guard let data else {
      return "No payload"
    }

    return JSONFormatter.pretty(data, maxCharacters: 1800)
  }
}

private enum JSONFormatter {
  static func pretty(_ value: JSONValue, maxCharacters: Int) -> String {
    let rendered = render(value, indent: 0)

    if rendered.count <= maxCharacters {
      return rendered
    }

    return String(rendered.prefix(maxCharacters)) + "\n…"
  }

  static func render(_ value: JSONValue, indent: Int) -> String {
    let pad = String(repeating: " ", count: indent)
    let nextPad = String(repeating: " ", count: indent + 2)

    switch value {
    case .null:
      return "null"
    case .bool(let bool):
      return bool ? "true" : "false"
    case .number(let number):
      return String(describing: number)
    case .string(let string):
      return "\"\(string.replacingOccurrences(of: "\"", with: "\\\""))\""
    case .array(let items):
      guard !items.isEmpty else { return "[]" }
      var lines = ["["]
      for index in items.indices {
        let line = "\(nextPad)\(render(items[index], indent: indent + 2))"
        if index + 1 < items.count {
          lines.append("\(line),")
        } else {
          lines.append(line)
        }
      }
      lines.append("\(pad)]")
      return lines.joined(separator: "\n")
    case .object(let object):
      guard !object.isEmpty else { return "{}" }
      let keys = object.keys.sorted()
      var lines = ["{"]
      for (idx, key) in keys.enumerated() {
        let value = object[key] ?? .null
        let suffix = idx + 1 < keys.count ? "," : ""
        lines.append("\(nextPad)\"\(key)\": \(render(value, indent: indent + 2))\(suffix)")
      }
      lines.append("\(pad)}")
      return lines.joined(separator: "\n")
    }
  }
}

#endif
