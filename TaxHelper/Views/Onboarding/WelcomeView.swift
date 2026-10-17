import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ZStack(alignment: .topTrailing) {
            EuroBackdrop()
            VStack(alignment: .leading, spacing: Space.xl) {
                Button { app.stage = .language } label: {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Color.ink900)
                .accessibilityLabel("Back")

                Text("Find the money and support your family is entitled to")
                    .font(.title)
                    .foregroundStyle(Color.ink900)

                VStack(alignment: .leading, spacing: Space.lg) {
                    promise("clock", "3 minutes", "A few taps. No paperwork needed to start.")
                    promise("character.bubble", "No German needed", "We explain official letters and write replies in German for you.")
                    promise("lock.shield", "No account needed", "Everything happens in the app. Your answers stay on this phone.")
                    promise("sparkles", "AI helps, you decide", "Claude reads and explains. Fixed rules calculate the money. Nothing is sent without your tap.")
                }
                .card()

                Text("Information, not legal or tax advice. Amounts are estimates. Official decisions come from the authorities.")
                    .font(.caption13)
                    .foregroundStyle(Color.ink500)

                Spacer()

                Button("Start the check") {
                    app.stage = .profile
                }
                .buttonStyle(.primary)

                Button("Use demo family (Priya & Arjun)") {
                    app.profile = .demo
                    app.stage = .result
                }
                .buttonStyle(.secondary)
            }
            .padding(Space.xl)
        }
        .screenBackground()
    }

    private func promise(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: Space.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(icon == "sparkles" ? Color.lilac700 : Color.green800)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.ink900)
                Text(text).font(.system(size: 15)).foregroundStyle(Color.ink500)
            }
        }
    }
}
