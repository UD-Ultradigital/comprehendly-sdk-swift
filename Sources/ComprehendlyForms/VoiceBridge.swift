import Foundation

public enum VoiceBridge {
  public static let defaultDocsOrigin = "https://docs.comprehendly.nz"
  public static let defaultSdkOrigin = "https://sdk.comprehendly.nz"

  public static func url(
    token: String,
    pageId: String,
    mode: String,
    docsOrigin: String = defaultDocsOrigin,
    sdkOrigin: String = defaultSdkOrigin
  ) -> URL {
    var components = URLComponents(string: "\(docsOrigin)/voice-bridge.html")!
    components.queryItems = [
      URLQueryItem(name: "integration_token", value: token),
      URLQueryItem(name: "page_id", value: pageId),
      URLQueryItem(name: "fill_mode", value: mode),
      URLQueryItem(name: "base_url", value: sdkOrigin)
    ]
    return components.url!
  }
}
