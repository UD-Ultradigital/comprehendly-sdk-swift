# Demo app

Checked-in iOS project. Microphone usage string is already in the generated Info.plist keys.

```bash
open Examples/Demo/ComprehendlyDemo.xcodeproj
```

Select an iPhone simulator → Run. Paste a `pk_*` key. Allowlist origin **`https://ios-demo.comprehendly.nz`** on that key.

Regenerate the project after editing `project.yml`:

```bash
cd Examples/Demo && xcodegen generate
```

Voice: Assistant / Silent opens `VoiceBridgeView` (WKWebView → hosted fill embed).
