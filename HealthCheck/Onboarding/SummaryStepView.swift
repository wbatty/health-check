import HealthCheckCore
import SwiftUI

/// Step 4: confirm the starting weight, review the plan and set the weekly targets.
struct SummaryStepView: View {
    @Bindable var model: OnboardingModel
    let onFinish: (Plan) -> Void
    @State private var isFinishing = false

    var body: some View {
        let pace = model.finalPace

        StepScaffold {
            VStack(alignment: .leading, spacing: 20) {
                StepHeader(step: 4, total: OnboardingModel.totalSteps, title: "Your starting point")

                startingWeightCard

                if let snapshot = model.snapshot {
                    healthGrid(snapshot)
                }

                planSection(pace)

                targetsSection(pace)
            }
        } footer: {
            VStack(spacing: 4) {
                Button("Start tracking") {
                    isFinishing = true
                    Task {
                        let plan = await model.finish()
                        isFinishing = false
                        onFinish(plan)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isFinishing || !pace.isValid)

                Button("Edit goal") { model.step = .goal }
                    .buttonStyle(QuietButtonStyle())
            }
        }
    }

    // MARK: Starting weight

    @ViewBuilder
    private var startingWeightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let healthWeight = model.healthWeight {
                HStack(alignment: .firstTextBaseline) {
                    Text("Apple Health · 7-day avg weight")
                        .font(.sans(13))
                        .foregroundStyle(Theme.secondary)
                    Spacer()
                    Label("Connected", systemImage: "checkmark")
                        .font(.sans(12))
                        .foregroundStyle(Theme.accent)
                }
                bigWeight(healthWeight)
                HStack(spacing: 6) {
                    segment("Use \(Format.weight(healthWeight)) average", selected: model.useHealthWeight) {
                        model.useHealthWeight = true
                    }
                    segment("Keep \(Format.weight(model.enteredWeight)) I entered", selected: !model.useHealthWeight) {
                        model.useHealthWeight = false
                    }
                }
                .padding(4)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Starting weight")
            } else {
                Text("Starting weight")
                    .font(.sans(13))
                    .foregroundStyle(Theme.secondary)
                bigWeight(model.enteredWeight)
                Text("Connect Apple Health in Settings to start from your 7-day average.")
                    .font(.sans(12))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(16)
        .card()
    }

    private func bigWeight(_ weight: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(Format.weight(weight))
                .font(.mono(48, weight: .medium))
                .tracking(-1.5)
            Text("lb")
                .font(.sans(17))
                .foregroundStyle(Theme.secondary)
        }
    }

    private func segment(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.sans(13, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(selected ? Theme.text : Theme.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(selected ? Theme.control : .clear, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Last 7 days

    private func healthGrid(_ snapshot: HealthSnapshot) -> some View {
        let tiles: [(String, String)] = [
            ("Steps", snapshot.averageSteps.map { Format.whole($0) } ?? "—"),
            ("Kcal eaten", snapshot.averageCaloriesEaten.map { Format.whole($0) } ?? "—"),
            ("BMR", snapshot.averageBMR.map { Format.whole($0) } ?? "—"),
            ("Lean mass", snapshot.averageLeanMass.map { Format.weight($0) } ?? "—")
        ]
        return HStack(spacing: 1) {
            ForEach(tiles, id: \.0) { title, value in
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.sans(11)).foregroundStyle(Theme.secondary)
                    Text(value).font(.mono(15)).lineLimit(1).minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Theme.surface)
                .accessibilityElement(children: .combine)
            }
        }
        .background(Theme.border)
        .card(radius: 16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Last 7 days from Apple Health")
    }

    // MARK: Plan

    private func planSection(_ pace: GoalPace) -> some View {
        let gaining = pace.direction == .gain
        let rows: [(String, String, Bool)] = [
            ("Start → goal", "\(Format.weight(pace.startWeight)) → \(Format.weight(pace.goalWeight)) lb", false),
            (gaining ? "To gain" : "To lose", "\(Format.weight(pace.delta)) lb", false),
            (gaining ? "Weekly gain" : "Weekly loss", "\(Format.rate(pace.weeklyRate)) lb", true),
            ("Goal date", "\(Format.shortDate(model.goalDate(for: pace))) · \(pace.weeks) wks", false),
            ("Check-ins", checkInText, false)
        ]

        return VStack(alignment: .leading, spacing: 8) {
            Text("Your plan").font(.sans(15, weight: .semibold))
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    if index > 0 { RowDivider() }
                    HStack {
                        Text(row.0).font(.sans(14)).foregroundStyle(Theme.secondary)
                        Spacer()
                        Text(row.1)
                            .font(.mono(14))
                            .foregroundStyle(row.2 ? Theme.accent : Theme.text)
                    }
                    .frame(minHeight: 40)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
            .card(radius: 16)
            if model.healthWeight != nil && model.useHealthWeight {
                Text("Rate recalculated to keep your goal date.")
                    .font(.sans(12))
                    .foregroundStyle(Theme.secondary)
            }
        }
    }

    private var checkInText: String {
        let calendar = Calendar.current
        let day = calendar.shortWeekdaySymbols[model.schedule.weekday - 1]
        let time = calendar.date(bySettingHour: model.schedule.hour, minute: model.schedule.minute, second: 0, of: .now) ?? .now
        return "\(day) \(Format.time(time))"
    }

    // MARK: Targets

    private func targetsSection(_ pace: GoalPace) -> some View {
        let goalWord = model.dynamicTargets ? "goal" : "target"

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your targets").font(.sans(15, weight: .semibold))
                Spacer()
                Text("The things you control").font(.sans(12)).foregroundStyle(Theme.secondary)
            }

            Toggle(isOn: $model.dynamicTargets) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Dynamic targets").font(.sans(15))
                    Text(model.dynamicTargets
                         ? "Steps and workouts build toward your goals. Calories are calculated from your results."
                         : "Use your goals as fixed weekly targets from day one.")
                        .font(.sans(12))
                        .foregroundStyle(Theme.secondary)
                }
            }
            .tint(Theme.accent)
            .padding(.vertical, 12)
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .card(radius: 16)

            VStack(spacing: 0) {
                targetRow(
                    title: "Daily steps",
                    caption: nowCaption(goalWord, model.currentSteps.map { Format.whole($0) }),
                    value: Format.whole(model.stepsGoal),
                    decrement: ("minus", "Fewer steps", { model.adjustSteps(by: -Targets.stepsIncrement) }),
                    increment: ("plus", "More steps", { model.adjustSteps(by: Targets.stepsIncrement) }),
                    note: model.dynamicTargets
                        ? (icon: "chart.line.uptrend.xyaxis", text: "This week \(Format.whole(model.firstWeekSteps)) · +500 each week you hit it")
                        : nil
                )
                RowDivider()
                targetRow(
                    title: "Workouts per week",
                    caption: nowCaption(goalWord, model.currentWorkouts.map(days)),
                    value: days(model.workoutsGoal),
                    decrement: ("minus", "Fewer workouts", { model.adjustWorkouts(by: -1) }),
                    increment: ("plus", "More workouts", { model.adjustWorkouts(by: 1) }),
                    note: model.dynamicTargets
                        ? (icon: "chart.line.uptrend.xyaxis", text: "This week \(days(model.firstWeekWorkouts)) · +1 after 2 weeks in a row")
                        : nil
                )
                RowDivider()
                caloriesRow
            }
            .card(radius: 16)

            Text(energyGapText(pace))
                .font(.sans(12))
                .foregroundStyle(Theme.secondary)

            if model.caloriesBelowBMR, let bmr = model.bmr {
                Text("That's below your resting burn (\(Format.whole(bmr)) kcal). Check with a professional before eating this little.")
                    .font(.sans(12))
                    .foregroundStyle(Theme.warning)
            }
        }
    }

    @ViewBuilder
    private var caloriesRow: some View {
        let color = model.caloriesBelowBMR ? Theme.warning : Theme.accent
        let caption = nowCaption(
            model.caloriesAreCalculated ? "calculated" : "target",
            model.currentCalories.map { Format.whole($0) }
        )

        if model.caloriesAreCalculated {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Daily calories").font(.sans(15))
                        RowCaption(text: caption, mono: true)
                    }
                    Spacer()
                    Text("AUTO")
                        .font(.mono(11))
                        .tracking(0.7)
                        .foregroundStyle(Theme.secondary)
                        .padding(.horizontal, 8)
                        .frame(height: 22)
                        .background(Theme.control, in: Capsule())
                    Text(Format.whole(model.activeCalories))
                        .font(.mono(17, weight: .medium))
                        .foregroundStyle(color)
                }
                .frame(minHeight: 44)
                .padding(.trailing, 6)
                noteView(
                    icon: "chart.xyaxis.line",
                    text: "Starting estimate from your BMR. Each check-in recalculates it from your weight trend and calories eaten, and you approve the change."
                )
            }
            .padding(.vertical, 12)
            .padding(.leading, 16)
            .padding(.trailing, 10)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                StepperRow(
                    title: "Daily calories",
                    value: Format.whole(model.manualCalories),
                    valueColor: color,
                    valueFont: .mono(17, weight: .medium),
                    valueWidth: 76,
                    decrement: ("minus", "Fewer calories", { model.adjustCalories(by: -Targets.caloriesIncrement) }),
                    increment: ("plus", "More calories", { model.adjustCalories(by: Targets.caloriesIncrement) })
                ) {
                    RowCaption(text: caption, mono: true)
                }
                .padding(.leading, -16)
                .padding(.trailing, -10)
                if model.dynamicTargets {
                    noteView(
                        icon: "info.circle",
                        text: "Connect Apple Health with basal energy to have calories calculated for you."
                    )
                }
            }
            .padding(.vertical, 12)
            .padding(.leading, 16)
            .padding(.trailing, 10)
        }
    }

    private func targetRow(
        title: String,
        caption: String,
        value: String,
        decrement: (icon: String, label: String, action: () -> Void),
        increment: (icon: String, label: String, action: () -> Void),
        note: (icon: String, text: String)?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            StepperRow(
                title: title,
                value: value,
                valueFont: .mono(17, weight: .medium),
                valueWidth: 76,
                decrement: decrement,
                increment: increment
            ) {
                RowCaption(text: caption, mono: true)
            }
            .padding(.leading, -16)
            .padding(.trailing, -10)
            if let note {
                noteView(icon: note.icon, text: note.text)
            }
        }
        .padding(.vertical, 12)
        .padding(.leading, 16)
        .padding(.trailing, 10)
    }

    private func noteView(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .padding(.top, 1)
                .accessibilityHidden(true)
            Text(text)
                .font(.sans(12))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.trailing, 6)
    }

    // MARK: Helpers

    private func nowCaption(_ word: String, _ now: String?) -> String {
        guard let now else { return word }
        return "\(word) · now \(now)"
    }

    private func days(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }

    private func energyGapText(_ pace: GoalPace) -> String {
        let gap = Int((TargetMath.dailyEnergyGap(weeklyRate: pace.weeklyRate) / 10).rounded()) * 10
        let side = pace.direction == .gain ? "above" : "below"
        let verb = pace.direction == .gain ? "gain" : "loss"
        return "\(Format.rate(pace.weeklyRate)) lb/week \(verb) is roughly \(Format.whole(gap)) kcal/day \(side) what you burn. Targets can be changed anytime in Settings."
    }
}
