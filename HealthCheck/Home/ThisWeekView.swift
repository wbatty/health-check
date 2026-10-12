import HealthCheckCore
import SwiftUI

/// Placeholder for the "This week" screen until the weekly loop is built.
struct ThisWeekView: View {
    @Environment(AppModel.self) private var app
    let plan: Plan

    var body: some View {
        let pace = plan.pace

        VStack(alignment: .leading, spacing: 16) {
            Text("WEEK 1")
                .font(.mono(12))
                .tracking(1)
                .foregroundStyle(Theme.secondary)
            Text("This week")
                .font(.sans(30, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("\(Format.weight(pace.startWeight)) → \(Format.weight(pace.goalWeight)) lb")
                    .font(.mono(22, weight: .medium))
                Text("\(Format.rate(pace.weeklyRate)) lb/week · goal \(Format.shortDate(pace.goalDate(from: plan.startDate)))")
                    .font(.sans(13))
                    .foregroundStyle(Theme.secondary)
                Text("First check-in \(plan.checkIn.firstCheckIn(startingFrom: plan.startDate).formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))")
                    .font(.sans(13))
                    .foregroundStyle(Theme.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .card()

            Spacer()

            #if DEBUG
            Button("Restart onboarding") { app.resetPlan() }
                .buttonStyle(QuietButtonStyle())
            #endif
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .foregroundStyle(Theme.text)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background.ignoresSafeArea())
    }
}
