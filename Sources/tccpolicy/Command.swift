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
  var client: String?

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
    var stderr = StandardErrorStream()

    let data = try Data(contentsOf: URL(fileURLWithPath: policyFile))

    if let client {
      let requiredPolicy = try JSONDecoder().decode(Policy.self, from: data)
      let policy = try await Policy.dump(client: client)

      do {
        try policy.check(requiredPolicy)
      } catch let error as Policy.CheckError {
        print("error: \(client): \(error)", to: &stderr)
        throw Error.checkFailed
      }
    } else {
      let requiredPolicies = try JSONDecoder().decode([String: Policy].self, from: data)
      let policies = try await Policy.dump()
      var failed = false

      for (name, requiredPolicy) in requiredPolicies {
        guard let policy = policies[name] else {
          print("error: \(name) has no policy", to: &stderr)
          failed = true
          continue
        }

        do {
          try policy.check(requiredPolicy)
        } catch let error as Policy.CheckError {
          print("error: \(name): \(error)", to: &stderr)
          failed = true
        }
      }

      if failed {
        throw Error.checkFailed
      }
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

  @Option(name: [.short, .customLong("service")])
  var service: String?

  mutating func run() async throws {
    try await Policy.reset(client: client, service: service)
  }
}
