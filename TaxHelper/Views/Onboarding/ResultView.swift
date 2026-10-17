import SwiftUI

/// The "aha" moment: €X per year + €Y from past years.
struct ResultView: View {
    @Environment(AppState.self) private var app
    @State private var shown: Double = 0
    @State private var shownOnce: Double = 0

    var body: some View {
        let opps = app.opportunities
        let totals = RulesEngine.totals(opps)
        let taxPart = opps.filter { $0.kind == .taxDeduction && !$0.alreadyReceived }.reduce(0) { $0 + $1.valuePerYear }
        let cashPart = totals.perYear - taxPart

        ZStack(alignment: .topTrailing) {
            EuroBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    Text("Nice — here's what \(app.profile.childName.isEmpty ? "your family" : "you and " + app.profile.childName) can claim")
                        .font(.title)
                        .foregroundStyle(Color.ink900)

                    VStack(alignment: .leading, spacing: Space.sm) {
                        Text("≈ " + euro(shown))
                            .font(.display)
                            .foregroundStyle(Color.green800)
                            .contentTransition(.numericText(value: shown))
                        Text("per year, not claimed yet").font(.body17).foregroundStyle(Color.ink500)
                        if totals.once > 0 {
                            Text("+ " + euro(shownOnce) + " back from past tax years")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color.ink900)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.gold100, in: Capsule())
                                .contentTransition(.numericText(value: shownOnce))
                        }
                        Divider().padding(.vertical, Space.xs)
                        split("Paid to you (care insurer)", cashPart)
                        split("Tax saving ≈ (at 30% tax rate)", taxPart)
                    }
                    .card()

                    Text("Top opportunities").font(.heading).foregroundStyle(Color.ink900)
                    ForEach(opps.filter { !$0.alreadyReceived }.prefix(4)) { o in
                        OpportunityRow(opportunity: o, status: app.status(o))
                    }

                    VStack(spacing: Space.md) {
                        Button("Go to my dashboard") {
                            Haptics.success()
                            app.stage = .main
                        }
                        .buttonStyle(.primary)

                        Button("Change my answers") {
                            app.profileStep = 0
                            app.stage = .profile
                        }
                        .buttonStyle(.secondary)
                    }

                    Text("Estimates from fixed rules (2026 amounts). Information, not legal or tax advice.")
                        .font(.caption13)
                        .foregroundStyle(Color.ink500)
                }
                .padding(Space.xl)
            }
        }
        .screenBackground()
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.9)) {
                shown = totals.perYear
                shownOnce = totals.once
            }
            Haptics.success()
        }
    }

    private func split(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label).font(.system(size: 15)).foregroundStyle(Color.ink500)
            Spacer()
            Text(euro(value)).font(.system(size: 15, weight: .semibold).monospacedDigit()).foregroundStyle(Color.ink900)
        }
    }
}
