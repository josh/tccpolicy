// swift-tools-version: 5.8

import PackageDescription

let package = Package(
  name: "tccpolicy",
  platforms: [
    .macOS(.v13)
  ],
  targets: [
    .executableTarget(name: "tccpolicy")
  ]
)
