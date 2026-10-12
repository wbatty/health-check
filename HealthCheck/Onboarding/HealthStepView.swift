import SwiftUI

/// Step 2: explain what's read from Apple Health and ask for access.
struct HealthStepView: View {
    @Bindable var model: OnboardingModel

    private struct DataType: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    private let dataTypes = [
        DataType(icon: "scalemass", title: "Body weight", detail: "7-day average of weigh-ins"),
        DataType(icon: "figure.walk", title: "Steps", detail: "7-day daily average"),
        DataType(icon: "fork.knife", title: "Calories eaten", detail: "Dietary energy, 7-day daily average"),
        DataType(icon: "flame", title: "Basal energy (BMR)", detail: "7-day daily average"),
        DataType(icon: "waveform.path.ecg", title: "Workouts", detail: "Days with at least one workout"),
        DataType(icon: "figure.stand", title: "Lean body mass", detail: "Optional, if your scale records it")
    ]

    var body: some View {
        StepScaffold {
            VStack(alignment: .leading, spacing: 28) {
                StepHeader(
                    step: 2,
                    total: OnboardingModel.totalSteps,
                    title: "Connect Apple Health",
                    subtitle: "Read-only. Nothing is written back to Health, and nothing leaves your phone."
                )

                VStack(spacing: 0) {
                    ForEach(Array(dataTypes.enumerated()), id: \.element.id) { index, type in
                        if index > 0 { RowDivider() }
                        HStack(spacing: 14) {
                            Image(systemName: type.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 32, height: 32)
                                .background(Theme.control, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.title).font(.sans(15))
                                Text(type.detail).font(.sans(12)).foregroundStyle(Theme.secondary)
                            }
                            Spacer()
                        }
                        .frame(minHeight: 60)
                        .padding(.horizontal, 16)
                        .accessibilityElement(children: .combine)
                    }
                }
                .card()

                if !model.healthAvailable {
                    Text("Apple Health isn't available on this device. You can still enter your numbers by hand.")
                        .font(.sans(13))
                        .foregroundStyle(Theme.warning)
                }
            }
        } footer: {
            VStack(spacing: 10) {
                Button {
                    Task {
                        await model.connectHealth()
                        model.advance()
                    }
                } label: {
                    if model.isLoadingHealth {
                        ProgressView().tint(Theme.background)
                    } else {
                        Text("Allow access")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!model.healthAvailable || model.isLoadingHealth)

                Button("Not now") { model.advance() }
                    .buttonStyle(QuietButtonStyle())
                    .disabled(model.isLoadingHealth)
            }
        }
    }
}
