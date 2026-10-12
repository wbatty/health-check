import Foundation
import HealthCheckCore
import Observation

/// App-wide state: the saved plan (nil until onboarding finishes) and shared services.
@MainActor
@Observable
final class AppModel {
    private static let planKey = "plan.v1"

    let health = HealthKitService()
    private(set) var plan: Plan?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.planKey) {
            plan = try? JSONDecoder().decode(Plan.self, from: data)
        }
    }

    func complete(with plan: Plan) {
        self.plan = plan
        if let data = try? JSONEncoder().encode(plan) {
            defaults.set(data, forKey: Self.planKey)
        }
    }

    func resetPlan() {
        plan = nil
        defaults.removeObject(forKey: Self.planKey)
    }
}
