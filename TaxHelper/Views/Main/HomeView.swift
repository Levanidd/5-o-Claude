import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var app
    var goTo: (Tab) -> Void
    /// nil = the soonest deadline is open.
    @State private var expandedDeadline: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    hero
                    if let banner = app.banner {
                        Label(banner, systemImage: "bell.badge")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.ink900)
                            .card(.gold100)
                    }
                    nextBestAction
                    deadlines
                    forYou
                }
                .padding(Space.lg)
            }
            .screenBackground()
            .navigationTitle(app.profile.parentName.isEmpty ? L("Hello") : L("Hello, %@", app.profile.parentName))
            .navigationDestination(for: Opportunity.self) { OpportunityDetailView(opportunity: $0) }
        }
    }

    private var hero: some View {
        let secured = app.securedPerYear
        let open = app.openPerYear
        let progress = secured + open > 0 ? secured / (secured + open) : 0
        return HStack(spacing: Space.xl) {
            ZStack {
                Circle().stroke(Color.green100, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.green500, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: progress)
                Text("\(Int(progress * 100))%").font(.system(size: 17, weight: .semibold).monospacedDigit())
            }
            .frame(width: 88, height: 88)
            VStack(alignment: .leading, spacing: Space.sm) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L("€ secured / year")).font(.caption13).foregroundStyle(Color.ink500)
                    Text(euro(secured)).font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.green800)
                        .contentTransition(.numericText(value: secured))
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(L("€ still open / year")).font(.caption13).foregroundStyle(Color.ink500)
                    Text("≈ " + euro(open)).font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.ink900)
                        .contentTransition(.numericText(value: open))
                }
                if app.openOnce > 0 {
                    Text(L("+ %@ from past years", euro(app.openOnce))).font(.caption13).foregroundStyle(Color.ink500)
                }
            }
            Spacer(minLength: 0)
        }
        .card()
    }

    @ViewBuilder
    private var nextBestAction: some View {
        if let o = app.nextBestAction {
            NavigationLink(value: o) {
                VStack(alignment: .leading, spacing: Space.md) {
                    Label(L("NEXT BEST ACTION"), systemImage: "play.fill")
                        .font(.caption13)
                        .foregroundStyle(Color.green100)
                    Text(o.title).font(.heading).foregroundStyle(.white)
                    HStack(spacing: Space.sm) {
                        Text(o.valueOnce > 0 ? euro(o.valueOnce) : "≈ " + L("%@/yr", euro(o.valuePerYear)))
                        Text(L("·"))
                        Text(L("%@ min", o.effortMinutes))
                        Text(L("·"))
                        Text(o.confidence.label)
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.green100)
                    Text(L("Start"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.green800)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.green100, in: Capsule())
                }
                .padding(Space.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green800, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private var deadlines: some View {
        let items = app.allDeadlines
        return VStack(alignment: .leading, spacing: Space.md) {
            Text(L("Deadlines")).font(.heading).foregroundStyle(Color.ink900)
            if items.isEmpty {
                Text(L("No deadlines yet. Scan an official letter and we'll add its deadline here."))
                    .font(.system(size: 15)).foregroundStyle(Color.ink500)
            }
            ForEach(Array(items.enumerated()), id: \.element.id) { i, d in
                if i > 0 { Divider() }
                let isOpen = expandedDeadline.map { $0 == d.id } ?? (i == 0)
                DeadlineRow(
                    deadline: d,
                    opportunity: app.opportunities.first { $0.id == d.opportunityID },
                    isOpen: isOpen
                ) {
                    withAnimation(.snappy) { expandedDeadline = isOpen ? "" : d.id }
                }
            }
        }
        .card()
    }

    private var forYou: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text(L("For you")).font(.heading).foregroundStyle(Color.ink900)
            Button { goTo(.capture) } label: {
                feedRow("envelope.open", L("Got a letter in German?"), L("Take a photo — we'll explain it in %@.", app.language.name))
            }
            if app.profile.newToGermany == true {
                feedRow("airplane.arrival", "New to Germany checklist", "Anmeldung, health insurance, Kindergeld, tax ID, German GdB assessment.")
            }
            feedRow("person.3", "12 parents near you", "Families with a child the same age, who speak your language.")
        }
        .card()
    }

    private func feedRow(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: Space.md) {
            Image(systemName: icon).foregroundStyle(Color.blue500).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(L(title)).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.ink900)
                Text(L(text)).font(.system(size: 13)).foregroundStyle(Color.ink500).multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct DeadlineRow: View {
    let deadline: Deadline
    let opportunity: Opportunity?
    let isOpen: Bool
    let toggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Button(action: toggle) {
                HStack(alignment: .top, spacing: Space.md) {
                    Image(systemName: deadline.urgent ? "exclamationmark.circle.fill" : "calendar")
                        .font(.system(size: 18))
                        .foregroundStyle(deadline.urgent ? Color.gold400 : Color.ink500)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(deadline.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.ink900)
                            .multilineTextAlignment(.leading)
                        Text(deadline.date + (countdown.map { " · " + $0 } ?? ""))
                            .font(.system(size: 13, weight: .medium).monospacedDigit())
                            .foregroundStyle(deadline.urgent ? Color.ink900 : Color.ink500)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.ink500)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(L("Next steps"))

            if isOpen {
                VStack(alignment: .leading, spacing: Space.sm) {
                    Text(L("Next steps")).font(.caption13).foregroundStyle(Color.ink500)
                    ForEach(Array(deadline.steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: Space.sm) {
                            Text("\(i + 1)")
                                .font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(Color.green800, in: Circle())
                            Text(step).font(.system(size: 15)).foregroundStyle(Color.ink900)
                        }
                    }
                    HStack {
                        if let source = deadline.source {
                            Label(source, systemImage: "building.columns").font(.caption13).foregroundStyle(Color.blue500)
                        }
                        Spacer()
                        if let opportunity {
                            NavigationLink(value: opportunity) {
                                Label(L("Open"), systemImage: "chevron.right")
                                    .labelStyle(.titleAndIcon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.green800)
                            }
                        }
                    }
                    .padding(.top, Space.xs)
                }
                .padding(.leading, 24 + Space.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var countdown: String? {
        guard let days = deadline.daysLeft else { return nil }
        if days < 0 { return L("overdue") }
        if days == 0 { return L("today") }
        return L("in %@ days", days)
    }
}
