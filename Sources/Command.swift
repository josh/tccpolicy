import ArgumentParser
import Foundation

@main
struct TccPolicy: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "manage policy for client in TCC privacy database",
    version: "0.1.0",
    subcommands: [Dump.self, Request.self, Reset.self]
  )
}

struct Dump: AsyncParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Dump policy for given client")

  @Option(help: "Bundle identifier or executable path")
  var client: String

  @Option(name: [.short, .customLong("output")])
  var outputFile: String?

  mutating func run() async throws {
    let policy = try await Policy.dump(client: client)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    let data = try encoder.encode(policy)

    if let outputFile = outputFile {
      try data.write(to: URL(fileURLWithPath: outputFile))
    } else {
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write("\n".data(using: .utf8)!)
    }
  }
}

struct Request: AsyncParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Request policy for given client")

  @Option(help: "Bundle identifier or executable path")
  var client: String

  @Option(name: [.short, .customLong("policy")])
  var policyFile: String

  mutating func run() async throws {
    let data = try Data(contentsOf: URL(fileURLWithPath: policyFile))
    let policy = try JSONDecoder().decode(Policy.self, from: data)
    try await policy.request()
  }
}

struct Reset: AsyncParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Reset policy for given client")

  @Option(help: "Bundle identifier or executable path")
  var client: String

  mutating func run() async throws {
    print("TODO: implement reset for \(client)")
  }
}
