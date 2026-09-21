#if os(iOS)
import SwiftUI
import WebKit

public struct VoiceBridgeView: UIViewRepresentable {
  public var url: URL
  public var store: FieldStore
  public var onSubmission: ((String?) -> Void)?

  public init(url: URL, store: FieldStore, onSubmission: ((String?) -> Void)? = nil) {
    self.url = url
    self.store = store
    self.onSubmission = onSubmission
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(store: store, onSubmission: onSubmission)
  }

  public func makeUIView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.allowsInlineMediaPlayback = true
    config.mediaTypesRequiringUserActionForPlayback = []
    config.userContentController.add(context.coordinator, name: "comprehendly")
    let view = WKWebView(frame: .zero, configuration: config)
    view.navigationDelegate = context.coordinator
    view.uiDelegate = context.coordinator
    view.scrollView.bounces = false
    view.load(URLRequest(url: url))
    return view
  }

  public func updateUIView(_ uiView: WKWebView, context: Context) {
    context.coordinator.store = store
    context.coordinator.onSubmission = onSubmission
  }

  public final class Coordinator: NSObject, WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate {
    var store: FieldStore
    var onSubmission: ((String?) -> Void)?

    init(store: FieldStore, onSubmission: ((String?) -> Void)?) {
      self.store = store
      self.onSubmission = onSubmission
    }

    public func userContentController(
      _ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage
    ) {
      let payload: [String: Any]
      if let dict = message.body as? [String: Any] {
        payload = dict
      } else if let text = message.body as? String,
                let data = text.data(using: .utf8),
                let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        payload = dict
      } else {
        return
      }
      DispatchQueue.main.async {
        self.store.applyHostMessage(payload)
        let type = payload["type"] as? String ?? ""
        if type == "stepcare:submission_saved" || type == "submission_saved" {
          let id = (payload["submissionId"] as? String) ?? (payload["id"] as? String)
          self.onSubmission?(id)
        }
      }
    }

    public func webView(
      _ webView: WKWebView,
      requestMediaCapturePermissionFor origin: WKSecurityOrigin,
      initiatedByFrame frame: WKFrameInfo,
      type: WKMediaCaptureType,
      decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
      decisionHandler(.grant)
    }
  }
}
#endif
