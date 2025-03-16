import Foundation

struct StandardErrorStream: TextOutputStream {
  func write(_ string: String) {
    if let data = string.data(using: .utf8) {
      FileHandle.standardError.write(data)
    }
  }
}
