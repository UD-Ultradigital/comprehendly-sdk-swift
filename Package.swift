// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "ComprehendlyForms",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .library(name: "ComprehendlyForms", targets: ["ComprehendlyForms"])
  ],
  targets: [
    .target(name: "ComprehendlyForms"),
    .testTarget(name: "ComprehendlyFormsTests", dependencies: ["ComprehendlyForms"])
  ]
)
