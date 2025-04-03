import Foundation

let version = "0.1.0"

let commands: [String: any Command] = [
  "check": CheckCommand(),
  "dump": DumpCommand(),
  "help": HelpCommand(),
  "request": RequestCommand(),
  "reset": ResetCommand(),
]

@main
struct TccPolicy {
  static func main() async throws {
    try await TccPolicy().run(CommandLine.arguments)
  }

  func run(_ args: [String]) async throws {
    let helpCommand = HelpCommand()

    if args.count <= 1 {
      helpCommand.printHelp()
      return
    }

    if args.count == 2 && (args[1] == "--help" || args[1] == "-h") {
      helpCommand.printHelp()
      return
    }

    if args.count == 2 && (args[1] == "--version" || args[1] == "-V") {
      print(version)
      return
    }

    let subcommand = args[1]
    if let command = commands[subcommand] {
      let commandArgs = Array(args.dropFirst(2))
      if commandArgs.contains("--help") || commandArgs.contains("-h") {
        command.printHelp()
        return
      }
      try await command.run(commandArgs)
    } else {
      print("Unknown subcommand: \(subcommand)")
      helpCommand.printHelp()
    }
  }
}

protocol Command {
  var abstract: String { get }
  func printHelp()
  func run(_ args: [String]) async throws
}

struct HelpCommand: Command {
  var abstract: String = "Show help information"

  func printHelp() {
    print(
      """
      OVERVIEW: manage policy for client in TCC privacy database

      USAGE: tcc-policy <subcommand>

      OPTIONS:
        -V, --version           Show the version.
        -h, --help              Show help information.

      SUBCOMMANDS:
      """)

    for (name, command) in commands.sorted(by: { $0.key < $1.key }) {
      print(
        "  \(name)\(String(repeating: " ", count: max(0, 24 - name.count)))\(command.abstract)"
      )
    }

    print(
      """

        See 'tcc-policy help <subcommand>' for detailed help.
      """)
  }

  func run(_ args: [String]) async throws {
    if args.count > 0 {
      if let command = commands[args[0]] {
        command.printHelp()
      } else {
        print("Unknown subcommand: \(args[2])")
        printHelp()
      }
    } else {
      printHelp()
    }
  }
}

struct DumpCommand: Command {
  var abstract: String = "Dump policy for given client"

  func printHelp() {
    print(
      """
      OVERVIEW: \(abstract)

      USAGE: tcc-policy dump [--client <client>] [--output <output>]

      OPTIONS:
        --client <client>       Bundle identifier or executable path
        -o, --output <output>
        -h, --help              Show help information.
      """)
  }

  func run(_ args: [String]) async throws {
    var client: String? = nil
    var outputFile: String? = nil

    var i = 0
    while i < args.count {
      switch args[i] {
      case "--client":
        if i + 1 < args.count {
          client = args[i + 1]
          i += 2
        } else {
          print("error: missing value for '--client'")
          return
        }
      case "--output", "-o":
        if i + 1 < args.count {
          outputFile = args[i + 1]
          i += 2
        } else {
          print("error: missing value for '--output'")
          return
        }
      default:
        print("error: unknown option '\(args[i])'")
        return
      }
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]

    let data: Data
    if let client {
      data = try await encoder.encode(Policy.dump(client: client))
    } else {
      data = try await encoder.encode(Policy.dump())
    }

    if let outputFile {
      try data.write(to: URL(fileURLWithPath: outputFile))
    } else {
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write("\n".data(using: .utf8)!)
    }
  }
}

struct CheckCommand: Command {
  var abstract: String = "Check client matches policy requirements"

  enum Error: Swift.Error, CustomStringConvertible {
    case checkFailed
    case missingRequiredOption(String)

    var description: String {
      switch self {
      case .checkFailed:
        return "Policy check failed"
      case .missingRequiredOption(let option):
        return "Missing required option: \(option)"
      }
    }
  }

  func printHelp() {
    print(
      """
      OVERVIEW: \(abstract)

      USAGE: tcc-policy check [--client <client>] --policy <policy>

      OPTIONS:
        --client <client>       Bundle identifier or executable path
        -p, --policy <policy>
        -h, --help              Show help information.
      """)
  }

  func run(_ args: [String]) async throws {
    var client: String? = nil
    var policyFile: String? = nil

    var i = 0
    while i < args.count {
      switch args[i] {
      case "--client":
        if i + 1 < args.count {
          client = args[i + 1]
          i += 2
        } else {
          print("error: missing value for '--client'")
          return
        }
      case "--policy", "-p":
        if i + 1 < args.count {
          policyFile = args[i + 1]
          i += 2
        } else {
          print("error: missing value for '--policy'")
          return
        }
      default:
        print("error: unknown option '\(args[i])'")
        return
      }
    }

    guard let policyFile = policyFile else {
      throw Error.missingRequiredOption("--policy")
    }

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

struct RequestCommand: Command {
  var abstract: String = "Request policy for given client"

  enum Error: Swift.Error, CustomStringConvertible {
    case missingRequiredOption(String)

    var description: String {
      switch self {
      case .missingRequiredOption(let option):
        return "Missing required option: \(option)"
      }
    }
  }

  func printHelp() {
    print(
      """
      OVERVIEW: \(abstract)

      USAGE: tcc-policy request --policy <policy>

      OPTIONS:
        -p, --policy <policy>
        -h, --help              Show help information.
      """)
  }

  func run(_ args: [String]) async throws {
    var policyFile: String? = nil

    var i = 0
    while i < args.count {
      switch args[i] {
      case "--policy", "-p":
        if i + 1 < args.count {
          policyFile = args[i + 1]
          i += 2
        } else {
          print("error: missing value for '--policy'")
          return
        }
      default:
        print("error: unknown option '\(args[i])'")
        return
      }
    }

    guard let policyFile else {
      throw Error.missingRequiredOption("--policy")
    }

    let data = try Data(contentsOf: URL(fileURLWithPath: policyFile))
    let policy = try JSONDecoder().decode(Policy.self, from: data)
    try await policy.request()
  }
}

struct ResetCommand: Command {
  var abstract: String = "Reset policy for given client"

  enum Error: Swift.Error, CustomStringConvertible {
    case missingRequiredOption(String)
    case invalidServiceValue(String)

    var description: String {
      switch self {
      case .missingRequiredOption(let option):
        return "Missing required option: \(option)"
      case .invalidServiceValue(let value):
        return "Invalid service value: \(value)"
      }
    }
  }

  func printHelp() {
    print(
      """
      OVERVIEW: \(abstract)

      USAGE: tcc-policy reset --client <client> [--service <service>]

      OPTIONS:
        --client <client>       Bundle identifier or executable path
        -s, --service <service>
        -h, --help              Show help information.
      """)
  }

  func run(_ args: [String]) async throws {
    var client: String? = nil
    var serviceString: String? = nil

    var i = 0
    while i < args.count {
      switch args[i] {
      case "--client":
        if i + 1 < args.count {
          client = args[i + 1]
          i += 2
        } else {
          print("error: missing value for '--client'")
          return
        }
      case "--service", "-s":
        if i + 1 < args.count {
          serviceString = args[i + 1]
          i += 2
        } else {
          print("error: missing value for '--service'")
          return
        }
      default:
        print("error: unknown option '\(args[i])'")
        return
      }
    }

    guard let client = client else {
      throw Error.missingRequiredOption("--client")
    }

    var service: Service? = nil
    if let serviceString {
      guard let parsedService = Service(rawValue: serviceString) else {
        throw Error.invalidServiceValue(serviceString)
      }
      service = parsedService
    }

    try await Policy.reset(client: client, service: service)
  }
}
