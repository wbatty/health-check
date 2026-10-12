import HealthCheckCore
import SwiftUI

/// Step 1: start and goal weight, with a linked weekly rate and goal date.
struct GoalStepView: View {
    @Bindable var model: OnboardingModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case start, goal
    }

    var body: some View {
        let pace = model.pace

        StepScaffold {
            VStack(alignment: .leading, spacing: 24) {
                StepHeader(
                    step: 1,
                    total: OnboardingModel.totalSteps,
                    title: "Set your goal",
                    subtitle: "Set a weekly rate or a goal date. The other one adjusts to match."
                )

                VStack(spacing: 0) {
                    weightRow(
                        "Starting weight",
                        text: Binding(get: { model.startWeightText }, set: { model.setStartWeightText($0) }),
                        field: .start
                    )
                    RowDivider()
                    weightRow(
                        "Goal weight",
                        text: Binding(get: { model.goalWeightText }, set: { model.setGoalWeightText($0) }),
                        field: .goal
                    )
                    RowDivider()
                    HStack {
                        Text("Start date").font(.sans(15))
                        Spacer()
                        Text(Format.shortDate(model.startDate))
                            .font(.mono(15))
                            .foregroundStyle(Theme.secondary)
                    }
                    .frame(minHeight: 56)
                    .padding(.horizontal, 16)
                }
                .card()

                VStack(spacing: 0) {
                    StepperRow(
                        title: pace.direction == .gain ? "Weekly gain" : "Weekly loss",
                        value: Format.rate(pace.weeklyRate),
                        valueColor: pace.isFast ? Theme.warning : Theme.accent,
                        decrement: ("minus", "Decrease weekly rate", { model.decreaseRate() }),
                        increment: ("plus", "Increase weekly rate", { model.increaseRate() })
                    ) {
                        RowCaption(text: "lb per week")
                    }
                    RowDivider()
                    StepperRow(
                        title: "Goal date",
                        value: Format.shortDate(model.goalDate(for: pace)),
                        valueColor: Theme.text,
                        valueFont: .mono(15, weight: .medium),
                        valueWidth: 108,
                        decrement: ("chevron.left", "One week earlier", { model.goalDateEarlier() }),
                        increment: ("chevron.right", "One week later", { model.goalDateLater() })
                    ) {
                        RowCaption(text: "\(pace.weeks) weeks")
                    }
                }
                .card()
                .disabled(!pace.isValid)
                .opacity(pace.isValid ? 1 : 0.5)

                if pace.isValid {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .font(.system(size: 13))
                                .accessibilityHidden(true)
                            Text("\(pace.direction == .gain ? "To gain" : "To lose") ")
                                + Text("\(Format.weight(pace.delta)) lb").font(.mono(13)).foregroundColor(Theme.text)
                                + Text(" · rate and date are linked")
                        }
                        .font(.sans(13))
                        .foregroundStyle(Theme.secondary)

                        if pace.isFast {
                            Text("That's a fast pace. A later goal date makes it more sustainable.")
                                .font(.sans(13))
                                .foregroundStyle(Theme.warning)
                        }
                    }
                }
            }
        } footer: {
            Button("Continue") {
                focusedField = nil
                model.advance()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!model.canContinueFromGoal)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }

    private func weightRow(_ title: String, text: Binding<String>, field: Field) -> some View {
        HStack {
            Text(title).font(.sans(15))
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("", text: text, prompt: Text("0.0").foregroundColor(Theme.secondary.opacity(0.6)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.mono(17))
                    .frame(width: 80, height: 44)
                    .focused($focusedField, equals: field)
                    .accessibilityLabel("\(title) in pounds")
                Text("lb")
                    .font(.sans(13))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .frame(minHeight: 56)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture { focusedField = field }
    }
}
