import XCTest
@testable import ComprehendlyForms

final class FieldStoreTests: XCTestCase {
  func testBindByElementId() throws {
    let store = FieldStore()
    let page = ComprehendlyPage(
      id: "p1",
      title: "Intake",
      elements: [[
        "id": "el-mood",
        "type": "form_field",
        "data": [
          "field_name": "mood",
          "label": "Mood",
          "input_type": "text"
        ]
      ]]
    )
    store.load(page)
    var seen: [String] = []
    _ = try store.bind(elementId: "el-mood") { value in
      seen.append(value as? String ?? "")
    }
    _ = try store.set(elementId: "el-mood", value: "ok", source: "voice")
    XCTAssertEqual(store.get("mood") as? String, "ok")
    XCTAssertEqual(seen.last, "ok")
  }
}
