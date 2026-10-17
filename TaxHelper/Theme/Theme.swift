import SwiftUI

// Colours approximate the Taxfix brand (Project context §11b).
// Meaning stays fixed: green = money, lilac = AI, gold = moments that matter, blue = official / expert.
extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static let green100 = Color(hex: 0xE3F5EC)
    static let green500 = Color(hex: 0x00B26B)
    static let green800 = Color(hex: 0x0B3D2E)
    static let lilac100 = Color(hex: 0xF1ECFD)
    static let lilac400 = Color(hex: 0xB9A6F0)
    static let lilac700 = Color(hex: 0x5B45A8)
    static let gold400 = Color(hex: 0xF2C14E)
    static let gold100 = Color(hex: 0xFDF3DC)
    static let blue500 = Color(hex: 0x3D6FE0)
    static let blue100 = Color(hex: 0xE6EDFC)
    static let ink900 = Color(hex: 0x14171A)
    static let ink500 = Color(hex: 0x6B7178)
    static let paper = Color(hex: 0xFAF8F4)
    static let surface = Color.white
    static let border = Color(hex: 0xEAE6DF)
    static let danger = Color(hex: 0xD64545)
}

enum Space {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

extension Font {
    static let display = Font.system(size: 52, weight: .semibold, design: .rounded).monospacedDigit()
    static let title = Font.system(size: 28, weight: .semibold)
    static let heading = Font.system(size: 20, weight: .semibold)
    static let body17 = Font.system(size: 17)
    static let caption13 = Font.system(size: 13, weight: .medium)
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .green500
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(color, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = .green800
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 52)
            .overlay(Capsule().stroke(color, lineWidth: 1.5))
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var aiPrimary: PrimaryButtonStyle { PrimaryButtonStyle(color: .lilac700) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Cards and blocks

struct CardModifier: ViewModifier {
    var background: Color = .surface
    func body(content: Content) -> some View {
        content
            .padding(Space.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.border, lineWidth: 1))
    }
}

extension View {
    func card(_ background: Color = .surface) -> some View { modifier(CardModifier(background: background)) }

    func screenBackground() -> some View {
        background(Color.paper.ignoresSafeArea())
    }
}

struct AILabel: View {
    var text = L("AI-read")
    var body: some View {
        Label(text, systemImage: "sparkles")
            .font(.caption13)
            .foregroundStyle(Color.lilac700)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.lilac100, in: Capsule())
            .overlay(Capsule().stroke(Color.lilac400, lineWidth: 1))
    }
}

struct AIBlock<Content: View>: View {
    var label = L("AI-written")
    var onReport: (() -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            AILabel(text: label)
            content
            if let onReport {
                Button(L("This isn't right"), action: onReport)
                    .font(.caption13)
                    .foregroundStyle(Color.lilac700)
            }
        }
        .padding(Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lilac100, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct Chip: View {
    var text: String
    var icon: String?
    var fg: Color = .ink500
    var bg: Color = .paper

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon) }
            Text(text).lineLimit(1)
        }
        .fixedSize()
        .font(.caption13)
        .foregroundStyle(fg)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(bg, in: Capsule())
    }
}

struct EuroBackdrop: View {
    var body: some View {
        Text(L("€"))
            .font(.system(size: 420, weight: .bold, design: .rounded))
            .foregroundStyle(Color.green500.opacity(0.06))
            .offset(x: 120, y: -80)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}

func euro(_ value: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "EUR"
    f.maximumFractionDigits = 0
    f.locale = Locale(identifier: "en_IE")
    return f.string(from: NSNumber(value: value)) ?? "€\(Int(value))"
}
