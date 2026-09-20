import Combine
import Foundation

public final class ComprehendlyClient: ObservableObject {
  public var publishableKey: String
  public var origin: String
  public var functionsUrl: String
  public var anonKey: String
  public var accessToken: String?
  public let store = FieldStore()

  public init(
    publishableKey: String,
    origin: String = "https://ios-demo.comprehendly.nz",
    functionsUrl: String = "https://api.stepcare.app/functions/v1",
    anonKey: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0cGFhdWh6dXFheGx1dXpqc2hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDkwMzE4NDUsImV4cCI6MjAyNDYwNzg0NX0.KY98XuoxMJAh-Qhb-_ozJzmFoOdI8ZcHqrFBNblf8fo"
  ) {
    self.publishableKey = publishableKey
    self.origin = origin
    self.functionsUrl = functionsUrl
    self.anonKey = anonKey
  }

  public func exchange() async throws {
    var req = URLRequest(url: URL(string: "\(functionsUrl)/integration_exchange")!)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue(origin, forHTTPHeaderField: "Origin")
    req.setValue(anonKey, forHTTPHeaderField: "apikey")
    req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    req.httpBody = try JSONSerialization.data(withJSONObject: [
      "key": publishableKey,
      "audience": "stepcare-embed",
      "requested_scopes": [
        "forms.schemas:read",
        "forms.submissions:read",
        "forms.submissions:write"
      ]
    ])
    let (data, res) = try await URLSession.shared.data(for: req)
    let http = res as? HTTPURLResponse
    let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    guard let http, (200 ..< 300).contains(http.statusCode) else {
      throw ComprehendlyError.http(http?.statusCode ?? 0, json["error"] as? String ?? "exchange failed")
    }
    accessToken = json["access_token"] as? String
  }

  public func gateway(_ operation: String, params: [String: Any] = [:]) async throws -> Any {
    if accessToken == nil { try await exchange() }
    var req = URLRequest(url: URL(string: "\(functionsUrl)/integration_gateway")!)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue(origin, forHTTPHeaderField: "Origin")
    req.setValue(anonKey, forHTTPHeaderField: "apikey")
    req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    req.httpBody = try JSONSerialization.data(withJSONObject: [
      "access_token": accessToken as Any,
      "operation": operation,
      "params": params
    ])
    let (data, res) = try await URLSession.shared.data(for: req)
    let http = res as? HTTPURLResponse
    let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    guard let http, (200 ..< 300).contains(http.statusCode) else {
      throw ComprehendlyError.http(http?.statusCode ?? 0, json["error"] as? String ?? "gateway failed")
    }
    return json["data"] ?? json
  }

  public func catalogList(parentId: String? = nil) async throws -> Any {
    var params: [String: Any] = [:]
    if let parentId { params["parent_id"] = parentId }
    return try await gateway("forms.catalog.list", params: params)
  }

  public func pageGet(_ pageId: String) async throws -> ComprehendlyPage {
    let data = try await gateway("forms.page.get", params: ["page_id": pageId])
    let page = ComprehendlyPage.parse(data)
    store.load(page)
    return page
  }

  public func sessionStart(pageId: String, mode: String = "silent") async throws -> Any {
    try await gateway("forms.voice.start", params: [
      "page_id": pageId,
      "session_mode": mode,
      "ui_consent_granted": true
    ])
  }
}
