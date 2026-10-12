import SwiftUI

/// Colors and type from the "Weekly Check-In" design canvas.
enum Theme {
    static let background = Color(hex: 0x0B0C0E)
    static let surface = Color(hex: 0x15171A)
    static let control = Color(hex: 0x1C1F23)
    static let border = Color(hex: 0x25282D)
    static let text = Color(hex: 0xF1F1EE)
    static let secondary = Color(hex: 0x9BA0A8)
    static let accent = Color(hex: 0x9DBBFF)
    static let warning = Color(hex: 0xF0A35E)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension Font {
    /// Numbers and labels set in the design's mono face. Uses the system mono until Geist Mono is bundled.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

enum Format {
    static func weight(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    static func rate(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    static func whole(_ value: Double) -> String {
        Int(value.rounded()).formatted(.number)
    }

    static func whole(_ value: Int) -> String {
        value.formatted(.number)
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
