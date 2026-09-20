import Combine
import SwiftUI
import ComprehendlyForms

@main
struct ComprehendlyDemoApp: App {
  var body: some Scene {
    WindowGroup { DemoRootView() }
  }
}

final class DemoModel: ObservableObject {
  @Published var publishableKey = ""
  @Published var pageId = ""
  @Published var status = "Paste a pk_* key. Allow origin https://ios-demo.comprehendly.nz on the key."
  @Published var boundMood = ""
  let client = ComprehendlyClient(publishableKey: "")

  func load() async {
    client.publishableKey = publishableKey.trimmingCharacters(in: .whitespacesAndNewlines)
    do {
      try await client.exchange()
      var id = pageId.trimmingCharacters(in: .whitespacesAndNewlines)
      if id.isEmpty {
        let catalog = try await client.catalogList()
        let root = catalog as? [String: Any] ?? [:]
        let forms = root["forms"] as? [[String: Any]] ?? []
        guard let first = forms.first, let fid = first["id"] as? String else {
          status = "No published forms"
          return
        }
        id = fid
        pageId = fid
      }
      let page = try await client.pageGet(id)
      if let first = client.store.fields.first {
        _ = try client.store.bind(elementId: first.elementId) { [weak self] value in
          DispatchQueue.main.async {
            self?.boundMood = value as? String ?? ""
          }
        }
      }
      status = "Loaded \(page.title ?? page.id)"
    } catch {
      status = error.localizedDescription
    }
  }
}

struct DemoRootView: View {
  @StateObject private var model = DemoModel()

  var body: some View {
    NavigationStack {
      List {
        Section("Connect") {
          TextField("pk_test_…", text: $model.publishableKey)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
          TextField("page UUID (optional)", text: $model.pageId)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
          Button("Load form") {
            Task { await model.load() }
          }
          Text(model.status).font(.footnote)
        }
        Section("Generated") {
          ComprehendlyFormView(store: model.client.store)
        }
        Section("Bound host field") {
          Text("First field, host TextField, same store")
            .font(.footnote)
          TextField("Host widget", text: $model.boundMood)
            .onChange(of: model.boundMood) { _, new in
              try? model.client.store.set(
                elementId: model.client.store.fields.first?.elementId,
                value: new,
                source: "bind"
              )
            }
        }
      }
      .navigationTitle("Comprehendly Swift")
    }
  }
}
