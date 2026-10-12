import SwiftUI

/// Step 3: pick the weekday and time the week locks, then ask for notification permission.
struct ScheduleStepView: View {
    @Bindable var model: OnboardingModel
    @State private var isRequesting = false

    private let calendar = Calendar.current

    var body: some View {
        StepScaffold {
            VStack(alignment: .leading, spacing: 28) {
                StepHeader(
                    step: 3,
                    total: OnboardingModel.totalSteps,
                    title: "When should we check in?",
                    subtitle: "Weigh in first. At this time we'll lock the week and ask how it went."
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Day").font(.sans(13)).foregroundStyle(Theme.secondary)
                    HStack(spacing: 6) {
                        ForEach(1...7, id: \.self) { weekday in
                            dayButton(weekday)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Time").font(.sans(13)).foregroundStyle(Theme.secondary)
                    DatePicker("Check-in time", selection: time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .clipped()
                        .card()
                }

                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "bell")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Every \(weekdayName) at \(Format.time(timeOfDay))")
                            .font(.sans(15))
                        Text("Your first check-in is \(firstCheckInText), closing out week 1.")
                            .font(.sans(13))
                            .foregroundStyle(Theme.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .card(radius: 16)
            }
        } footer: {
            VStack(spacing: 4) {
                Button {
                    isRequesting = true
                    Task {
                        await model.enableNotifications()
                        isRequesting = false
                        model.advance()
                    }
                } label: {
                    Text("Turn on notifications")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isRequesting)

                Button("Skip reminders") { model.advance() }
                    .buttonStyle(QuietButtonStyle())
                    .disabled(isRequesting)
            }
        }
    }

    private func dayButton(_ weekday: Int) -> some View {
        let selected = model.schedule.weekday == weekday
        return Button {
            model.schedule.weekday = weekday
        } label: {
            Text(calendar.veryShortStandaloneWeekdaySymbols[weekday - 1])
                .font(.sans(14, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? Theme.background : Theme.secondary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(selected ? Theme.accent : Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(selected ? Theme.accent : Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(calendar.weekdaySymbols[weekday - 1])
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var weekdayName: String {
        calendar.weekdaySymbols[model.schedule.weekday - 1]
    }

    private var timeOfDay: Date {
        calendar.date(bySettingHour: model.schedule.hour, minute: model.schedule.minute, second: 0, of: .now) ?? .now
    }

    private var time: Binding<Date> {
        Binding(
            get: { timeOfDay },
            set: { date in
                let components = calendar.dateComponents([.hour, .minute], from: date)
                model.schedule.hour = components.hour ?? 7
                model.schedule.minute = components.minute ?? 0
            }
        )
    }

    private var firstCheckInText: String {
        model.firstCheckIn.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}
