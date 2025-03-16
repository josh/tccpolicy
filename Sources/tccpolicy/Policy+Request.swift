import EventKit
import Foundation

extension Policy {
  func request() async throws {
    var stderr = StandardErrorStream()

    if self.calendar == true {
      if try await EKEventStore().requestFullAccessToEvents() == false {
        print("warn: Calendar access denied", to: &stderr)
      }
    }

    if self.reminders == true {
      if try await EKEventStore().requestFullAccessToReminders() == false {
        print("warn: Reminders access denied", to: &stderr)
      }
    }
  }
}
