import SwiftUI

/// Explainable card: € → confidence → why you qualify → how to claim → actions → questions → source.
struct OpportunityDetailView: View {
    @Environment(AppState.self) private var app
    let opportunity: Opportunity

    @State private var explanation: AIResult<OpportunityExplanation>?
    @State private var explaining = false
    @State private var question = ""
    @State private var answers: [(q: String, a: AIResult<CardAnswer>)] = []
    @State private var asking = false
    @State private var showTaxfix = false
    @State private var showExpert = false
    @State private var showCalc = false

    private let suggested = ["Can I get this for past years?", "What documents do I need?", "How long does it take?"]

    var body: some View {
        let o = opportunity
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xl) {
                header(o)
                why(o)
                aiExplanation(o)
                howTo(o)
                actions(o)
                questions(o)
                source(o)
            }
            .padding(Space.lg)
        }
        .screenBackground()
        .navigationTitle(o.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTaxfix) { TaxfixHandoffView(opportunity: o) }
        .sheet(isPresented: $showExpert) { ExpertHandoffView(opportunity: o) }
        .sheet(isPresented: $showCalc) { calculation(o).presentationDetents([.medium]) }
    }

    private func header(_ o: Opportunity) -> some View {
        VStack(alignment: .leading, spacing: Space.md) {
            HStack {
                Image(systemName: o.category.icon).font(.system(size: 32)).foregroundStyle(Color.green800)
                Spacer()
                StatusBadge(status: app.status(o))
            }
            Text(o.title).font(.title).foregroundStyle(Color.ink900)
            Text(o.germanTerm).font(.system(size: 15).italic()).foregroundStyle(Color.blue500)
            Text(o.summary).font(.body17).foregroundStyle(Color.ink500)
            HStack(alignment: .bottom) {
                OpportunityAmount(opportunity: o)
                Spacer()
                ConfidenceBadge(confidence: o.confidence)
            }
            Button("How we calculated this") { showCalc = true }
                .font(.caption13)
                .foregroundStyle(Color.blue500)
        }
        .card()
    }

    private func why(_ o: Opportunity) -> some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("Why you qualify").font(.heading).foregroundStyle(Color.ink900)
            ForEach(o.reasons) { r in
                HStack(alignment: .top, spacing: Space.sm) {
                    Image(systemName: r.met ? "checkmark.circle.fill" : "questionmark.circle")
                        .foregroundStyle(r.met ? Color.green500 : Color.gold400)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.label).font(.system(size: 15)).foregroundStyle(Color.ink900)
                        if r.fromDocument {
                            Text("From your scanned document").font(.system(size: 12)).foregroundStyle(Color.lilac700)
                        }
                    }
                }
            }
            HStack(spacing: Space.sm) {
                Image(systemName: "arrow.turn.down.right").foregroundStyle(Color.ink500)
                Text(o.confidence == .needsInfo ? "Answer 1 question to confirm" : "→ eligible (decided by fixed rules, not AI)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.green800)
            }
            if let missing = o.missingQuestion {
                Chip(text: missing, icon: "questionmark.bubble", fg: .ink900, bg: .gold100)
            }
        }
        .card()
    }

    @ViewBuilder
    private func aiExplanation(_ o: Opportunity) -> some View {
        if let explanation {
            AIBlock(label: explanation.fromCache ? "AI-explained · demo answer" : "AI-explained in \(app.language.name)", onReport: { self.explanation = nil }) {
                Text(explanation.value.plainExplanation).font(.body17).foregroundStyle(Color.ink900)
                ForEach(explanation.value.whyBullets, id: \.self) { b in
                    Label(b, systemImage: "checkmark").font(.system(size: 15)).foregroundStyle(Color.ink900)
                }
            }
        } else {
            Button {
                Task {
                    explaining = true
                    explanation = await AIService.explainOpportunity(o, language: app.language)
                    explaining = false
                }
            } label: {
                if explaining { ProgressView().tint(.white) } else { Label("Explain this in \(app.language.name)", systemImage: "sparkles") }
            }
            .buttonStyle(.aiPrimary)
        }
    }

    private func howTo(_ o: Opportunity) -> some View {
        VStack(alignment: .leading, spacing: Space.md) {
            HStack {
                Text("How to claim").font(.heading).foregroundStyle(Color.ink900)
                Spacer()
                Chip(text: "\(o.effortMinutes) min", icon: "clock")
            }
            ForEach(Array(o.howToClaim.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: Space.md) {
                    Text("\(i + 1)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.green800, in: Circle())
                    Text(step).font(.system(size: 15)).foregroundStyle(Color.ink900)
                }
            }
        }
        .card()
    }

    @ViewBuilder
    private func actions(_ o: Opportunity) -> some View {
        VStack(spacing: Space.md) {
            switch o.action {
            case .taxfix:
                Button { showTaxfix = true } label: { Label("Add to my Taxfix return", systemImage: "plus.circle") }
                    .buttonStyle(.primary)
                    .disabled(app.status(o) == .submitted)
            case .letter, .info:
                NavigationLink {
                    LetterReplyView(
                        title: "Application in German",
                        intent: "Please send me the application for \(o.title) (\(o.germanTerm)) for my child. Care level \(app.profile.pflegegrad ?? 0).",
                        context: "",
                        lockedTokens: [],
                        onSent: { app.setStatus(o, .submitted) }
                    )
                } label: {
                    Label("Draft the application in German", systemImage: "doc.text")
                }
                .buttonStyle(.primary)
            }
            Button { showExpert = true } label: { Label("Talk to an expert", systemImage: "person.badge.shield.checkmark") }
                .buttonStyle(SecondaryButtonStyle(color: .blue500))
        }
    }

    private func questions(_ o: Opportunity) -> some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("Questions about this").font(.heading).foregroundStyle(Color.ink900)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(suggested, id: \.self) { q in
                        Button { ask(q, o) } label: {
                            Chip(text: q, icon: "sparkles", fg: .lilac700, bg: .lilac100)
                        }
                    }
                }
            }
            HStack {
                TextField("Ask about this card…", text: $question)
                    .font(.system(size: 15))
                    .padding(Space.md)
                    .background(Color.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.border))
                    .onSubmit { ask(question, o) }
                Button { ask(question, o) } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 30)).foregroundStyle(Color.lilac700)
                }
                .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Ask")
            }
            if asking { ProgressView().tint(Color.lilac700) }
            ForEach(Array(answers.enumerated()), id: \.offset) { _, item in
                AIBlock(label: item.a.fromCache ? "AI answer · demo" : "AI answer") {
                    Text(item.q).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.ink900)
                    Text(item.a.value.answer).font(.system(size: 15)).foregroundStyle(Color.ink900)
                    if let s = item.a.value.citedSource {
                        Label(s, systemImage: "building.columns").font(.caption13).foregroundStyle(Color.blue500)
                    }
                    if item.a.value.escalate == true {
                        Button("Ask an expert instead") { showExpert = true }
                            .font(.caption13).foregroundStyle(Color.blue500)
                    }
                }
            }
        }
    }

    private func source(_ o: Opportunity) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            if let url = o.sourceURL {
                Link(destination: url) {
                    Label("Legal source: \(o.legalSource)", systemImage: "building.columns")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.blue500)
            }
            Text("Rule checked on \(RulesEngine.verifiedOn). Information, not legal or tax advice.")
                .font(.caption13)
                .foregroundStyle(Color.ink500)
        }
    }

    private func calculation(_ o: Opportunity) -> some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            AILabel(text: "Fixed rule · not AI")
            Text("How we calculated this").font(.title).foregroundStyle(Color.ink900)
            switch o.kind {
            case .taxDeduction:
                Text("Allowance: \(euro(o.grossAmount)) \(o.unit == "once" ? "in total" : "per year")")
                Text("× assumed tax rate 30%")
                Text("≈ \(euro(o.valuePerYear + o.valueOnce)) tax saving").fontWeight(.semibold)
                Text("A tax allowance lowers your taxable income. It isn't cash. Your real saving depends on your tax rate.")
                    .foregroundStyle(Color.ink500)
            case .cashBenefit:
                Text("\(euro(o.grossAmount)) per \(o.unit)")
                if o.unit == "month" { Text("× 12 months = \(euro(o.valuePerYear)) per year").fontWeight(.semibold) }
                Text("Paid by your care insurer (Pflegekasse).").foregroundStyle(Color.ink500)
            default:
                Text(o.summary)
            }
            Text("Source: \(o.legalSource)").foregroundStyle(Color.blue500)
            Spacer()
        }
        .font(.body17)
        .padding(Space.xxl)
    }

    private func ask(_ q: String, _ o: Opportunity) {
        let text = q.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !asking else { return }
        question = ""
        asking = true
        Task {
            let a = await AIService.answerOnCard(text, o, language: app.language)
            answers.insert((text, a), at: 0)
            asking = false
        }
    }
}

struct ExpertHandoffView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let opportunity: Opportunity

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Space.lg) {
                Text("We send your case summary, so you never repeat yourself.")
                    .font(.body17).foregroundStyle(Color.ink500)
                VStack(alignment: .leading, spacing: Space.sm) {
                    Text("Case summary").font(.heading)
                    Text("Topic: \(opportunity.title) (\(opportunity.germanTerm))")
                    Text("Child: GdB \(app.profile.gdb ?? 0), care level \(app.profile.pflegegrad ?? 0)")
                    Text("Status: \(app.status(opportunity).label) · \(opportunity.confidence.label)")
                    Text("Language: \(app.language.name)")
                }
                .font(.system(size: 15))
                .card()
                Button("Taxfix expert (speaks \(app.language.name))") { dismiss() }.buttonStyle(SecondaryButtonStyle(color: .blue500))
                Button("Free counselling (EUTB)") { dismiss() }.buttonStyle(SecondaryButtonStyle(color: .blue500))
                Spacer()
            }
            .padding(Space.xl)
            .screenBackground()
            .navigationTitle("Talk to an expert")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } } }
        }
    }
}

struct TaxfixHandoffView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let opportunity: Opportunity
    @State private var done = false

    var body: some View {
        VStack(spacing: Space.xl) {
            Spacer()
            Image(systemName: done ? "checkmark.circle.fill" : "doc.text.magnifyingglass")
                .font(.system(size: 72))
                .foregroundStyle(Color.green500)
                .symbolEffect(.bounce, value: done)
            Text(done ? "Added to your Taxfix return" : "Add to your Taxfix return 2026?")
                .font(.title).multilineTextAlignment(.center)
            Text(done
                 ? "\(opportunity.title) is now in your return. Tax saving ≈ \(euro(opportunity.valuePerYear + opportunity.valueOnce))."
                 : "We pre-fill the child section with the disability degree \(app.profile.gdb ?? 0) and care level \(app.profile.pflegegrad ?? 0). You check it before filing.")
                .font(.body17).foregroundStyle(Color.ink500).multilineTextAlignment(.center)
            Spacer()
            if done {
                Button("Done") { dismiss() }.buttonStyle(.primary)
            } else {
                Button("Add to my return") {
                    app.setStatus(opportunity, .submitted)
                    Haptics.success()
                    withAnimation { done = true }
                }
                .buttonStyle(.primary)
                Button("Not now") { dismiss() }.buttonStyle(.secondary)
            }
            Text("Demo: no data is sent to Taxfix.").font(.caption13).foregroundStyle(Color.ink500)
        }
        .padding(Space.xl)
        .screenBackground()
    }
}
