import Foundation

/// The weekly targets the user controls: steps, workouts and calories.
public struct Targets: Codable, Equatable, Sendable {
    /// Steps and workouts ramp toward the goals; calories are recalculated at each check-in.
    public var dynamic: Bool
    public var dailySteps: Int
    public var weeklyWorkouts: Int
    public var dailyCalories: Int
    /// True when `dailyCalories` came from the BMR estimate rather than the user.
    public var caloriesCalculated: Bool

    public init(dynamic: Bool, dailySteps: Int, weeklyWorkouts: Int, dailyCalories: Int, caloriesCalculated: Bool) {
        self.dynamic = dynamic
        self.dailySteps = dailySteps
        self.weeklyWorkouts = weeklyWorkouts
        self.dailyCalories = dailyCalories
        self.caloriesCalculated = caloriesCalculated
    }

    public static let stepsRange = 1_000...30_000
    public static let stepsIncrement = 500
    public static let workoutsRange = 0...7
    public static let caloriesRange = 800...5_000
    public static let caloriesIncrement = 50
}

public enum TargetMath {
    /// Light-activity multiplier applied to BMR for the starting burn estimate.
    public static let activityMultiplier = 1.35
    public static let kcalPerPound = 3_500.0

    /// Daily energy gap needed for a weekly rate (1 lb/week ≈ 500 kcal/day).
    public static func dailyEnergyGap(weeklyRate: Double) -> Double {
        weeklyRate * kcalPerPound / 7
    }

    /// Starting calorie target: estimated burn (BMR × light activity) minus the
    /// deficit for the rate (plus the surplus when gaining), rounded to 10 kcal.
    public static func estimatedCalories(bmr: Double, pace: GoalPace) -> Int {
        let gap = dailyEnergyGap(weeklyRate: pace.weeklyRate)
        let burn = bmr * activityMultiplier
        let target = pace.direction == .gain ? burn + gap : burn - gap
        return Int((target / 10).rounded()) * 10
    }

    /// First-week step target: one 500-step increment above where you are now, never past the goal.
    public static func firstWeekSteps(goal: Int, current: Int?) -> Int {
        guard let current, goal > current else { return goal }
        let increment = Targets.stepsIncrement
        let next = ((current + 1) + increment - 1) / increment * increment
        return min(goal, next)
    }

    /// First-week workout target: no more than you already do, never past the goal.
    public static func firstWeekWorkouts(goal: Int, current: Int?) -> Int {
        guard let current else { return goal }
        return min(goal, current)
    }
}
