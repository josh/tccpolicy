import Foundation

struct StandardErrorStream: TextOutputStream {
  func write(_ string: String) {
    FileHandle.standardError.write(Data(string.utf8))
  }
}
