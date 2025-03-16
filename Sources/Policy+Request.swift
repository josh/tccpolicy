import EventKit
import Foundation

extension Policy {
  func request() async throws {
    if self.calendar == true {
      try await EKEventStore().requestFullAccessToEvents()
    }

    if self.reminders == true {
      try await EKEventStore().requestFullAccessToReminders()
    }
  }
}
