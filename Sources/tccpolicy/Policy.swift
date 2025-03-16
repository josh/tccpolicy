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

  enum CodingKeys: String, CodingKey {
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
    let mirror = Mirror(reflecting: self)
    for child in mirror.children {
      if child.value != nil {
        return false
      }
    }
    return true
  }

  func satisfies(_ other: Self) -> Bool {
    if let selfEvents = self.appleEvents,
      let otherEvents = other.appleEvents,
      !Set(selfEvents).isSubset(of: Set(otherEvents))
    {
      return false
    }

    let mirror = Mirror(reflecting: self)

    for child in mirror.children {
      guard let propertyName = child.label else { continue }

      if propertyName == "appleEvents" { continue }

      guard let value = child.value as? Bool? else { continue }
      if value == nil { continue }

      let otherMirror = Mirror(reflecting: other)
      let otherValue = otherMirror.children.first { $0.label == propertyName }?.value as? Bool?

      if value != otherValue {
        return false
      }
    }

    return true
  }
}
