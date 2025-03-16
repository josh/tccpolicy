// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "tccpolicy",
  platforms: [
    .macOS(.v15)
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
  ],
  targets: [
    .executableTarget(
      name: "tccpolicy",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ])
  ]
)
