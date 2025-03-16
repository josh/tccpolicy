struct Policy: Codable {
  var addressBook: Bool?
  var calendar: Bool?
  var mediaLibrary: Bool?
  var photos: Bool?
  var reminders: Bool?
  // var accessibility: Bool?
  // var appleEvents: [String]?
  // var camera: Bool?
  // var microphone: Bool?
  // var postEvent: Bool?
  // var systemPolicyAllFiles: Bool?
  // var systemPolicyDesktopFolder: Bool?
  // var systemPolicyDeveloperFiles: Bool?
  // var systemPolicyDocumentsFolder: Bool?
  // var systemPolicyDownloadsFolder: Bool?
  // var systemPolicyiCloudDrive: Bool?
  // var systemPolicyNetworkVolumes: Bool?
  // var systemPolicyRemovableVolumes: Bool?
  // var systemPolicySysAdminFiles: Bool?

  enum CodingKeys: String, CodingKey {
    case addressBook = "AddressBook"
    case calendar = "Calendar"
    case mediaLibrary = "MediaLibrary"
    case photos = "Photos"
    case reminders = "Reminders"
    // case accessibility = "Accessibility"
    // case appleEvents = "AppleEvents"
    // case camera = "Camera"
    // case microphone = "Microphone"
    // case postEvent = "PostEvent"
    // case systemPolicyAllFiles = "SystemPolicyAllFiles"
    // case systemPolicyDesktopFolder = "SystemPolicyDesktopFolder"
    // case systemPolicyDeveloperFiles = "SystemPolicyDeveloperFiles"
    // case systemPolicyDocumentsFolder = "SystemPolicyDocumentsFolder"
    // case systemPolicyDownloadsFolder = "SystemPolicyDownloadsFolder"
    // case systemPolicyiCloudDrive = "SystemPolicyiCloudDrive"
    // case systemPolicyNetworkVolumes = "SystemPolicyNetworkVolumes"
    // case systemPolicyRemovableVolumes = "SystemPolicyRemovableVolumes"
    // case systemPolicySysAdminFiles = "SystemPolicySysAdminFiles"
  }
}

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
