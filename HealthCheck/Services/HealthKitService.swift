import Foundation
import HealthCheckCore
import HealthKit

/// Read-only access to the Apple Health data the weekly check-in uses.
final class HealthKitService {
    private let store = HKHealthStore()

    static let readTypes: Set<HKObjectType> = [
        HKQuantityType(.bodyMass),
        HKQuantityType(.stepCount),
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.basalEnergyBurned),
        HKQuantityType(.leanBodyMass),
        HKObjectType.workoutType()
    ]

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Shows the Health permission sheet. HealthKit never reveals whether read access was
    /// granted, so callers should just query and treat missing data as "not shared".
    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: [], read: Self.readTypes)
    }

    /// Averages over the last seven calendar days, today included.
    func lastSevenDays(endingAt end: Date = .now, calendar: Calendar = .current) async -> HealthSnapshot {
        guard isAvailable else { return HealthSnapshot() }
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: end)) ?? end

        async let weight = average(.bodyMass, unit: .pound(), from: start, to: end)
        async let leanMass = average(.leanBodyMass, unit: .pound(), from: start, to: end)
        async let steps = dailyAverage(.stepCount, unit: .count(), from: start, to: end)
        async let eaten = dailyAverage(.dietaryEnergyConsumed, unit: .kilocalorie(), from: start, to: end)
        async let bmr = dailyAverage(.basalEnergyBurned, unit: .kilocalorie(), from: start, to: end)
        async let workouts = workoutDays(from: start, to: end, calendar: calendar)

        return await HealthSnapshot(
            averageWeight: weight,
            averageSteps: steps,
            averageCaloriesEaten: eaten,
            averageBMR: bmr,
            workoutDays: workouts,
            averageLeanMass: leanMass
        )
    }

    /// Mean of all samples in the range (weigh-ins, lean mass readings).
    private func average(_ id: HKQuantityTypeIdentifier, unit: HKUnit, from start: Date, to end: Date) async -> Double? {
        let predicate = HKSamplePredicate.quantitySample(
            type: HKQuantityType(id),
            predicate: HKQuery.predicateForSamples(withStart: start, end: end)
        )
        let query = HKStatisticsQueryDescriptor(predicate: predicate, options: .discreteAverage)
        guard let statistics = try? await query.result(for: store) else { return nil }
        return statistics.averageQuantity()?.doubleValue(for: unit)
    }

    /// Mean of the daily totals, counting only days that have data.
    private func dailyAverage(_ id: HKQuantityTypeIdentifier, unit: HKUnit, from start: Date, to end: Date) async -> Double? {
        let predicate = HKSamplePredicate.quantitySample(
            type: HKQuantityType(id),
            predicate: HKQuery.predicateForSamples(withStart: start, end: end)
        )
        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: predicate,
            options: .cumulativeSum,
            anchorDate: start,
            intervalComponents: DateComponents(day: 1)
        )
        guard let collection = try? await query.result(for: store) else { return nil }
        let totals = collection.statistics().compactMap { $0.sumQuantity()?.doubleValue(for: unit) }
        guard !totals.isEmpty else { return nil }
        return totals.reduce(0, +) / Double(totals.count)
    }

    /// Number of distinct days with at least one workout.
    private func workoutDays(from start: Date, to end: Date, calendar: Calendar) async -> Int? {
        let query = HKSampleQueryDescriptor(
            predicates: [.workout(HKQuery.predicateForSamples(withStart: start, end: end))],
            sortDescriptors: []
        )
        guard let workouts = try? await query.result(for: store) else { return nil }
        return Set(workouts.map { calendar.startOfDay(for: $0.startDate) }).count
    }
}
