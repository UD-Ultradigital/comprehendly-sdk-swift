import SwiftUI

public struct ComprehendlyFormView: View {
  @ObservedObject var store: FieldStore

  public init(store: FieldStore) {
    self.store = store
  }

  public var body: some View {
    Form {
      ForEach(store.fields.filter(\.generated), id: \.fieldName) { field in
        GeneratedFieldRow(field: field, store: store)
      }
    }
  }
}

private struct GeneratedFieldRow: View {
  let field: ComprehendlyField
  @ObservedObject var store: FieldStore

  var text: String {
    store.get(field.fieldName) as? String ?? ""
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(field.label)
        .font(.subheadline.weight(.medium))
      if field.inputType == "textarea" {
        TextEditor(text: Binding(
          get: { text },
          set: { _ = try? store.set(fieldName: field.fieldName, value: $0, source: "user") }
        ))
        .frame(minHeight: 80)
      } else if field.inputType == "boolean" {
        Toggle("", isOn: Binding(
          get: { store.get(field.fieldName) as? Bool ?? false },
          set: { _ = try? store.set(fieldName: field.fieldName, value: $0, source: "user") }
        ))
      } else if field.inputType == "select", !field.options.isEmpty {
        Picker("", selection: Binding(
          get: { text },
          set: { _ = try? store.set(fieldName: field.fieldName, value: $0, source: "user") }
        )) {
          Text("").tag("")
          ForEach(field.options, id: \.self) { Text($0).tag($0) }
        }
      } else {
        TextField(field.fieldName, text: Binding(
          get: { text },
          set: { _ = try? store.set(fieldName: field.fieldName, value: $0, source: "user") }
        ))
      }
    }
  }
}
