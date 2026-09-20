import Combine
import Foundation

public enum ComprehendlyError: Error, LocalizedError {
  case missingFieldIdentity
  case unknownField
  case http(Int, String)
  case notConfigured

  public var errorDescription: String? {
    switch self {
    case .missingFieldIdentity: return "fieldName or known elementId required"
    case .unknownField: return "unknown field"
    case .http(let code, let message): return "HTTP \(code): \(message)"
    case .notConfigured: return "publishableKey required"
    }
  }
}

public struct ComprehendlyField: Equatable {
  public var elementId: String
  public var fieldName: String
  public var label: String
  public var inputType: String
  public var required: Bool
  public var options: [String]
  public var generated: Bool
}

public struct ComprehendlyPage {
  public var id: String
  public var title: String?
  public var elements: [[String: Any]]

  public init(id: String, title: String?, elements: [[String: Any]]) {
    self.id = id
    self.title = title
    self.elements = elements
  }

  public static func parse(_ data: Any) -> ComprehendlyPage {
    let root = data as? [String: Any] ?? [:]
    let page = (root["page"] as? [String: Any]) ?? root
    let id = (page["id"] as? String) ?? ""
    let title = page["page_title"] as? String
    let nested = page["data"] as? [String: Any]
    let elements = (page["elements"] as? [[String: Any]])
      ?? (nested?["elements"] as? [[String: Any]])
      ?? []
    return ComprehendlyPage(id: id, title: title, elements: elements)
  }
}

public struct FieldPatch {
  public var elementId: String?
  public var fieldName: String
  public var value: Any?
  public var source: String
}

private let fillableTypes: Set<String> = ["form_field", "form_field_rating", "form_field_score"]
private let generatedTypes: Set<String> = [
  "text", "textarea", "number", "date", "boolean", "select", "multiselect"
]

public func fillableFields(from page: ComprehendlyPage) -> [ComprehendlyField] {
  page.elements.compactMap { el in
    guard let type = el["type"] as? String, fillableTypes.contains(type) else { return nil }
    let data = el["data"] as? [String: Any] ?? [:]
    let elementId = (el["id"] as? String) ?? ""
    let named = (data["field_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let fieldName = named.isEmpty ? "field_\(elementId.prefix(8))" : named
    let inputType = (data["input_type"] as? String)
      ?? (type == "form_field_rating" ? "rating" : type == "form_field_score" ? "score" : "text")
    let options = data["options"] as? [String] ?? []
    return ComprehendlyField(
      elementId: elementId,
      fieldName: fieldName,
      label: (data["label"] as? String) ?? fieldName,
      inputType: inputType,
      required: data["required"] as? Bool ?? false,
      options: options,
      generated: generatedTypes.contains(inputType)
    )
  }
}

public final class FieldStore: ObservableObject {
  @Published public private(set) var fields: [ComprehendlyField] = []
  @Published public private(set) var values: [String: Any] = [:]

  private var byElement: [String: ComprehendlyField] = [:]
  private var listeners: [UUID: (FieldPatch) -> Void] = [:]

  public init() {}

  @discardableResult
  public func load(_ page: ComprehendlyPage) -> [ComprehendlyField] {
    fields = fillableFields(from: page)
    byElement = Dictionary(
      uniqueKeysWithValues: fields.filter { !$0.elementId.isEmpty }.map { ($0.elementId, $0) }
    )
    let keep = Set(fields.map(\.fieldName))
    values = values.filter { keep.contains($0.key) }
    return fields
  }

  public func get(_ fieldName: String) -> Any? {
    values[fieldName]
  }

  @discardableResult
  public func set(elementId: String? = nil, fieldName: String? = nil, value: Any?, source: String = "user") throws -> FieldPatch {
    let resolved = fieldName ?? elementId.flatMap { byElement[$0]?.fieldName }
    guard let name = resolved else { throw ComprehendlyError.missingFieldIdentity }
    values[name] = value
    let field = fields.first { $0.fieldName == name }
    let patch = FieldPatch(
      elementId: elementId ?? field?.elementId,
      fieldName: name,
      value: value,
      source: source
    )
    listeners.values.forEach { $0(patch) }
    return patch
  }

  @discardableResult
  public func bind(elementId: String? = nil, fieldName: String? = nil, apply: @escaping (Any?) -> Void) throws -> UUID {
    let resolved = fieldName ?? elementId.flatMap { byElement[$0]?.fieldName }
    guard let name = resolved else { throw ComprehendlyError.unknownField }
    apply(values[name])
    let id = UUID()
    listeners[id] = { patch in
      if patch.fieldName == name { apply(patch.value) }
    }
    return id
  }

  public func unbind(_ id: UUID) {
    listeners[id] = nil
  }
}
