import Foundation

public enum TVProfile: String, CaseIterable, Codable, Sendable {
  case full
  case tech
  case finance
  case happy

  public var endpointValue: String { rawValue }
}

public struct TVManifest: Codable {
  public let schemaVersion: String
  public let generatedAt: String
  public let endpoints: Endpoints
  public let moduleDefs: [String: TVModuleDef]
  public let profiles: Profiles

  public struct Endpoints: Codable {
    public let bootstrap: String
    public let dashboard: String
  }

  public struct Profiles: Codable {
    public let ids: [String]
    public let details: [String: TVProfileConfig]
  }
}

public struct TVBootstrap: Codable {
  public let schemaVersion: String
  public let profile: String
  public let generatedAt: Int
  public let refreshSeconds: Int
  public let selectedModules: [String]
  public let moduleManifest: [String: TVModuleManifestItem]
  public let panelOrder: [String]
  public let mapLayers: [String: Bool]
  public let defaultRegion: String

  public struct TVModuleManifestItem: Codable {
    public let key: String
    public let name: String
    public let description: String
    public let cacheHint: String
    public let endpoint: String
  }
}

public struct TVModuleDef: Codable {
  public let key: String
  public let name: String
  public let description: String
  public let cacheHint: String
}

public struct TVProfileConfig: Codable {
  public let id: String
  public let displayName: String
  public let description: String
  public let panelOrder: [String]
  public let modules: [String]
  public let mapLayers: [String: Bool]
  public let defaultRegion: String
}

public struct TVDashboardResponse: Codable {
  public let schemaVersion: String
  public let status: String
  public let generatedAt: String
  public let profile: String
  public let region: String
  public var modules: [String: ModuleResult]

  public struct ModuleResult: Codable {
    public let status: String
    public let ok: Bool
    public let data: JSONValue?
    public let error: String?
    public let latencyMs: Int
    public let updatedAt: String
  }
}

public enum JSONValue: Codable {
  case object([String: JSONValue])
  case array([JSONValue])
  case string(String)
  case number(Double)
  case bool(Bool)
  case null

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(Double.self) {
      self = .number(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode([String: JSONValue].self) {
      self = .object(value)
    } else if let value = try? container.decode([JSONValue].self) {
      self = .array(value)
    } else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .null:
      try container.encodeNil()
    case .bool(let value):
      try container.encode(value)
    case .number(let value):
      try container.encode(value)
    case .string(let value):
      try container.encode(value)
    case .object(let value):
      try container.encode(value)
    case .array(let value):
      try container.encode(value)
    }
  }
}
