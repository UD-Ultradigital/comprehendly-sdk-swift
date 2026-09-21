import Foundation
import XCTest
@testable import ComprehendlyForms

final class ComprehendlyClientTests: XCTestCase {
  func testSubmissionsSaveSendsPayload() async throws {
    let testID = UUID().uuidString
    let session = makeSession(testID: testID)
    let client = ComprehendlyClient(
      publishableKey: "pk_test_123",
      functionsUrl: "https://example.test/functions/v1",
      anonKey: "anon",
      session: session
    )

    let recorder = RequestRecorder()
    MockURLProtocol.install(
      testID: testID,
      requestHandler: { request in
        if request.url?.path.hasSuffix("/integration_exchange") == true {
          return .ok(["access_token": "token_123"])
        }
        return .ok(["data": ["id": "sub_123"]])
      },
      requestObserver: { recorder.append($0) }
    )
    defer { MockURLProtocol.remove(testID: testID) }

    let data = try await client.submissionsSave(
      pageId: "page_123",
      fieldValues: ["mood": "ok"],
      title: "My submission"
    )

    let payload = (data as? [String: Any])?["id"] as? String
    XCTAssertEqual(payload, "sub_123")
    let requests = recorder.all()
    XCTAssertEqual(requests.count, 2)
    XCTAssertEqual(requests.first?.url?.path, "/functions/v1/integration_exchange")
    XCTAssertEqual(requests.last?.url?.path, "/functions/v1/integration_gateway")

    let bodyData = try XCTUnwrap(bodyData(from: requests[1]))
    let body = try XCTUnwrap(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
    XCTAssertEqual(body["operation"] as? String, "forms.submissions.save")

    let params = try XCTUnwrap(body["params"] as? [String: Any])
    let requestPayload = try XCTUnwrap(params["payload"] as? [String: Any])
    XCTAssertEqual(requestPayload["page_id"] as? String, "page_123")
    XCTAssertEqual((requestPayload["field_values"] as? [String: String])?["mood"], "ok")
    XCTAssertEqual(requestPayload["title"] as? String, "My submission")
  }

  func testSubmissionsSaveOmitsNilTitle() async throws {
    let testID = UUID().uuidString
    let session = makeSession(testID: testID)
    let client = ComprehendlyClient(
      publishableKey: "pk_test_123",
      functionsUrl: "https://example.test/functions/v1",
      anonKey: "anon",
      session: session
    )
    client.accessToken = "token_123"

    let recorder = RequestRecorder()
    MockURLProtocol.install(
      testID: testID,
      requestHandler: { _ in .ok(["data": ["id": "sub_123"]]) },
      requestObserver: { recorder.append($0) }
    )
    defer { MockURLProtocol.remove(testID: testID) }

    _ = try await client.submissionsSave(pageId: "page_123", fieldValues: ["mood": "ok"])

    let requests = recorder.all()
    let captured = try XCTUnwrap(requests.last)
    let bodyData = try XCTUnwrap(bodyData(from: captured))
    let body = try XCTUnwrap(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
    let params = try XCTUnwrap(body["params"] as? [String: Any])
    let requestPayload = try XCTUnwrap(params["payload"] as? [String: Any])
    XCTAssertNil(requestPayload["title"])
  }

  private func makeSession(testID: String) -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    config.httpAdditionalHeaders = ["X-Mock-Test-ID": testID]
    return URLSession(configuration: config)
  }

  private func bodyData(from request: URLRequest) -> Data? {
    if let body = request.httpBody { return body }
    guard let stream = request.httpBodyStream else { return nil }
    stream.open()
    defer { stream.close() }

    var data = Data()
    let bufferSize = 4096
    var buffer = [UInt8](repeating: 0, count: bufferSize)
    while stream.hasBytesAvailable {
      let bytesRead = stream.read(&buffer, maxLength: bufferSize)
      if bytesRead < 0 { return nil }
      if bytesRead == 0 { break }
      data.append(buffer, count: bytesRead)
    }
    return data
  }
}

private final class RequestRecorder {
  private var requests: [URLRequest] = []
  private let lock = NSLock()

  func append(_ request: URLRequest) {
    lock.lock()
    requests.append(request)
    lock.unlock()
  }

  func all() -> [URLRequest] {
    lock.lock()
    defer { lock.unlock() }
    return requests
  }
}

private final class MockURLProtocol: URLProtocol {
  private struct Hooks {
    let requestHandler: (URLRequest) throws -> (HTTPURLResponse, Data)
    let requestObserver: ((URLRequest) -> Void)?
  }

  private static var hooksByTestID: [String: Hooks] = [:]
  private static let lock = NSLock()

  static func install(
    testID: String,
    requestHandler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data),
    requestObserver: ((URLRequest) -> Void)? = nil
  ) {
    lock.lock()
    hooksByTestID[testID] = Hooks(requestHandler: requestHandler, requestObserver: requestObserver)
    lock.unlock()
  }

  static func remove(testID: String) {
    lock.lock()
    hooksByTestID.removeValue(forKey: testID)
    lock.unlock()
  }

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    guard
      let testID = request.value(forHTTPHeaderField: "X-Mock-Test-ID"),
      let hooks = Self.hooks(for: testID)
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    do {
      hooks.requestObserver?(request)
      let (response, data) = try hooks.requestHandler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}

  private static func hooks(for testID: String) -> Hooks? {
    lock.lock()
    defer { lock.unlock() }
    return hooksByTestID[testID]
  }
}

private extension (HTTPURLResponse, Data) {
  static func ok(_ json: [String: Any]) -> Self {
    let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
    let response = HTTPURLResponse(
      url: URL(string: "https://example.test")!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )!
    return (response, data)
  }
}
