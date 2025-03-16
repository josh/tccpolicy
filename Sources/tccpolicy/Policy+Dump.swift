extension Policy {
  static func dump(client: String) async throws -> Policy {
    var policy = Policy()

    try await TCCDb.user.open()

    var authValue: TCCDb.AuthValue?

    // Calendars
    authValue = try await TCCDb.user.authValue(client: client, service: "kTCCServiceCalendar")
    if authValue == .allowed || authValue == .addOnly {
      policy.calendar = true
    } else if authValue == .denied {
      policy.calendar = false
    }

    // Contacts
    authValue = try await TCCDb.user.authValue(client: client, service: "kTCCServiceAddressBook")
    if authValue == .allowed {
      policy.addressBook = true
    } else if authValue == .denied {
      policy.addressBook = false
    }

    // Files & Folders - Desktop Folder
    authValue = try await TCCDb.user.authValue(
      client: client, service: "kTCCServiceSystemPolicyDesktopFolder")
    if authValue == .allowed {
      policy.systemPolicyDesktopFolder = true
    } else if authValue == .denied {
      policy.systemPolicyDesktopFolder = false
    }

    // Files & Folders - Documents Folder
    authValue = try await TCCDb.user.authValue(
      client: client, service: "kTCCServiceSystemPolicyDocumentsFolder")
    if authValue == .allowed {
      policy.systemPolicyDocumentsFolder = true
    } else if authValue == .denied {
      policy.systemPolicyDocumentsFolder = false
    }

    // Files & Folders - Downloads Folder
    authValue = try await TCCDb.user.authValue(
      client: client, service: "kTCCServiceSystemPolicyDownloadsFolder")
    if authValue == .allowed {
      policy.systemPolicyDownloadsFolder = true
    } else if authValue == .denied {
      policy.systemPolicyDownloadsFolder = false
    }

    // Files & Folders - Network Volumes
    authValue = try await TCCDb.user.authValue(
      client: client, service: "kTCCServiceSystemPolicyNetworkVolumes")
    if authValue == .allowed {
      policy.systemPolicyNetworkVolumes = true
    } else if authValue == .denied {
      policy.systemPolicyNetworkVolumes = false
    }

    // Files & Folders - iCloud Drive
    authValue = try await TCCDb.user.authValue(
      client: client, service: "kTCCServiceFileProviderDomain",
      identifierPrefix: "com.apple.CloudDocs.iCloudDriveFileProvider/")
    if authValue == .allowed {
      policy.systemPolicyiCloudDrive = true
    } else if authValue == .denied {
      policy.systemPolicyiCloudDrive = false
    }

    // Files & Folders - Other Documents
    // authValue = try await TCCDb.user.authValue(client: client, service: "???")

    // Media & Apple Music
    authValue = try await TCCDb.user.authValue(client: client, service: "kTCCServiceMediaLibrary")
    if authValue == .allowed {
      policy.mediaLibrary = true
    } else if authValue == .denied {
      policy.mediaLibrary = false
    }

    // Photos
    authValue = try await TCCDb.user.authValue(client: client, service: "kTCCServicePhotos")
    if authValue == .allowed {
      policy.photos = true
    } else if authValue == .denied {
      policy.photos = false
    }

    // Reminders
    authValue = try await TCCDb.user.authValue(client: client, service: "kTCCServiceReminders")
    if authValue == .allowed {
      policy.reminders = true
    } else if authValue == .denied {
      policy.reminders = false
    }

    // Automation
    let appleEventIdentifiers = try await TCCDb.user.identifiers(
      client: client, service: "kTCCServiceAppleEvents")
    if !appleEventIdentifiers.isEmpty {
      policy.appleEvents = appleEventIdentifiers
    }

    await TCCDb.user.close()

    return policy
  }
}
