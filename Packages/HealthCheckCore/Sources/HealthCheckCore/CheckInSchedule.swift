import Foundation

/// When the weekly check-in happens. `weekday` follows `Calendar`: 1 = Sunday … 7 = Saturday.
public struct CheckInSchedule: Codable, Equatable, Sendable {
    public var weekday: Int
    public var hour: Int
    public var minute: Int

    public static let `default` = CheckInSchedule(weekday: 2, hour: 7, minute: 0)

    public init(weekday: Int, hour: Int, minute: Int) {
        self.weekday = weekday
        self.hour = hour
        self.minute = minute
    }

    /// The check-in that closes week 1: the first matching weekday and time
    /// at least seven days after the start date.
    public func firstCheckIn(startingFrom start: Date, calendar: Calendar = .current) -> Date {
        let startOfDay = calendar.startOfDay(for: start)
        let earliest = calendar.date(byAdding: .day, value: 7, to: startOfDay) ?? startOfDay
        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        // `nextDate(after:)` is exclusive, so step back a second to allow `earliest` itself.
        return calendar.nextDate(
            after: earliest.addingTimeInterval(-1),
            matching: components,
            matchingPolicy: .nextTime
        ) ?? earliest
    }

    /// `count` weekly check-ins, starting with the one that closes week 1.
    public func upcoming(startingFrom start: Date, count: Int, calendar: Calendar = .current) -> [Date] {
        let first = firstCheckIn(startingFrom: start, calendar: calendar)
        return (0..<max(0, count)).compactMap { calendar.date(byAdding: .day, value: 7 * $0, to: first) }
    }
}
