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

    var label: String {
      switch self {
      case .addressBook: return "addressBook"
      case .appleEvents: return "appleEvents"
      case .calendar: return "calendar"
      case .mediaLibrary: return "mediaLibrary"
      case .photos: return "photos"
      case .reminders: return "reminders"
      case .systemPolicyAllFiles: return "systemPolicyAllFiles"
      case .systemPolicyDesktopFolder: return "systemPolicyDesktopFolder"
      case .systemPolicyDeveloperFiles: return "systemPolicyDeveloperFiles"
      case .systemPolicyDocumentsFolder: return "systemPolicyDocumentsFolder"
      case .systemPolicyDownloadsFolder: return "systemPolicyDownloadsFolder"
      case .systemPolicyiCloudDrive: return "systemPolicyiCloudDrive"
      case .systemPolicyNetworkVolumes: return "systemPolicyNetworkVolumes"
      }
    }

    static let labelMap: [String: CodingKeys] = CodingKeys.allCases.reduce(into: [:]) {
      (dict, key) in
      dict[key.label] = key
    }
  }

  var isEmpty: Bool {
    let mirror = Mirror(reflecting: self)
    for child in mirror.children {
      let isNil =
        Mirror(reflecting: child.value).displayStyle == .optional
        && Mirror(reflecting: child.value).children.isEmpty
      if !isNil {
        return false
      }
    }
    return true
  }

  enum CheckError: Error, CustomStringConvertible {
    case accessError([CodingKeys])

    var description: String {
      switch self {
      case .accessError(let keys):
        return "Policy missing access: \(keys.map(\.stringValue).joined(separator: ", "))"
      }
    }
  }

  func check(_ other: Self) throws {
    var errors: [CodingKeys] = []

    if let requiredEvents = other.appleEvents {
      if let selfEvents = self.appleEvents {
        if !Set(requiredEvents).isSubset(of: Set(selfEvents)) {
          errors.append(.appleEvents)
        }
      } else {
        errors.append(.appleEvents)
      }
    }

    let selfMirror = Mirror(reflecting: self)
    let otherMirror = Mirror(reflecting: other)

    for otherChild in otherMirror.children {
      guard let label = otherChild.label else {
        fatalError("Unknown label")
      }
      guard let codingKey = CodingKeys.labelMap[label] else {
        fatalError("Unknown label")
      }

      if codingKey == .appleEvents { continue }

      guard let requiredValue = otherChild.value as? Bool? else { continue }
      if requiredValue == nil { continue }

      let selfValue = selfMirror.children.first { $0.label == label }?.value as? Bool?

      if requiredValue != selfValue {
        errors.append(codingKey)
      }
    }

    if !errors.isEmpty {
      throw CheckError.accessError(errors)
    }
  }
}
