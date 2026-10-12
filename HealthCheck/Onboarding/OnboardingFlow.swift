import HealthCheckCore
import SwiftUI

struct OnboardingFlow: View {
    @State private var model: OnboardingModel
    private let onFinish: (Plan) -> Void

    init(health: HealthKitService, onFinish: @escaping (Plan) -> Void) {
        _model = State(initialValue: OnboardingModel(health: health))
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    if model.step != .goal {
                        Button {
                            model.back()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.secondary)
                        .padding(.leading, -12)
                        .accessibilityLabel("Back")
                    }
                    StepProgress(step: model.step.rawValue, total: OnboardingModel.totalSteps)
                }
                .frame(height: 44)

                Group {
                    switch model.step {
                    case .goal:
                        GoalStepView(model: model)
                    case .health:
                        HealthStepView(model: model)
                    case .schedule:
                        ScheduleStepView(model: model)
                    case .summary:
                        SummaryStepView(model: model, onFinish: onFinish)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .foregroundStyle(Theme.text)
            .background(Theme.background.ignoresSafeArea())
            .animation(.snappy(duration: 0.3), value: model.step)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
