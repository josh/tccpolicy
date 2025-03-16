import EventKit
import Foundation

extension Policy {
  func request() async throws {
    let eventStore = EKEventStore()

    if self.calendar == true {
      if try await eventStore.requestFullAccessToEvents() == false {
        print("warn: Calendar access denied", to: &stderr)
      }
    }

    if self.reminders == true {
      if try await eventStore.requestFullAccessToReminders() == false {
        print("warn: Reminders access denied", to: &stderr)
      }
    }
  }
}
