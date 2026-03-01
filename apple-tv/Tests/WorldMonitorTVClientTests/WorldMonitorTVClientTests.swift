import XCTest
import Foundation
@testable import WorldMonitorTVClient

final class WorldMonitorTVClientTests: XCTestCase {
  override func setUp() {
    super.setUp()
    MockURLProtocol.requestHandler = nil
  }

  private func makeClient(baseURLString: String = "https://worldmonitor.example") throws -> WorldMonitorTVClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: config)
    let baseURL = try XCTUnwrap(URL(string: baseURLString))
    return WorldMonitorTVClient(baseURL: baseURL, session: session)
  }

  func testFetchManifest() async throws {
    MockURLProtocol.requestHandler = { request in
      guard let url = request.url else {
        throw URLError(.badURL)
      }

      XCTAssertEqual(url.absoluteString, "https://worldmonitor.example/api/tv/v1/manifest")

      let payload = """
      {
        "schemaVersion": "1.0.0",
        "generatedAt": "2026-03-01T00:00:00Z",
        "endpoints": {
          "bootstrap": "/api/tv/v1/bootstrap",
          "dashboard": "/api/tv/v1/dashboard"
        },
        "moduleDefs": {
          "riskPulse": {
            "key": "riskPulse",
            "name": "Strategic Risk",
            "description": "Test module",
            "cacheHint": "short"
          }
        },
        "profiles": {
          "ids": ["full", "tech", "finance", "happy"],
          "details": {
            "full": {
              "id": "full",
              "displayName": "Global Intelligence",
              "description": "Full coverage",
              "panelOrder": ["riskPulse"],
              "modules": ["riskPulse"],
              "mapLayers": {"conflicts": true},
              "defaultRegion": "global"
            }
          }
        }
      }
      """

      let data = Data(payload.utf8)
      guard let response = HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      ) else {
        throw URLError(.badServerResponse)
      }
      return (response, data)
    }

    let client = try makeClient()
    let manifest = try await client.fetchManifest()

    XCTAssertEqual(manifest.schemaVersion, "1.0.0")
    XCTAssertEqual(manifest.generatedAt, "2026-03-01T00:00:00Z")
    XCTAssertEqual(manifest.endpoints.bootstrap, "/api/tv/v1/bootstrap")
    XCTAssertEqual(manifest.moduleDefs["riskPulse"]?.name, "Strategic Risk")
    XCTAssertEqual(manifest.profiles.ids, ["full", "tech", "finance", "happy"])
  }

  func testFetchBootstrapIncludesModulesAndRegion() async throws {
    MockURLProtocol.requestHandler = { request in
      guard let url = request.url else {
        throw URLError(.badURL)
      }

      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      let query = Dictionary<String, String>(uniqueKeysWithValues: components?.queryItems?.compactMap { item in
        guard let value = item.value else { return nil }
        return (item.name, value)
      } ?? [])

      XCTAssertEqual(query["profile"], "finance")
      XCTAssertEqual(query["modules"], "riskPulse,cyberThreats")
      XCTAssertEqual(query["region"], "eu")
      XCTAssertEqual(query["sort"], "1")

      let payload = """
      {
        "schemaVersion": "1.0.0",
        "profile": "finance",
        "generatedAt": 1700000000000,
        "refreshSeconds": 30,
        "selectedModules": ["riskPulse", "cyberThreats"],
        "moduleManifest": {
          "riskPulse": {
            "key": "riskPulse",
            "name": "Strategic Risk",
            "description": "Test",
            "cacheHint": "short",
            "endpoint": "/api/tv/v1/dashboard"
          },
          "cyberThreats": {
            "key": "cyberThreats",
            "name": "Cyber Threats",
            "description": "Test",
            "cacheHint": "medium",
            "endpoint": "/api/tv/v1/dashboard"
          }
        },
        "panelOrder": ["riskPulse", "cyberThreats"],
        "mapLayers": {"conflicts": true},
        "defaultRegion": "global"
      }
      """

      guard let response = HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      ) else {
        throw URLError(.badServerResponse)
      }
      return (response, Data(payload.utf8))
    }

    let client = try makeClient()
    _ = try await client.fetchBootstrap(
      profile: .finance,
      modules: ["riskPulse", "cyberThreats"],
      region: "eu"
    )
  }

  func testFetchDashboardIncludesProfileAndModules() async throws {
    MockURLProtocol.requestHandler = { request in
      guard let url = request.url else {
        throw URLError(.badURL)
      }

      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      let query = Dictionary<String, String>(uniqueKeysWithValues: components?.queryItems?.compactMap { item in
        guard let value = item.value else { return nil }
        return (item.name, value)
      } ?? [])

      XCTAssertEqual(query["profile"], "tech")
      XCTAssertEqual(query["modules"], "riskPulse,macroSignals")
      XCTAssertEqual(query["pageSize"], "100")

      let payload = """
      {
        "schemaVersion": "1.0.0",
        "status": "ok",
        "generatedAt": "2026-03-01T00:00:00Z",
        "profile": "tech",
        "region": "global",
        "modules": {
          "riskPulse": {
            "status": "ok",
            "ok": true,
            "data": {
              "score": 5
            },
            "error": null,
            "latencyMs": 12,
            "updatedAt": "2026-03-01T00:00:00Z"
          }
        }
      }
      """

      guard let response = HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      ) else {
        throw URLError(.badServerResponse)
      }
      return (response, Data(payload.utf8))
    }

    let client = try makeClient()
    let dashboard = try await client.fetchDashboard(
      profile: .tech,
      modules: ["riskPulse", "macroSignals"],
      params: ["pageSize": "100"]
    )

    XCTAssertEqual(dashboard.status, "ok")
    XCTAssertNotNil(dashboard.modules["riskPulse"])
  }

  func testFetchDashboardPropagatesHTTPError() async throws {
    MockURLProtocol.requestHandler = { request in
      guard let url = request.url else {
        throw URLError(.badURL)
      }

      guard let response = HTTPURLResponse(
        url: url,
        statusCode: 500,
        httpVersion: nil,
        headerFields: nil
      ) else {
        throw URLError(.badServerResponse)
      }
      return (response, Data("service unavailable".utf8))
    }

    do {
      _ = try await makeClient().fetchDashboard(profile: .full)
      XCTFail("Expected fetchDashboard to throw")
    } catch {
      guard let clientError = error as? TVClientError else {
        return XCTFail("Unexpected error type: \(error)")
      }

      guard case .httpError(let code) = clientError else {
        return XCTFail("Expected httpError but got: \(clientError)")
      }
      XCTAssertEqual(code, 500)
    }
  }

  func testJSONValueDecodingAndEncoding() throws {
    let payload = """
    {
      "array": [true, null, 3.14, "ok"],
      "nested": {"ok": false}
    }
    """

    let data = Data(payload.utf8)
    let decoded = try JSONDecoder().decode([String: JSONValue].self, from: data)
    guard case .array(let array) = decoded["array"] else {
      return XCTFail("Expected array")
    }
    guard case .bool(false) = decoded["nested"]?.objectValue["ok"] else {
      return XCTFail("Expected nested bool")
    }
    XCTAssertEqual(array.count, 4)

    let encoded = try JSONEncoder().encode(decoded)
    let redecoded = try JSONDecoder().decode([String: JSONValue].self, from: encoded)
    XCTAssertNotNil(redecoded["array"])
  }
}

private extension JSONValue {
  var objectValue: [String: JSONValue] {
    if case .object(let value) = self { return value }
    return [:]
  }
}
