import Foundation
import HealthCheckCore
import Observation

/// State for the four onboarding steps: goal → Apple Health → check-in schedule → summary.
@MainActor
@Observable
final class OnboardingModel {
    enum Step: Int, CaseIterable {
        case goal = 1
        case health
        case schedule
        case summary
    }

    static let totalSteps = Step.allCases.count
    static let weightRange: ClosedRange<Double> = 50...1_000

    let health: HealthKitService
    let startDate: Date
    var step: Step = .goal

    // MARK: Step 1 · goal

    private(set) var startWeightText = ""
    private(set) var goalWeightText = ""
    /// nil until the user touches the pace; until then it follows a sensible default rate.
    private var weeksOverride: Int?
    private var pinnedRate: Double?

    // MARK: Step 2 · Apple Health

    private(set) var isLoadingHealth = false
    private(set) var snapshot: HealthSnapshot?

    // MARK: Step 3 · schedule

    var schedule = CheckInSchedule.default
    private(set) var notificationsEnabled = false

    // MARK: Step 4 · summary

    var useHealthWeight = true
    var dynamicTargets = true
    var stepsGoal = 10_000
    var workoutsGoal = 4
    var manualCalories = 2_000

    init(health: HealthKitService, startDate: Date = .now) {
        self.health = health
        self.startDate = startDate
    }

    // MARK: Navigation

    func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    // MARK: Goal

    var pace: GoalPace {
        var pace = GoalPace(
            startWeight: Self.parse(startWeightText) ?? 0,
            goalWeight: Self.parse(goalWeightText) ?? 0,
            weeks: 1
        )
        pace.weeks = weeksOverride ?? pace.suggestedWeeks
        pace.pinnedRate = pinnedRate
        return pace
    }

    var canContinueFromGoal: Bool {
        guard let start = Self.parse(startWeightText), let goal = Self.parse(goalWeightText) else { return false }
        return Self.weightRange.contains(start) && Self.weightRange.contains(goal) && pace.isValid
    }

    func setStartWeightText(_ text: String) {
        startWeightText = text
        pinnedRate = nil
    }

    func setGoalWeightText(_ text: String) {
        goalWeightText = text
        pinnedRate = nil
    }

    func goalDate(for pace: GoalPace) -> Date {
        pace.goalDate(from: startDate)
    }

    func increaseRate() { updatePace { $0.increaseRate() } }
    func decreaseRate() { updatePace { $0.decreaseRate() } }
    func goalDateLater() { updatePace { $0.shiftGoalDate(byWeeks: 1) } }
    func goalDateEarlier() { updatePace { $0.shiftGoalDate(byWeeks: -1) } }

    private func updatePace(_ change: (inout GoalPace) -> Void) {
        var next = pace
        guard next.isValid else { return }
        change(&next)
        weeksOverride = next.weeks
        pinnedRate = next.pinnedRate
    }

    static func parse(_ text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }

    // MARK: Apple Health

    var healthAvailable: Bool { health.isAvailable }

    func connectHealth() async {
        isLoadingHealth = true
        defer { isLoadingHealth = false }
        do {
            try await health.requestAuthorization()
            let snapshot = await health.lastSevenDays(endingAt: .now)
            self.snapshot = snapshot.isEmpty ? nil : snapshot
        } catch {
            snapshot = nil
        }
    }

    // MARK: Schedule

    var firstCheckIn: Date {
        schedule.firstCheckIn(startingFrom: startDate)
    }

    func enableNotifications() async {
        notificationsEnabled = await CheckInNotifications.requestPermission()
    }

    // MARK: Summary

    var healthWeight: Double? { snapshot?.averageWeight }

    var enteredWeight: Double { pace.startWeight }

    var chosenStartWeight: Double {
        if useHealthWeight, let healthWeight { return healthWeight }
        return enteredWeight
    }

    /// The final plan keeps the goal date and recalculates the rate from the chosen start weight.
    var finalPace: GoalPace {
        pace.keepingGoalDate(startWeight: chosenStartWeight)
    }

    var bmr: Double? { snapshot?.averageBMR }

    var estimatedCalories: Int? {
        bmr.map { TargetMath.estimatedCalories(bmr: $0, pace: finalPace) }
    }

    /// Calories are calculated only when targets are dynamic and there's a BMR to start from.
    var caloriesAreCalculated: Bool {
        dynamicTargets && estimatedCalories != nil
    }

    var activeCalories: Int {
        caloriesAreCalculated ? (estimatedCalories ?? manualCalories) : manualCalories
    }

    var caloriesBelowBMR: Bool {
        guard let bmr else { return false }
        return Double(activeCalories) < bmr
    }

    var currentSteps: Int? { snapshot?.averageSteps.map { Int($0.rounded()) } }
    var currentWorkouts: Int? { snapshot?.workoutDays }
    var currentCalories: Int? { snapshot?.averageCaloriesEaten.map { Int($0.rounded()) } }

    var firstWeekSteps: Int { TargetMath.firstWeekSteps(goal: stepsGoal, current: currentSteps) }
    var firstWeekWorkouts: Int { TargetMath.firstWeekWorkouts(goal: workoutsGoal, current: currentWorkouts) }

    func adjustSteps(by delta: Int) {
        stepsGoal = (stepsGoal + delta).clamped(to: Targets.stepsRange)
    }

    func adjustWorkouts(by delta: Int) {
        workoutsGoal = (workoutsGoal + delta).clamped(to: Targets.workoutsRange)
    }

    func adjustCalories(by delta: Int) {
        manualCalories = (manualCalories + delta).clamped(to: Targets.caloriesRange)
    }

    func makePlan() -> Plan {
        let pace = finalPace
        return Plan(
            startDate: startDate,
            startWeight: pace.startWeight,
            goalWeight: pace.goalWeight,
            weeks: pace.weeks,
            checkIn: schedule,
            targets: Targets(
                dynamic: dynamicTargets,
                dailySteps: stepsGoal,
                weeklyWorkouts: workoutsGoal,
                dailyCalories: activeCalories,
                caloriesCalculated: caloriesAreCalculated
            ),
            notificationsEnabled: notificationsEnabled
        )
    }

    func finish() async -> Plan {
        let plan = makePlan()
        if plan.notificationsEnabled {
            await CheckInNotifications.schedule(plan.checkIn, startDate: plan.startDate)
        }
        return plan
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(range.upperBound, max(range.lowerBound, self))
    }
}
