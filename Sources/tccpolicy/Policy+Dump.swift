extension Policy {
  static func dump() async throws -> [String: Policy] {
    try await TCCDb.user.open()

    let clients = try await TCCDb.user.clients()
    var policies: [String: Policy] = [:]
    for client in clients {
      var policy = Policy()
      try await policy.load(client: client)
      if !policy.isEmpty {
        policies[client] = policy
      }
    }

    await TCCDb.user.close()

    return policies
  }

  static func dump(client: String) async throws -> Policy {
    try await TCCDb.user.open()
    var policy = Policy()
    try await policy.load(client: client)
    await TCCDb.user.close()
    return policy
  }

  mutating func load(client: String) async throws {
    var authValue: TCCDb.AuthValue?

    // Calendars
    authValue = try await TCCDb.user.authValue(client: client, service: "kTCCServiceCalendar")
    if authValue == .allowed || authValue == .addOnly {
      self.calendar = true
    } else if authValue == .denied {
      self.calendar = false
    }

    // Contacts
    authValue = try await TCCDb.user.authValue(client: client, service: "kTCCServiceAddressBook")
    if authValue == .allowed {
      self.addressBook = true
    } else if authValue == .denied {
      self.addressBook = false
    }

    // Files & Folders - Desktop Folder
    authValue = try await TCCDb.user.authValue(
      client: client, service: "kTCCServiceSystemPolicyDesktopFolder")
    if authValue == .allowed {
      self.systemPolicyDesktopFolder = true
    } else if authValue == .denied {
      self.systemPolicyDesktopFolder = false
    }

    // Files & Folders - Documents Folder
    authValue = try await TCCDb.user.authValue(
      client: client, service: "kTCCServiceSystemPolicyDocumentsFolder")
    if authValue == .allowed {
      self.systemPolicyDocumentsFolder = true
    } else if authValue == .denied {
      self.systemPolicyDocumentsFolder = false
    }

    // Files & Folders - Downloads Folder
    authValue = try await TCCDb.user.authValue(
      client: client, service: "kTCCServiceSystemPolicyDownloadsFolder")
    if authValue == .allowed {
      self.systemPolicyDownloadsFolder = true
    } else if authValue == .denied {
      self.systemPolicyDownloadsFolder = false
    }

    // Files & Folders - Network Volumes
    authValue = try await TCCDb.user.authValue(
      client: client, service: "kTCCServiceSystemPolicyNetworkVolumes")
    if authValue == .allowed {
      self.systemPolicyNetworkVolumes = true
    } else if authValue == .denied {
      self.systemPolicyNetworkVolumes = false
    }

    // Files & Folders - iCloud Drive
    authValue = try await TCCDb.user.authValue(
      client: client, service: "kTCCServiceFileProviderDomain",
      identifierPrefix: "com.apple.CloudDocs.iCloudDriveFileProvider/")
    if authValue == .allowed {
      self.systemPolicyiCloudDrive = true
    } else if authValue == .denied {
      self.systemPolicyiCloudDrive = false
    }

    // Files & Folders - Other Documents
    // authValue = try await TCCDb.user.authValue(client: client, service: "???")

    // Media & Apple Music
    authValue = try await TCCDb.user.authValue(client: client, service: "kTCCServiceMediaLibrary")
    if authValue == .allowed {
      self.mediaLibrary = true
    } else if authValue == .denied {
      self.mediaLibrary = false
    }

    // Photos
    authValue = try await TCCDb.user.authValue(client: client, service: "kTCCServicePhotos")
    if authValue == .allowed {
      self.photos = true
    } else if authValue == .denied {
      self.photos = false
    }

    // Reminders
    authValue = try await TCCDb.user.authValue(client: client, service: "kTCCServiceReminders")
    if authValue == .allowed {
      self.reminders = true
    } else if authValue == .denied {
      self.reminders = false
    }

    // Automation
    let appleEventIdentifiers = try await TCCDb.user.identifiers(
      client: client, service: "kTCCServiceAppleEvents")
    if !appleEventIdentifiers.isEmpty {
      self.appleEvents = appleEventIdentifiers
    }
  }
}
