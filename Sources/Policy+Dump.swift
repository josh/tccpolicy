extension Policy {
  static func dump(client: String) async throws -> Policy {
    var policy = Policy()

    try await TCCDb.user.open()

    if try await TCCDb.user.hasAccess(client: client, service: "kTCCServiceCalendar") {
      policy.calendar = true
    }

    if try await TCCDb.user.hasAccess(client: client, service: "kTCCServiceReminders") {
      policy.reminders = true
    }

    if try await TCCDb.user.hasAccess(client: client, service: "kTCCServicePhotos") {
      policy.photos = true
    }

    await TCCDb.user.close()

    return policy
  }
}
