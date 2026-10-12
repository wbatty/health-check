import XCTest
@testable import HealthCheckCore

final class GoalPaceTests: XCTestCase {
    func testRateFollowsWeeks() {
        let pace = GoalPace(startWeight: 212.5, goalWeight: 185, weeks: 25)
        XCTAssertEqual(pace.delta, 27.5, accuracy: 1e-9)
        XCTAssertEqual(pace.weeklyRate, 1.1, accuracy: 1e-9)
        XCTAssertEqual(pace.direction, .lose)
        XCTAssertFalse(pace.isFast)
    }

    func testIncreaseRateSnapsToNextStepAndRecomputesWeeks() {
        var pace = GoalPace(startWeight: 212.5, goalWeight: 185, weeks: 25)
        pace.increaseRate()
        XCTAssertEqual(pace.weeklyRate, 1.25, accuracy: 1e-9)
        XCTAssertEqual(pace.weeks, 22)
    }

    func testDecreaseRateSnapsToPreviousStep() {
        var pace = GoalPace(startWeight: 212.5, goalWeight: 185, weeks: 25)
        pace.decreaseRate()
        XCTAssertEqual(pace.weeklyRate, 1.0, accuracy: 1e-9)
        XCTAssertEqual(pace.weeks, 28)
    }

    func testRateIsClamped() {
        var pace = GoalPace(startWeight: 200, goalWeight: 190, weeks: 40)
        pace.decreaseRate()
        pace.decreaseRate()
        XCTAssertEqual(pace.weeklyRate, 0.25, accuracy: 1e-9)
        pace.setRate(10)
        XCTAssertEqual(pace.weeklyRate, 3, accuracy: 1e-9)
    }

    func testShiftingGoalDateUnpinsRate() {
        var pace = GoalPace(startWeight: 212.5, goalWeight: 185, weeks: 25)
        pace.increaseRate()
        pace.shiftGoalDate(byWeeks: 1)
        XCTAssertNil(pace.pinnedRate)
        XCTAssertEqual(pace.weeks, 23)
        XCTAssertEqual(pace.weeklyRate, 27.5 / 23, accuracy: 1e-9)
    }

    func testFastWarningThresholds() {
        XCTAssertTrue(GoalPace(startWeight: 220, goalWeight: 200, weeks: 8).isFast)   // 2.5 lb/wk loss
        XCTAssertFalse(GoalPace(startWeight: 220, goalWeight: 200, weeks: 10).isFast) // 2.0 lb/wk loss
        XCTAssertTrue(GoalPace(startWeight: 150, goalWeight: 160, weeks: 8).isFast)   // 1.25 lb/wk gain
        XCTAssertEqual(GoalPace(startWeight: 150, goalWeight: 160, weeks: 8).direction, .gain)
    }

    func testInvalidPace() {
        let pace = GoalPace(startWeight: 0, goalWeight: 185, weeks: 10)
        XCTAssertFalse(pace.isValid)
        XCTAssertEqual(pace.delta, 0)
    }

    func testSuggestedWeeks() {
        XCTAssertEqual(GoalPace(startWeight: 212.5, goalWeight: 185, weeks: 1).suggestedWeeks, 28)
        XCTAssertEqual(GoalPace(startWeight: 150, goalWeight: 160, weeks: 1).suggestedWeeks, 20)
    }

    func testKeepingGoalDateRecalculatesRate() {
        let pace = GoalPace(startWeight: 212.5, goalWeight: 185, weeks: 25)
        let adjusted = pace.keepingGoalDate(startWeight: 212.0)
        XCTAssertEqual(adjusted.weeks, 25)
        XCTAssertEqual(adjusted.weeklyRate, 1.08, accuracy: 1e-9)
    }
}

final class CheckInScheduleTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    func testFirstCheckInClosesWeekOne() {
        let start = date(2026, 7, 6, 15, 30) // Monday afternoon
        let first = CheckInSchedule.default.firstCheckIn(startingFrom: start, calendar: calendar)
        XCTAssertEqual(first, date(2026, 7, 13, 7, 0))
    }

    func testFirstCheckInOnOtherWeekdayIsAtLeastSevenDaysOut() {
        let start = date(2026, 7, 6) // Monday
        let thursday = CheckInSchedule(weekday: 5, hour: 18, minute: 30)
        XCTAssertEqual(thursday.firstCheckIn(startingFrom: start, calendar: calendar), date(2026, 7, 16, 18, 30))
    }

    func testUpcomingIsWeekly() {
        let dates = CheckInSchedule.default.upcoming(startingFrom: date(2026, 7, 6), count: 3, calendar: calendar)
        XCTAssertEqual(dates, [date(2026, 7, 13, 7), date(2026, 7, 20, 7), date(2026, 7, 27, 7)])
    }
}

final class TargetMathTests: XCTestCase {
    func testEstimatedCaloriesForLoss() {
        let pace = GoalPace(startWeight: 212.0, goalWeight: 185, weeks: 25) // 1.08 lb/wk
        XCTAssertEqual(TargetMath.estimatedCalories(bmr: 1912, pace: pace), 2040)
    }

    func testEstimatedCaloriesForGain() {
        let pace = GoalPace(startWeight: 150, goalWeight: 160, weeks: 20) // 0.5 lb/wk
        XCTAssertEqual(TargetMath.estimatedCalories(bmr: 1600, pace: pace), 2410)
    }

    func testFirstWeekStepsRampsOneIncrement() {
        XCTAssertEqual(TargetMath.firstWeekSteps(goal: 10_000, current: 8_105), 8_500)
        XCTAssertEqual(TargetMath.firstWeekSteps(goal: 8_200, current: 8_105), 8_200)
        XCTAssertEqual(TargetMath.firstWeekSteps(goal: 6_000, current: 8_105), 6_000)
        XCTAssertEqual(TargetMath.firstWeekSteps(goal: 10_000, current: nil), 10_000)
    }

    func testFirstWeekWorkouts() {
        XCTAssertEqual(TargetMath.firstWeekWorkouts(goal: 4, current: 3), 3)
        XCTAssertEqual(TargetMath.firstWeekWorkouts(goal: 2, current: 3), 2)
        XCTAssertEqual(TargetMath.firstWeekWorkouts(goal: 4, current: nil), 4)
    }
}
