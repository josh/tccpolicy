struct Policy: Codable {
  var addressBook: Bool?
  var appleEvents: [String]?
  var calendar: Bool?
  var mediaLibrary: Bool?
  var photos: Bool?
  var reminders: Bool?
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
    case systemPolicyDesktopFolder = "SystemPolicyDesktopFolder"
    case systemPolicyDeveloperFiles = "SystemPolicyDeveloperFiles"
    case systemPolicyDocumentsFolder = "SystemPolicyDocumentsFolder"
    case systemPolicyDownloadsFolder = "SystemPolicyDownloadsFolder"
    case systemPolicyiCloudDrive = "SystemPolicyiCloudDrive"
    case systemPolicyNetworkVolumes = "SystemPolicyNetworkVolumes"
  }

  var isEmpty: Bool {
    return addressBook == nil && appleEvents == nil && calendar == nil && mediaLibrary == nil
      && photos == nil && reminders == nil && systemPolicyDesktopFolder == nil
      && systemPolicyDeveloperFiles == nil && systemPolicyDocumentsFolder == nil
      && systemPolicyDownloadsFolder == nil && systemPolicyiCloudDrive == nil
      && systemPolicyNetworkVolumes == nil
  }
}
