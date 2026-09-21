import XCTest
@testable import ComprehendlyForms

final class VoiceBridgeTests: XCTestCase {
  func testBridgeURL() {
    let url = VoiceBridge.url(
      token: "scist_x",
      pageId: "11111111-1111-4111-8111-111111111111",
      mode: "assistant"
    )
    XCTAssertEqual(url.host, "docs.comprehendly.nz")
    XCTAssertEqual(url.path, "/voice-bridge.html")
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    XCTAssertEqual(items.first { $0.name == "fill_mode" }?.value, "assistant")
    XCTAssertEqual(items.first { $0.name == "base_url" }?.value, "https://sdk.comprehendly.nz")
  }

  func testApplyHostMessage() {
    let store = FieldStore()
    store.load(ComprehendlyPage(
      id: "p1",
      title: nil,
      elements: [[
        "id": "el-mood",
        "type": "form_field",
        "data": ["field_name": "mood", "label": "Mood", "input_type": "text"]
      ]]
    ))
    store.applyHostMessage(["field_values": ["mood": "low"]])
    XCTAssertEqual(store.get("mood") as? String, "low")
  }

  func testCamelCaseFieldValues() {
    let store = FieldStore()
    store.load(ComprehendlyPage(
      id: "p1",
      title: nil,
      elements: [[
        "id": "el-mood",
        "type": "form_field",
        "data": ["field_name": "mood", "label": "Mood", "input_type": "text"]
      ]]
    ))
    store.applyHostMessage(["fieldValues": ["mood": "ok"]])
    XCTAssertEqual(store.get("mood") as? String, "ok")
  }
}
