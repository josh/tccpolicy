import Foundation

extension Policy {
  enum CodableError: Error, CustomStringConvertible {
    case invalidPolicyPath(String)

    var description: String {
      switch self {
      case .invalidPolicyPath(let path):
        return "Invalid policy path: \(path)"
      }
    }
  }

  static func read(atPath path: String) throws -> Policy {
    let url = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(Policy.self, from: data)
  }

  static func readAll(atPath path: String) throws -> [String: Policy] {
    let url = URL(fileURLWithPath: path)
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
      throw CodableError.invalidPolicyPath(path)
    }
    if isDirectory.boolValue {
      let directoryContents = try FileManager.default.contentsOfDirectory(atPath: path)
      var allPolicies: [String: Policy] = [:]
      for filename in directoryContents {
        if !filename.hasSuffix(".json") {
          continue
        }
        let data = try Data(contentsOf: url.appendingPathComponent(filename))
        let policies = try JSONDecoder().decode([String: Policy].self, from: data)
        allPolicies.merge(policies) { (_, b) in b }
      }
      return allPolicies
    } else {
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode([String: Policy].self, from: data)
    }
  }
}
