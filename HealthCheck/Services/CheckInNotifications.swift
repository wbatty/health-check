import Foundation
import HealthCheckCore
import UserNotifications

/// Local reminders for the weekly check-in.
enum CheckInNotifications {
    private static let idPrefix = "checkin."
    /// iOS keeps at most 64 pending requests per app; a quarter of reminders is plenty
    /// as long as the app re-schedules when the week is locked.
    static let scheduledWeeks = 12

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func schedule(_ schedule: CheckInSchedule, startDate: Date, calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
        )

        let dates = schedule.upcoming(startingFrom: startDate, count: scheduledWeeks, calendar: calendar)
        for (index, date) in dates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Week \(index + 1) check-in"
            content.body = "Weigh in, then review and lock the week."
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "\(idPrefix)\(index)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
