import Foundation

public enum WeightDirection: String, Codable, Sendable {
    case lose
    case gain
}

/// The linked weekly rate and goal date from onboarding step 1.
///
/// Changing the rate recomputes the number of weeks; changing the weeks (goal date)
/// recomputes the rate. `pinnedRate` remembers a rate the user picked directly so the
/// rounded week count doesn't nudge it.
public struct GoalPace: Equatable, Sendable {
    public static let rateStep = 0.25
    public static let rateRange: ClosedRange<Double> = 0.25...3.0

    public var startWeight: Double
    public var goalWeight: Double
    public var weeks: Int
    public var pinnedRate: Double?

    public init(startWeight: Double, goalWeight: Double, weeks: Int, pinnedRate: Double? = nil) {
        self.startWeight = startWeight
        self.goalWeight = goalWeight
        self.weeks = max(1, weeks)
        self.pinnedRate = pinnedRate
    }

    public var isValid: Bool {
        startWeight > 0 && goalWeight > 0 && startWeight != goalWeight
    }

    /// Pounds to lose or gain.
    public var delta: Double {
        isValid ? abs(startWeight - goalWeight) : 0
    }

    public var direction: WeightDirection {
        isValid && goalWeight > startWeight ? .gain : .lose
    }

    /// Pounds per week.
    public var weeklyRate: Double {
        pinnedRate ?? delta / Double(weeks)
    }

    /// Faster than 2 lb/week loss or 1 lb/week gain.
    public var isFast: Bool {
        direction == .gain ? weeklyRate > 1 : weeklyRate > 2
    }

    /// The week count for a sensible default pace (1 lb/week loss, 0.5 lb/week gain).
    public var suggestedWeeks: Int {
        let rate = direction == .gain ? 0.5 : 1.0
        return max(1, Int((delta / rate - 1e-9).rounded(.up)))
    }

    public func goalDate(from start: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: weeks * 7, to: start) ?? start
    }

    /// Steps the rate up to the next multiple of `rateStep`.
    public mutating func increaseRate() {
        let step = Self.rateStep
        setRate(((weeklyRate / step) + 1e-9).rounded(.down) * step + step)
    }

    /// Steps the rate down to the previous multiple of `rateStep`.
    public mutating func decreaseRate() {
        let step = Self.rateStep
        setRate(((weeklyRate / step) - 1e-9).rounded(.up) * step - step)
    }

    public mutating func setRate(_ rate: Double) {
        let clamped = min(Self.rateRange.upperBound, max(Self.rateRange.lowerBound, rate))
        pinnedRate = clamped
        weeks = max(1, Int((delta / clamped - 1e-9).rounded(.up)))
    }

    /// Moves the goal date by whole weeks; the rate follows.
    public mutating func shiftGoalDate(byWeeks offset: Int) {
        weeks = max(1, weeks + offset)
        pinnedRate = nil
    }

    /// The same goal date from a different starting weight, with the rate recalculated.
    public func keepingGoalDate(startWeight newStart: Double) -> GoalPace {
        GoalPace(startWeight: newStart, goalWeight: goalWeight, weeks: weeks)
    }
}
