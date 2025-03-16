import EventKit
import Foundation

extension Policy {
  func request() async throws {
    let eventStore = EKEventStore()

    if self.calendar == true {
      if try await eventStore.requestAccess(to: .event) == false {
        print("warn: Calendar access denied", to: &stderr)
      }
    }

    if self.reminders == true {
      if try await eventStore.requestAccess(to: .reminder) == false {
        print("warn: Reminders access denied", to: &stderr)
      }
    }
  }
}

extension EKEventStore {
  func requestAccess(to entityType: EKEntityType) async throws -> Bool {
    return try await withCheckedThrowingContinuation { continuation in
      self.requestAccess(to: entityType) { granted, error in
        if let error = error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: granted)
        }
      }
    }
  }
}
