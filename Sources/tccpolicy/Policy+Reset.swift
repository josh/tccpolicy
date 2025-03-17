extension Policy {
  static func reset(client: String, service: String? = nil) async throws {
    var stderr = StandardErrorStream()
    try await TCCDb.user.open(readonly: false)
    let rowsChanged = try await TCCDb.user.reset(client: client, service: service)
    if rowsChanged == 0 {
      if let service {
        print("warn: No access entries found for client \(client) and service \(service)", to: &stderr)
      } else {
        print("warn: No access entries found for client \(client)", to: &stderr)
      }
    }
    await TCCDb.user.close()
  }
}