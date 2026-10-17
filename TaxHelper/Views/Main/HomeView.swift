import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var app
    var goTo: (Tab) -> Void

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
            .navigationTitle(app.profile.parentName.isEmpty ? "Hello" : "Hello, \(app.profile.parentName)")
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
                    Text("€ secured / year").font(.caption13).foregroundStyle(Color.ink500)
                    Text(euro(secured)).font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.green800)
                        .contentTransition(.numericText(value: secured))
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("€ still open / year").font(.caption13).foregroundStyle(Color.ink500)
                    Text("≈ " + euro(open)).font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.ink900)
                        .contentTransition(.numericText(value: open))
                }
                if app.openOnce > 0 {
                    Text("+ \(euro(app.openOnce)) from past years").font(.caption13).foregroundStyle(Color.ink500)
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
                    Label("NEXT BEST ACTION", systemImage: "play.fill")
                        .font(.caption13)
                        .foregroundStyle(Color.green100)
                    Text(o.title).font(.heading).foregroundStyle(.white)
                    HStack(spacing: Space.sm) {
                        Text(o.valueOnce > 0 ? euro(o.valueOnce) : "≈ \(euro(o.valuePerYear))/yr")
                        Text("·")
                        Text("\(o.effortMinutes) min")
                        Text("·")
                        Text(o.confidence.label)
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.green100)
                    Text("Start")
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
        VStack(alignment: .leading, spacing: Space.md) {
            Text("Deadlines").font(.heading).foregroundStyle(Color.ink900)
            if app.deadlines.isEmpty {
                Text("No deadlines yet. Scan an official letter and we'll add its deadline here.")
                    .font(.system(size: 15)).foregroundStyle(Color.ink500)
            }
            ForEach(app.deadlines) { d in
                HStack {
                    Image(systemName: d.urgent ? "exclamationmark.circle.fill" : "circle")
                        .foregroundStyle(d.urgent ? Color.gold400 : Color.ink500)
                    Text(d.title).font(.system(size: 15)).foregroundStyle(Color.ink900)
                    Spacer()
                    Text(d.date).font(.system(size: 15, weight: .semibold).monospacedDigit())
                        .foregroundStyle(d.urgent ? Color.ink900 : Color.ink500)
                }
            }
        }
        .card()
    }

    private var forYou: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("For you").font(.heading).foregroundStyle(Color.ink900)
            Button { goTo(.capture) } label: {
                feedRow("envelope.open", "Got a letter in German?", "Take a photo — we'll explain it in \(app.language.name).")
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
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.ink900)
                Text(text).font(.system(size: 13)).foregroundStyle(Color.ink500).multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
    }
}
