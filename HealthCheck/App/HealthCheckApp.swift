import SwiftUI

@main
struct HealthCheckApp: App {
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Group {
            if let plan = app.plan {
                ThisWeekView(plan: plan)
            } else {
                OnboardingFlow(health: app.health) { plan in
                    app.complete(with: plan)
                }
            }
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
    }
}
