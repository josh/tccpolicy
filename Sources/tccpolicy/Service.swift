// strings /System/Library/PrivateFrameworks/TCC.framework/Support/tccd | \
//   fgrep kTCCService | fgrep -v ' ' | sed -e s/kTCCService// | sort
enum Service: String, CaseIterable {
  case AddressBook
  case AppleEvents
  case Calendar
  case ContactsFull
  case ContactsLimited
  case FileProviderDomain
  case MediaLibrary
  case Photos
  case PhotosAdd
  case Reminders
  case SystemPolicyAllFiles
  case SystemPolicyDesktopFolder
  case SystemPolicyDeveloperFiles
  case SystemPolicyDocumentsFolder
  case SystemPolicyDownloadsFolder
  case SystemPolicyNetworkVolumes
  case SystemPolicyRemovableVolumes
  case SystemPolicySysAdminFiles
  case Ubiquity
}

extension Service {
  var tccServiceConstant: String {
    return "kTCCService\(self)"
  }
}
