import Foundation
import UserNotifications

@Observable
@MainActor
class NotificationService {
    var isAuthorized: Bool = false

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    func scheduleFlightReminder(flightNumber: String, departureTime: Date) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Flight Update"
        content.body = "Your turbulence forecast for \(flightNumber) has been updated. Tap to check."
        content.sound = .default

        let reminderDate = departureTime.addingTimeInterval(-3600 * 3)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "flight-\(flightNumber)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
