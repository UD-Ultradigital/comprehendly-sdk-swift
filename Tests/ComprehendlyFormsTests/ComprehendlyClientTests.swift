import XCTest
@testable import ComprehendlyForms

final class ComprehendlyClientTests: XCTestCase {
  override class func setUp() {
    super.setUp()
    URLProtocol.registerClass(MockURLProtocol.self)
  }

  override class func tearDown() {
    URLProtocol.unregisterClass(MockURLProtocol.self)
    super.tearDown()
  }

  override func tearDown() {
    MockURLProtocol.requestHandler = nil
    super.tearDown()
  }

  func testSubmissionsSaveUsesFieldNameValuesPayload() async throws {
    let client = ComprehendlyClient(
      publishableKey: "pk_test_123",
      functionsUrl: "https://example.com/functions/v1",
      anonKey: "anon"
    )
    client.accessToken = "token"

    MockURLProtocol.requestHandler = { request in
      XCTAssertEqual(request.url?.absoluteString, "https://example.com/functions/v1/integration_gateway")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Origin"), "https://ios-demo.comprehendly.nz")

      let body = try XCTUnwrap(request.httpBody)
      let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
      XCTAssertEqual(json["operation"] as? String, "forms.submissions.save")

      let params = try XCTUnwrap(json["params"] as? [String: Any])
      let payload = try XCTUnwrap(params["payload"] as? [String: Any])
      XCTAssertEqual(payload["page_id"] as? String, "page-123")
      XCTAssertNil(payload["title"])

      let fieldValues = try XCTUnwrap(payload["field_values"] as? [String: Any])
      XCTAssertEqual(fieldValues["mood"] as? String, "ok")
      XCTAssertEqual(fieldValues["notes"] as? String, "Ready")
      XCTAssertEqual(fieldValues["consent"] as? Bool, true)

      return (
        HTTPURLResponse(
          url: try XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!,
        try JSONSerialization.data(withJSONObject: ["data": ["submission_id": "sub_123"]])
      )
    }

    let response = try await client.submissionsSave(
      pageId: "page-123",
      fieldValues: ["mood": "ok", "notes": "Ready", "consent": true]
    )

    let data = try XCTUnwrap(response as? [String: Any])
    XCTAssertEqual(data["submission_id"] as? String, "sub_123")
  }

  func testSubmissionsSaveIncludesOptionalTitle() async throws {
    let client = ComprehendlyClient(
      publishableKey: "pk_test_123",
      functionsUrl: "https://example.com/functions/v1",
      anonKey: "anon"
    )
    client.accessToken = "token"

    MockURLProtocol.requestHandler = { request in
      let body = try XCTUnwrap(request.httpBody)
      let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
      let params = try XCTUnwrap(json["params"] as? [String: Any])
      let payload = try XCTUnwrap(params["payload"] as? [String: Any])
      XCTAssertEqual(payload["title"] as? String, "Triage intake")

      return (
        HTTPURLResponse(
          url: try XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!,
        try JSONSerialization.data(withJSONObject: ["data": [:]])
      )
    }

    _ = try await client.submissionsSave(
      pageId: "page-123",
      fieldValues: ["mood": "ok"],
      title: "Triage intake"
    )
  }
}

private final class MockURLProtocol: URLProtocol {
  static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let handler = Self.requestHandler else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
