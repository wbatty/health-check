import Foundation

/// Seven-day averages read from Apple Health. Any value can be missing.
public struct HealthSnapshot: Equatable, Sendable {
    public var averageWeight: Double?
    public var averageSteps: Double?
    public var averageCaloriesEaten: Double?
    public var averageBMR: Double?
    public var workoutDays: Int?
    public var averageLeanMass: Double?

    public init(
        averageWeight: Double? = nil,
        averageSteps: Double? = nil,
        averageCaloriesEaten: Double? = nil,
        averageBMR: Double? = nil,
        workoutDays: Int? = nil,
        averageLeanMass: Double? = nil
    ) {
        self.averageWeight = averageWeight
        self.averageSteps = averageSteps
        self.averageCaloriesEaten = averageCaloriesEaten
        self.averageBMR = averageBMR
        self.workoutDays = workoutDays
        self.averageLeanMass = averageLeanMass
    }

    public var isEmpty: Bool {
        averageWeight == nil && averageSteps == nil && averageCaloriesEaten == nil
            && averageBMR == nil && workoutDays == nil && averageLeanMass == nil
    }
}

/// Everything onboarding produces. Weights are in pounds.
public struct Plan: Codable, Equatable, Sendable {
    public var startDate: Date
    public var startWeight: Double
    public var goalWeight: Double
    public var weeks: Int
    public var checkIn: CheckInSchedule
    public var targets: Targets
    public var notificationsEnabled: Bool

    public init(
        startDate: Date,
        startWeight: Double,
        goalWeight: Double,
        weeks: Int,
        checkIn: CheckInSchedule,
        targets: Targets,
        notificationsEnabled: Bool
    ) {
        self.startDate = startDate
        self.startWeight = startWeight
        self.goalWeight = goalWeight
        self.weeks = weeks
        self.checkIn = checkIn
        self.targets = targets
        self.notificationsEnabled = notificationsEnabled
    }

    public var pace: GoalPace {
        GoalPace(startWeight: startWeight, goalWeight: goalWeight, weeks: weeks)
    }
}
