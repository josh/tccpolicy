import AppKit
import Foundation

enum Client {
  case bundleIdentifier(String, URL)
  case path(URL)
  case unknown(String)

  init(_ client: String) {
    if client.hasPrefix("/") {
      self = .path(URL(fileURLWithPath: client))
    } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: client) {
      self = .bundleIdentifier(client, url)
    } else {
      self = .unknown(client)
    }
  }

  var url: URL? {
    switch self {
    case .bundleIdentifier(_, let url):
      return url
    case .path(let url):
      return url
    case .unknown:
      return nil
    }
  }
}

extension Client: CustomStringConvertible {
  var description: String {
    switch self {
    case .bundleIdentifier(let identifier, _):
      return identifier
    case .path(let url):
      return url.path
    case .unknown(let value):
      return value
    }
  }
}

extension Client: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(description)
  }
}
