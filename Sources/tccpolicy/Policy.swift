struct Policy: Codable {
  var addressBook: Bool?
  var appleEvents: [String]?
  var calendar: Bool?
  var mediaLibrary: Bool?
  var photos: Bool?
  var reminders: Bool?
  var systemPolicyAllFiles: Bool?
  var systemPolicyDesktopFolder: Bool?
  var systemPolicyDeveloperFiles: Bool?
  var systemPolicyDocumentsFolder: Bool?
  var systemPolicyDownloadsFolder: Bool?
  var systemPolicyiCloudDrive: Bool?
  var systemPolicyNetworkVolumes: Bool?

  enum CodingKeys: String, CodingKey, CaseIterable {
    case addressBook = "AddressBook"
    case appleEvents = "AppleEvents"
    case calendar = "Calendar"
    case mediaLibrary = "MediaLibrary"
    case photos = "Photos"
    case reminders = "Reminders"
    case systemPolicyAllFiles = "SystemPolicyAllFiles"
    case systemPolicyDesktopFolder = "SystemPolicyDesktopFolder"
    case systemPolicyDeveloperFiles = "SystemPolicyDeveloperFiles"
    case systemPolicyDocumentsFolder = "SystemPolicyDocumentsFolder"
    case systemPolicyDownloadsFolder = "SystemPolicyDownloadsFolder"
    case systemPolicyiCloudDrive = "SystemPolicyiCloudDrive"
    case systemPolicyNetworkVolumes = "SystemPolicyNetworkVolumes"
  }

  var isEmpty: Bool {
    return addressBook == nil && appleEvents == nil && calendar == nil && mediaLibrary == nil
      && photos == nil && reminders == nil && systemPolicyAllFiles == nil
      && systemPolicyDesktopFolder == nil && systemPolicyDeveloperFiles == nil
      && systemPolicyDocumentsFolder == nil && systemPolicyDownloadsFolder == nil
      && systemPolicyNetworkVolumes == nil
  }

  enum CheckError: Error, CustomStringConvertible {
    case accessError([CodingKeys])

    var description: String {
      switch self {
      case .accessError(let keys):
        return "Policy missing access: \(keys.map(\.rawValue).joined(separator: ", "))"
      }
    }
  }

  func check(_ other: Self) throws {
    var errors: [CodingKeys] = []

    // Check AppleEvents separately since it's an array
    if let valueEvents = other.appleEvents {
      if let selfEvents = self.appleEvents {
        if !Set(valueEvents).isSubset(of: Set(selfEvents)) {
          errors.append(.appleEvents)
        }
      } else {
        errors.append(.appleEvents)
      }
    }

    if let value = other.addressBook, value != self.addressBook {
      errors.append(.addressBook)
    }

    if let value = other.calendar, value != self.calendar {
      errors.append(.calendar)
    }

    if let value = other.mediaLibrary, value != self.mediaLibrary {
      errors.append(.mediaLibrary)
    }

    if let value = other.photos, value != self.photos {
      errors.append(.photos)
    }

    if let value = other.reminders, value != self.reminders {
      errors.append(.reminders)
    }

    if let value = other.systemPolicyAllFiles, value != self.systemPolicyAllFiles {
      errors.append(.systemPolicyAllFiles)
    }

    if let value = other.systemPolicyDesktopFolder, value != self.systemPolicyDesktopFolder {
      errors.append(.systemPolicyDesktopFolder)
    }

    if let value = other.systemPolicyDeveloperFiles, value != self.systemPolicyDeveloperFiles {
      errors.append(.systemPolicyDeveloperFiles)
    }

    if let value = other.systemPolicyDocumentsFolder,
      value != self.systemPolicyDocumentsFolder
    {
      errors.append(.systemPolicyDocumentsFolder)
    }

    if let value = other.systemPolicyDownloadsFolder,
      value != self.systemPolicyDownloadsFolder
    {
      errors.append(.systemPolicyDownloadsFolder)
    }

    if let value = other.systemPolicyiCloudDrive, value != self.systemPolicyiCloudDrive {
      errors.append(.systemPolicyiCloudDrive)
    }

    if let value = other.systemPolicyNetworkVolumes, value != self.systemPolicyNetworkVolumes {
      errors.append(.systemPolicyNetworkVolumes)
    }

    if !errors.isEmpty {
      throw CheckError.accessError(errors)
    }
  }
}
