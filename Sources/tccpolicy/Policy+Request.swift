import Contacts
import EventKit
import Foundation
import Photos

extension Policy {
  func request() async throws {
    var stderr = StandardErrorStream()

    if self.calendar == true {
      if try await EKEventStore()._requestFullAccessToEvents() == false {
        print("warn: Calendar access denied", to: &stderr)
      }
    }

    if self.addressBook == true {
      if await CNContactStore().requestAccess() == false {
        print("warn: Contacts access denied", to: &stderr)
      }
    }

    if self.mediaLibrary == true {
      if try await requestMediaAppleMusicAccess() == false {
        print("warn: Media Library access denied", to: &stderr)
      }
    }

    if self.photos == true {
      if await PHPhotoLibrary.requestAccess() == false {
        print("warn: Photos access denied", to: &stderr)
      }
    }

    if self.reminders == true {
      if try await EKEventStore()._requestFullAccessToReminders() == false {
        print("warn: Reminders access denied", to: &stderr)
      }
    }
  }

  private func requestMediaAppleMusicAccess() async throws -> Bool {
    let fileManager = FileManager.default
    let musicLibraryURL = fileManager.homeDirectoryForCurrentUser
      .appendingPathComponent("Music")
      .appendingPathComponent("Music")
      .appendingPathComponent("Media.localized")
    try fileManager.contentsOfDirectory(at: musicLibraryURL, includingPropertiesForKeys: nil)
    return true
  }
}

extension CNContactStore {
  func requestAccess() async -> Bool {
    await withCheckedContinuation { continuation in
      requestAccess(for: .contacts) { granted, _ in
        continuation.resume(returning: granted)
      }
    }
  }
}

extension PHPhotoLibrary {
  static func requestAccess() async -> Bool {
    await withCheckedContinuation { continuation in
      requestAuthorization { status in
        continuation.resume(returning: status == .authorized)
      }
    }
  }
}

extension EKEventStore {
  func _requestFullAccessToEvents() async throws -> Bool {
    // if #available(macOS 14.0, *) {
    //   return try await self.requestFullAccessToEvents()
    // } else {
    return try await withCheckedThrowingContinuation { continuation in
      self.requestAccess(to: .event) { granted, error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: granted)
        }
      }
    }
    // }
  }

  func _requestFullAccessToReminders() async throws -> Bool {
    // if #available(macOS 14.0, *) {
    //   return try await self.requestFullAccessToReminders()
    // } else {
    return try await withCheckedThrowingContinuation { continuation in
      self.requestAccess(to: .reminder) { granted, error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: granted)
        }
      }
    }
    // }
  }
}
