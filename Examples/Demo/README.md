# Demo app

The Swift package is the SDK. This folder is a **drop-in iOS app** (Xcode 15+):

1. Xcode → File → New → Project → iOS App → SwiftUI.
2. File → Add Package Dependencies → Add Local… → this repo root (`ComprehendlyForms`).
3. Replace the generated `App` file with `ComprehendlyDemoApp.swift`.
4. Info → App Transport / outgoing network (default ATS allows `https://api.stepcare.app`).

Allowlist origin **`https://ios-demo.comprehendly.nz`** on your publishable key (the client sends that `Origin` header).

Voice assistant / silent listening: next slice (WKWebView bridge). This demo is FieldStore + generated + bound.
