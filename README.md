# Comprehendly Forms — Swift SDK

SwiftUI client for the same Comprehendly partner API as [`comprehendly-sdk-js`](https://github.com/UD-Ultradigital/comprehendly-sdk-js) (`apiVersion` 1).

- **Generated** — `ComprehendlyFormView` renders primitive fields from `forms.page.get`
- **Bound** — `store.bind(elementId:)` patches your existing controls

Voice (assistant / silent) uses the hosted WebView bridge; this package does not reimplement Realtime.

Docs: https://docs.comprehendly.nz

## Clone and run the demo

Requires Xcode 15+, a Comprehendly tenant, and a publishable key.

```bash
git clone https://github.com/UD-Ultradigital/comprehendly-sdk-swift.git
cd comprehendly-sdk-swift
open Package.swift
```

Or open `Examples/Demo/Demo.xcodeproj`.

1. Sign up: [app.comprehendly.nz/signup](https://app.comprehendly.nz/signup)
2. Publish a form. Settings → API → publishable key.
3. Allowlist origin `https://ios-demo.comprehendly.nz` (the SDK sends this `Origin` header on exchange).
4. In the demo, paste `pk_*` and the page UUID (or pick from catalog).

```swift
let client = ComprehendlyClient(publishableKey: "pk_test_…")
try await client.exchange()
let page = try await client.pageGet(pageId)
client.store.load(page)
```

```swift
let url = try client.voiceBridgeURL(pageId: pageId, mode: "assistant")
VoiceBridgeView(url: url, store: client.store)
```

## Identity

Bind with **element id** (stable). The engine writes **field_name**. Labels are display-only.
