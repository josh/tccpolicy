extension Policy {
  static func dump() async throws -> [String: Policy] {
    try await TCCDb.user.open()
    try await TCCDb.system.open()

    let userClients = try await TCCDb.user.clients()
    let systemClients = try await TCCDb.system.clients()
    let clients = Set(userClients + systemClients)

    var policies: [String: Policy] = [:]
    for client in clients {
      var policy = Policy()
      try await policy.load(client: client)
      if !policy.isEmpty {
        policies[client.description] = policy
      }
    }

    await TCCDb.user.close()
    await TCCDb.system.close()

    return policies
  }

  static func dump(client: Client) async throws -> Policy {
    try await TCCDb.user.open()
    try await TCCDb.system.open()

    var policy = Policy()
    try await policy.load(client: client)

    await TCCDb.user.close()
    await TCCDb.system.close()

    return policy
  }

  mutating func load(client: Client) async throws {
    var authValue: TCCDb.AuthValue?

    // Calendars
    authValue = await TCCDb.user.authValue(client: client, service: .Calendar)
    if authValue == .allowed || authValue == .addOnly {
      self.calendar = true
    } else if authValue == .denied {
      self.calendar = false
    }

    // Contacts
    authValue = await TCCDb.user.authValue(client: client, service: .AddressBook)
    if authValue == .allowed {
      self.addressBook = true
    } else if authValue == .denied {
      self.addressBook = false
    }

    // Files & Folders - Desktop Folder
    authValue = await TCCDb.user.authValue(
      client: client,
      service: .SystemPolicyDesktopFolder
    )
    if authValue == .allowed {
      self.systemPolicyDesktopFolder = true
    } else if authValue == .denied {
      self.systemPolicyDesktopFolder = false
    }

    // Files & Folders - Documents Folder
    authValue = await TCCDb.user.authValue(
      client: client,
      service: .SystemPolicyDocumentsFolder
    )
    if authValue == .allowed {
      self.systemPolicyDocumentsFolder = true
    } else if authValue == .denied {
      self.systemPolicyDocumentsFolder = false
    }

    // Files & Folders - Downloads Folder
    authValue = await TCCDb.user.authValue(
      client: client,
      service: .SystemPolicyDownloadsFolder
    )
    if authValue == .allowed {
      self.systemPolicyDownloadsFolder = true
    } else if authValue == .denied {
      self.systemPolicyDownloadsFolder = false
    }

    // Files & Folders - Network Volumes
    authValue = await TCCDb.user.authValue(
      client: client,
      service: .SystemPolicyNetworkVolumes
    )
    if authValue == .allowed {
      self.systemPolicyNetworkVolumes = true
    } else if authValue == .denied {
      self.systemPolicyNetworkVolumes = false
    }

    // Files & Folders - iCloud Drive
    authValue = await TCCDb.user.authValue(
      client: client,
      service: .FileProviderDomain,
      identifierPrefix: "com.apple.CloudDocs.iCloudDriveFileProvider/"
    )
    if authValue == .allowed {
      self.systemPolicyiCloudDrive = true
    } else if authValue == .denied {
      self.systemPolicyiCloudDrive = false
    }

    // Files & Folders - Other Documents
    // authValue = try await TCCDb.user.authValue(client: client, service: "???")

    // Full Disk Access
    authValue = await TCCDb.system.authValue(
      client: client,
      service: .SystemPolicyAllFiles
    )
    if authValue == .allowed {
      self.systemPolicyAllFiles = true
    } else if authValue == .denied {
      self.systemPolicyAllFiles = false
    }

    // Media & Apple Music
    authValue = await TCCDb.user.authValue(client: client, service: .MediaLibrary)
    if authValue == .allowed {
      self.mediaLibrary = true
    } else if authValue == .denied {
      self.mediaLibrary = false
    }

    // Photos
    authValue = await TCCDb.user.authValue(client: client, service: .Photos)
    if authValue == .allowed {
      self.photos = true
    } else if authValue == .denied {
      self.photos = false
    }

    // Reminders
    authValue = await TCCDb.user.authValue(client: client, service: .Reminders)
    if authValue == .allowed {
      self.reminders = true
    } else if authValue == .denied {
      self.reminders = false
    }

    // Automation
    let appleEventIdentifiers = await TCCDb.user.identifiers(client: client, service: .AppleEvents)
    if !appleEventIdentifiers.isEmpty {
      self.appleEvents = appleEventIdentifiers
    }
  }
}
