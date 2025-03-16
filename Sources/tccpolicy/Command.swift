import ArgumentParser
import Foundation

@main
struct TccPolicy: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "manage policy for client in TCC privacy database",
    version: "0.1.0",
    subcommands: [Dump.self, Check.self, Request.self, Reset.self]
  )
}

struct Dump: AsyncParsableCommand {
  static let configuration = CommandConfiguration(abstract: "Dump policy for given client")

  @Option(help: "Bundle identifier or executable path")
  var client: String?

  @Option(name: [.short, .customLong("output")])
  var outputFile: String?

  mutating func run() async throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    let data: Data

    if let client {
      data = try await encoder.encode(Policy.dump(client: client))
    } else {
      data = try await encoder.encode(Policy.dump())
    }

    if let outputFile = outputFile {
      try data.write(to: URL(fileURLWithPath: outputFile))
    } else {
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write("\n".data(using: .utf8)!)
    }
  }
}

struct Check: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Check client matches policy requirements")

  @Option(help: "Bundle identifier or executable path")
  var client: String

  @Option(name: [.short, .customLong("policy")])
  var policyFile: String

  enum Error: Swift.Error, CustomStringConvertible {
    case checkFailed

    var description: String {
      switch self {
      case .checkFailed:
        return "Policy check failed"
      }
    }
  }

  mutating func run() async throws {
    let data = try Data(contentsOf: URL(fileURLWithPath: policyFile))
    let policyA = try JSONDecoder().decode(Policy.self, from: data)
    let policyB = try await Policy.dump(client: client)
    if !policyA.satisfies(policyB) {
      throw Error.checkFailed
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
