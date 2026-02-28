import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
import WorldMonitorTVClient

#if canImport(SwiftUI)
private enum WorldMonitorTVSettings {
  static let defaultBaseURL = "https://worldmonitor-finance.showntell.dev"
  static let defaultProfile: TVProfile = .full
}

private enum RemoteHint {
  static let lines = [
    "▶ Select module to open detail",
    "↔/↑↓ Navigate cards with remote",
    "▶/⏯ Tap Play-Pause to pause auto-refresh",
    "↻ Refresh button: refresh dashboard",
    "↙ Back/Menu returns to dashboard"
  ]
}

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
  @State private var selectedProfile: TVProfile = WorldMonitorTVSettings.defaultProfile
  @FocusState private var focusedModuleIndex: Int?
  @State private var showRemoteHelp = false

  private let cardColumns = [GridItem(.adaptive(minimum: 560), spacing: 18)]

  var body: some View {
    NavigationStack {
      ZStack {
        ScrollView {
          VStack(spacing: 18) {
            header
            if let error = model.errorMessage {
              Text(error)
                .foregroundStyle(.red)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }

            profileBar

            dashboardControls

            moduleGrid

            Spacer(minLength: 32)
          }
          .padding(.horizontal, 40)
          .padding(.vertical, 24)
        }

        if showRemoteHelp {
          RemoteHintBanner {
            showRemoteHelp = false
          }
        }
      }
      .background(Color.black.opacity(0.96))
      .navigationTitle("WORLDMONITOR TV")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(true)
      .tint(.white)
      .navigationDestination(for: ModuleCardModel.self) { card in
        ModuleDetailView(card: card)
          .environmentObject(model)
      }
      .onAppear {
        selectedProfile = model.profile
      }
      .task {
        await model.load()
      }
      .onChange(of: model.moduleCards) { cards in
        if focusedModuleIndex == nil && !cards.isEmpty {
          focusedModuleIndex = 0
        }
      }
      .onChange(of: selectedProfile) { newProfile in
        Task {
          await model.updateProfile(newProfile)
        }
      }
      .onMoveCommand(perform: handleMoveCommand)
      .onPlayPauseCommand {
        model.toggleAutoRefresh()
      }
      .onExitCommand {
        if showRemoteHelp {
          showRemoteHelp = false
        }
      }
      .onDisappear {
        model.stopRefreshLoop()
      }
    }
  }

  private var header: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 6) {
        Text("WORLDMONITOR TV")
          .font(.system(size: 38, weight: .bold, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)

        Text("Backend: \(model.baseURL)")
          .font(.caption)
          .foregroundStyle(.secondary)

        if let lastUpdated = model.lastUpdated {
          Text("Updated: \(RelativeDateTimeFormatter().localizedString(for: lastUpdated, relativeTo: Date()))")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 6) {
        if model.isLoading {
          ProgressView()
            .scaleEffect(0.9)
        } else {
          Circle()
            .fill(model.isAutoRefreshEnabled ? Color.green : Color.orange)
            .frame(width: 12, height: 12)
        }

        Text(model.isAutoRefreshEnabled ? "AUTO-REFRESH" : "PAUSED")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(model.isAutoRefreshEnabled ? .green : .orange)
      }
    }
  }

  private var profileBar: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Profile")
        .font(.headline)
        .foregroundStyle(.secondary)

      Picker("Profile", selection: $selectedProfile) {
        ForEach(TVProfile.allCases, id: \.self) { profile in
          Text(profile.rawValue.capitalized)
            .tag(profile)
        }
      }
      .pickerStyle(.segmented)
      .disabled(model.isLoading)
    }
  }

  private var dashboardControls: some View {
    HStack(spacing: 12) {
      Button {
        Task {
          await model.refresh()
        }
      } label: {
        Label("Refresh", systemImage: "arrow.clockwise")
      }
      .buttonStyle(.borderedProminent)
      .tint(.blue)

      Button {
        model.toggleAutoRefresh()
      } label: {
        Label(model.isAutoRefreshEnabled ? "Pause refresh" : "Resume refresh", systemImage: model.isAutoRefreshEnabled ? "pause.circle" : "play.circle")
      }
      .buttonStyle(.borderedProminent)
      .tint(model.isAutoRefreshEnabled ? .orange : .green)

      Button {
        showRemoteHelp.toggle()
      } label: {
        Label("Remote help", systemImage: "questionmark.circle")
      }
      .buttonStyle(.bordered)
      .tint(.gray)

      Spacer()
    }
    .labelStyle(.titleAndIcon)
  }

  private var moduleGrid: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Modules")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundStyle(.white)

      if model.moduleCards.isEmpty {
        Text("No modules available yet. Pull refresh to retry.")
          .foregroundStyle(.secondary)
          .padding(18)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
      } else {
        LazyVGrid(columns: cardColumns, spacing: 18) {
          ForEach(Array(model.moduleCards.enumerated()), id: \.element.id) { index, card in
            NavigationLink(value: card) {
              ModuleCard(card: card, isFocused: focusedModuleIndex == index)
            }
            .buttonStyle(.plain)
            .focused($focusedModuleIndex, equals: index)
            .focusable()
            .onTapGesture {
              focusedModuleIndex = index
            }
          }
        }
        .focusSection()
      }
    }
    .padding(.vertical, 6)
  }

  private func handleMoveCommand(_ direction: MoveCommandDirection) {
    let cards = model.moduleCards
    guard !cards.isEmpty else { return }

    let current = max(0, focusedModuleIndex ?? 0)
    let last = cards.count - 1

    switch direction {
    case .left:
      focusedModuleIndex = max(0, current - 1)
    case .right:
      focusedModuleIndex = min(last, current + 1)
    case .up:
      focusedModuleIndex = max(0, current - 2)
    case .down:
      focusedModuleIndex = min(last, current + 2)
    @unknown default:
      break
    }
  }
}

struct ModuleCard: View {
  let card: ModuleCardModel
  let isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 10) {
        Text(card.name)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundStyle(.white)
          .lineLimit(2)

        Spacer()

        Text(card.statusText)
          .font(.subheadline.weight(.bold))
          .foregroundStyle(card.ok ? .green : .orange)
      }

      Text("Key: \(card.key)")
        .font(.caption)
        .foregroundStyle(.secondary)

      Text("Endpoint: \(card.endpoint)")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)

      Text(card.description)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)

      Divider()
        .background(.white.opacity(0.2))

      HStack {
        Text("Latency")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Text("\(card.latencyMs) ms")
          .font(.caption)
          .foregroundStyle(.white)
          .fontWeight(.semibold)
      }

      Text(card.payloadPreview)
        .font(.system(.caption, design: .monospaced))
        .foregroundStyle(.white.opacity(0.9))
        .lineLimit(8)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
    }
    .padding(16)
    .background(
      isFocused ?
      LinearGradient(
        colors: [Color(.darkGray).opacity(0.6), Color(.black).opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
      ) :
      Color(.secondarySystemBackground).opacity(0.16),
      in: RoundedRectangle(cornerRadius: 14)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(isFocused ? Color.white.opacity(0.7) : Color.white.opacity(0.12), lineWidth: isFocused ? 2 : 1)
    )
    .scaleEffect(isFocused ? 1.02 : 1.0)
    .animation(.easeInOut(duration: 0.12), value: isFocused)
  }
}

struct ModuleDetailView: View {
  let card: ModuleCardModel
  @EnvironmentObject private var model: WorldMonitorTVModel
  @State private var refreshingModule = false

  private var moduleResult: TVDashboardResponse.ModuleResult? {
    model.moduleResult(for: card.key)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        detailHeader

        HStack {
          Text("Endpoint")
            .font(.subheadline.weight(.bold))
          Text(card.endpoint)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        if let result = moduleResult {
          statusBanner(result)
          payloadView(result)
        } else {
          VStack(alignment: .leading, spacing: 10) {
            Text("No result available yet. Pull refresh in dashboard or retry this module.")
              .foregroundStyle(.secondary)
            Button {
              Task {
                refreshingModule = true
                await model.refreshSpecificModule(key: card.key)
                refreshingModule = false
              }
            } label: {
              if refreshingModule {
                ProgressView()
              } else {
                Label("Retry module", systemImage: "arrow.clockwise")
              }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
      }
      .padding(24)
      .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    .background(Color.black.opacity(0.95))
    .navigationTitle(card.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          Task {
            refreshingModule = true
            await model.refreshSpecificModule(key: card.key)
            refreshingModule = false
          }
        } label: {
          if refreshingModule {
            ProgressView()
          } else {
            Label("Refresh module", systemImage: "arrow.clockwise")
          }
        }
      }
    }
  }

  private var detailHeader: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(card.name)
        .font(.title)
        .fontWeight(.bold)
      Text(card.description)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(3)
      Text("Cache hint: \(card.cacheHint)")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private func statusBanner(_ result: TVDashboardResponse.ModuleResult) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Label(result.ok ? "Module healthy" : "Module error", systemImage: result.ok ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
          .foregroundStyle(result.ok ? .green : .orange)

        Spacer()

        Text("Latency: \(result.latencyMs)ms")
          .font(.subheadline.weight(.semibold))
      }
      .font(.headline)

      if let error = result.error {
        Text(error)
          .foregroundStyle(.orange)
          .font(.caption)
      }

      Text("Updated at: \(result.updatedAt)")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.secondarySystemBackground).opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
  }

  @ViewBuilder
  private func payloadView(_ result: TVDashboardResponse.ModuleResult) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Payload")
        .font(.headline)

      Text(result.prettyPayloadPreview())
        .font(.system(.caption, design: .monospaced))
        .foregroundStyle(.white)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }
  }
}

struct RemoteHintBanner: View {
  let onDismiss: () -> Void

  var body: some View {
    VStack {
      Spacer()
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Image(systemName: "sparkles")
          Text("Apple TV Controls")
            .font(.headline)
            .fontWeight(.bold)
          Spacer()
          Button {
            onDismiss()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
        ForEach(RemoteHint.lines, id: \.self) { line in
          Text(line)
            .font(.footnote)
        }
      }
      .padding(20)
      .frame(maxWidth: 640)
      .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
      .padding()
    }
  }
}

@MainActor
final class WorldMonitorTVModel: ObservableObject {
  @Published var profile: TVProfile
  @Published var manifest: TVManifest?
  @Published var bootstrap: TVBootstrap?
  @Published var dashboard: TVDashboardResponse?
  @Published var isLoading = false
  @Published var isAutoRefreshEnabled = true
  @Published var errorMessage: String?
  @Published var lastUpdated: Date?

  let baseURL: String
  let client: WorldMonitorTVClient
  private var refreshTask: Task<Void, Never>?

  init(baseURLString: String? = nil) {
    let configured = baseURLString
      ?? ProcessInfo.processInfo.environment["WORLDMONITOR_TV_BASE_URL"]
      ?? WorldMonitorTVSettings.defaultBaseURL

    baseURL = configured

    if let client = try? WorldMonitorTVClient(baseURLString: configured) {
      self.client = client
    } else {
      self.client = try! WorldMonitorTVClient(baseURLString: WorldMonitorTVSettings.defaultBaseURL)
    }

    self.profile = WorldMonitorTVSettings.defaultProfile
  }

  var moduleCards: [ModuleCardModel] {
    guard let bootstrap = bootstrap else { return [] }

    let moduleKeys = bootstrap.panelOrder.isEmpty ? bootstrap.selectedModules : bootstrap.panelOrder

    return moduleKeys.compactMap { key in
      guard let def = bootstrap.moduleManifest[key] else { return nil }
      let result = dashboard?.modules[key]

      let statusText = result?.statusText ?? "PENDING"
      let latencyMs = result?.latencyMs ?? 0
      let isOk = result?.ok ?? false
      let payloadPreview = result?.prettyPayloadPreview() ?? "No payload yet. Open module details and refresh this module."

      return ModuleCardModel(
        key: key,
        name: def.name.isEmpty ? key : def.name,
        description: def.description,
        statusText: statusText,
        latencyMs: latencyMs,
        ok: isOk,
        payloadPreview: payloadPreview,
        cacheHint: def.cacheHint,
        endpoint: def.endpoint
      )
    }
  }

  func load() async {
    await refresh()
  }

  func updateProfile(_ nextProfile: TVProfile) async {
    guard nextProfile != profile else { return }
    profile = nextProfile
    await refresh()
  }

  func refresh() async {
    await fetchAndApplyDashboard(modules: nil)
  }

  func refreshSpecificModule(key: String) async {
    await fetchAndApplyDashboard(modules: [key])
  }

  func moduleResult(for key: String) -> TVDashboardResponse.ModuleResult? {
    dashboard?.modules[key]
  }

  func toggleAutoRefresh() {
    isAutoRefreshEnabled.toggle()
    if isAutoRefreshEnabled {
      if let bootstrap {
        startRefreshLoop(intervalSeconds: bootstrap.refreshSeconds)
      }
    } else {
      stopRefreshLoop()
    }
  }

  private func fetchAndApplyDashboard(modules: [String]?) async {
    guard !isLoading else { return }
    isLoading = true
    defer { isLoading = false }

    do {
      if manifest == nil {
        manifest = try await client.fetchManifest()
      }

      let newBootstrap = try await client.fetchBootstrap(profile: profile)
      bootstrap = newBootstrap

      let requestedModules = modules ?? newBootstrap.selectedModules
      let newDashboard = try await client.fetchDashboard(
        profile: profile,
        modules: requestedModules
      )

      if let modules, modules.count == 1, let onlyKey = modules.first,
         var current = dashboard,
         let moduleResult = newDashboard.modules[onlyKey] {
        current.modules[onlyKey] = moduleResult
        dashboard = current
      } else {
        dashboard = newDashboard
      }

      lastUpdated = Date()
      errorMessage = nil

      if isAutoRefreshEnabled {
        startRefreshLoop(intervalSeconds: newBootstrap.refreshSeconds)
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func startRefreshLoop(intervalSeconds: Int) {
    refreshTask?.cancel()
    guard isAutoRefreshEnabled, intervalSeconds > 0 else { return }

    refreshTask = Task {
      while !Task.isCancelled {
        do {
          try await Task.sleep(for: .seconds(intervalSeconds))
        } catch {
          return
        }

        if Task.isCancelled || !isAutoRefreshEnabled {
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

struct ModuleCardModel: Identifiable, Hashable {
  let key: String
  let name: String
  let description: String
  let statusText: String
  let latencyMs: Int
  let ok: Bool
  let payloadPreview: String
  let cacheHint: String
  let endpoint: String

  var id: String { key }
}

private extension TVDashboardResponse.ModuleResult {
  var statusText: String {
    ok ? "OK" : "ERROR"
  }

  func prettyPayloadPreview() -> String {
    guard ok else { return error ?? "No payload" }
    guard let data else { return "No payload" }
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
