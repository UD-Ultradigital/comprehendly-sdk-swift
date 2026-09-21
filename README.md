# Comprehendly Swift SDK developer guide

Swift package for the Comprehendly Forms partner API.

Docs: https://docs.comprehendly.nz

## Install

In Xcode:

1. **File → Add Package Dependencies…**
2. Enter `https://github.com/UD-Ultradigital/comprehendly-sdk-swift.git`
3. Choose a pinned revision or release when one is available for your app
4. Add the **ComprehendlyForms** product to your target

## Configure the client

`ComprehendlyClient` exchanges a publishable key for a short-lived gateway token.

```swift
import ComprehendlyForms

let client = ComprehendlyClient(
  publishableKey: "pk_test_..."
)
```

The default `Origin` header is `https://ios-demo.comprehendly.nz`. That exact origin must be on the publishable key allowlist or `exchange()` will fail.

```swift
try await client.exchange()
```

## Load forms

Use `catalogList()` to list published forms and `pageGet(_:)` to fetch a page definition.

```swift
let catalog = try await client.catalogList()
let page = try await client.pageGet("11111111-1111-4111-8111-111111111111")
```

`pageGet(_:)` also loads the page into `client.store`.

## Field identity

- Bind host widgets by `element.id`
- Submission values are keyed by `field_name`
- Never use labels as identifiers

Field identity is `element.id` + `field_name`: resolve by `element.id`, persist by `field_name`.

## Generated UI

Use `ComprehendlyFormView` when you want the SDK to render supported primitive controls from the loaded page.

```swift
ComprehendlyFormView(store: client.store)
```

This is generated input UI, not a reproduction of full Comprehendly page chrome.

## Bind your own widgets

If your app already has its own controls, bind them through `FieldStore` using `elementId`.

```swift
let bindingId = try client.store.bind(elementId: "el-mood") { value in
  print("Updated:", value as? String ?? "")
}

try client.store.set(elementId: "el-mood", value: "ok", source: "host")
client.store.unbind(bindingId)
```

Do not overlay Comprehendly chrome on host widgets. Keep your app's controls native and sync values through the store.

## Voice

Use the hosted voice bridge through `VoiceBridgeView`.

```swift
let url = try client.voiceBridgeURL(pageId: page.id, mode: "assistant")
VoiceBridgeView(url: url, store: client.store)
```

The voice experience is hosted; do not reimplement GPT Realtime or replace the bridge with custom realtime transport.

## Save submissions

Use `submissionsSave(pageId:fieldValues:title:)` to persist values keyed by `field_name`.

```swift
let result = try await client.submissionsSave(
  pageId: page.id,
  fieldValues: [
    "mood": "ok",
    "notes": "Ready for review"
  ],
  title: "Intake"
)
```

`submissionsGet(_:)` remains available for fetching an existing submission.
