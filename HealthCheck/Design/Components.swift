import SwiftUI

struct StepProgress: View {
    let step: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...total, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Theme.accent : Theme.border)
                    .frame(height: 4)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(step) of \(total)")
    }
}

struct StepHeader: View {
    let step: Int
    let total: Int
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STEP \(step) OF \(total)")
                .font(.mono(12))
                .tracking(1)
                .foregroundStyle(Theme.secondary)
            Text(title)
                .font(.sans(30, weight: .semibold))
                .tracking(-0.6)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(.sans(15))
                    .lineSpacing(3)
                    .foregroundStyle(Theme.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Scrolling step content with the call to action pinned to the bottom.
struct StepScaffold<Content: View, Footer: View>: View {
    private let content: Content
    private let footer: Footer

    init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            footer
                .padding(.top, 12)
        }
    }
}

struct CardModifier: ViewModifier {
    var radius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(Theme.surface, in: shape)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Theme.border, lineWidth: 1))
    }
}

extension View {
    func card(radius: CGFloat = 20) -> some View {
        modifier(CardModifier(radius: radius))
    }
}

struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.border)
            .frame(height: 1)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration)
    }

    private struct StyledLabel: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.sans(16, weight: .semibold))
                .foregroundStyle(isEnabled ? Theme.background : Theme.secondary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    (isEnabled ? Theme.accent : Theme.border).opacity(configuration.isPressed ? 0.8 : 1),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .contentShape(Rectangle())
        }
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sans(15))
            .foregroundStyle(Theme.secondary.opacity(configuration.isPressed ? 0.6 : 1))
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// The square 44pt −/+ and ‹/› buttons used by the steppers.
struct IconStepButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Theme.control, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(Theme.text)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// A labelled value with −/+ (or ‹/›) controls on either side.
struct StepperRow<Caption: View>: View {
    let title: String
    let value: String
    var valueColor: Color = Theme.accent
    var valueFont: Font = .mono(18, weight: .medium)
    var valueWidth: CGFloat = 64
    let decrement: (icon: String, label: String, action: () -> Void)
    let increment: (icon: String, label: String, action: () -> Void)
    @ViewBuilder var caption: Caption

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.sans(15))
                caption
            }
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                IconStepButton(systemImage: decrement.icon, label: decrement.label, action: decrement.action)
                Text(value)
                    .font(valueFont)
                    .foregroundStyle(valueColor)
                    .monospacedDigit()
                    .frame(minWidth: valueWidth)
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(title), \(value)")
                IconStepButton(systemImage: increment.icon, label: increment.label, action: increment.action)
            }
        }
        .frame(minHeight: 64)
        .padding(.leading, 16)
        .padding(.trailing, 10)
    }
}

/// A small caption for a stepper row, such as "lb per week".
struct RowCaption: View {
    let text: String
    var mono = false

    var body: some View {
        Text(text)
            .font(mono ? .mono(11) : .sans(12))
            .foregroundStyle(Theme.secondary)
    }
}
