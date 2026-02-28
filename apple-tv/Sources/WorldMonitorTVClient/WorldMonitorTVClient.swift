import Foundation

public enum TVClientError: LocalizedError {
  case invalidBaseURL
  case invalidResponse
  case httpError(statusCode: Int)

  public var errorDescription: String? {
    switch self {
    case .invalidBaseURL:
      return "Base URL is invalid"
    case .invalidResponse:
      return "Received invalid response"
    case .httpError(let statusCode):
      return "HTTP error: \(statusCode)"
    }
  }
}

public final class WorldMonitorTVClient {
  private let baseURL: URL
  private let session: URLSession
  private let decoder: JSONDecoder

  public init(baseURL: URL, session: URLSession = .shared) {
    self.baseURL = baseURL
    self.session = session
    self.decoder = JSONDecoder()
    self.decoder.dateDecodingStrategy = .iso8601
  }

  public convenience init(baseURLString: String) throws {
    guard let url = URL(string: baseURLString) else {
      throw TVClientError.invalidBaseURL
    }
    self.init(baseURL: url)
  }

  public func fetchManifest() async throws -> TVManifest {
    let requestURL = baseURL.appendingPathComponent("api/tv/v1/manifest")
    let response = try await request(TVManifest.self, from: requestURL)
    return response
  }

  public func fetchBootstrap(
    profile: TVProfile,
    modules: [String]? = nil,
    region: String? = nil,
    sort: Bool = true
  ) async throws -> TVBootstrap {
    var url = baseURL.appendingPathComponent("api/tv/v1/bootstrap")
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    var queryItems: [URLQueryItem] = [URLQueryItem(name: "profile", value: profile.rawValue)]
    if let modules, !modules.isEmpty { queryItems.append(URLQueryItem(name: "modules", value: modules.joined(separator: ","))) }
    if let region { queryItems.append(URLQueryItem(name: "region", value: region)) }
    if sort { queryItems.append(URLQueryItem(name: "sort", value: "1")) }
    components?.queryItems = queryItems
    url = components?.url ?? url
    return try await request(TVBootstrap.self, from: url)
  }

  public func fetchDashboard(
    profile: TVProfile,
    modules: [String]? = nil,
    params: [String: String] = [:]
  ) async throws -> TVDashboardResponse {
    var url = baseURL.appendingPathComponent("api/tv/v1/dashboard")
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    var items = [URLQueryItem(name: "profile", value: profile.rawValue)]
    if let modules, !modules.isEmpty { items.append(URLQueryItem(name: "modules", value: modules.joined(separator: ","))) }
    params.forEach { items.append(URLQueryItem(name: $0.key, value: $0.value)) }
    components?.queryItems = items
    url = components?.url ?? url
    return try await request(TVDashboardResponse.self, from: url)
  }

  private func request<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
    let (data, response) = try await session.data(from: url)
    guard let http = response as? HTTPURLResponse else { throw TVClientError.invalidResponse }
    guard (200..<300).contains(http.statusCode) else { throw TVClientError.httpError(statusCode: http.statusCode) }
    return try decoder.decode(T.self, from: data)
  }
}
