import SwiftUI

/// Official letter explainer: a German letter → summary in the parent's language.
struct LetterExplainView: View {
    @Environment(AppState.self) private var app
    let letter: Letter

    @State private var result: AIResult<LetterExplanation>?
    @State private var showOriginal = false
    @State private var showTranslation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                if let result {
                    summary(result)
                } else {
                    VStack(spacing: Space.lg) {
                        ProgressView().tint(Color.lilac700).scaleEffect(1.3)
                        Text("Claude is reading the letter…").font(.body17).foregroundStyle(Color.ink500)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                }
            }
            .padding(Space.lg)
        }
        .screenBackground()
        .navigationTitle("Your letter")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard result == nil else { return }
            let r = await AIService.explainLetter(text: letter.originalText, image: letter.imageData, language: app.language)
            withAnimation { result = r }
            if let deadline = r.value.deadline {
                app.addDeadline("Reply to \(r.value.sender ?? "letter")", deadline)
                app.banner = "New deadline added: \(deadline)"
            }
        }
    }

    @ViewBuilder
    private func summary(_ r: AIResult<LetterExplanation>) -> some View {
        let e = r.value
        VStack(alignment: .leading, spacing: Space.sm) {
            if let sender = e.sender {
                Label(sender, systemImage: "building.2").font(.caption13).foregroundStyle(Color.blue500)
            }
            Text(e.subject ?? "Here's what this letter means").font(.title).foregroundStyle(Color.ink900)
        }

        HStack(spacing: Space.md) {
            if let deadline = e.deadline {
                fact("Deadline", deadline, icon: "calendar.badge.exclamationmark", bg: .gold100)
            }
            if let amount = e.amount {
                fact("Amount", amount, icon: "eurosign", bg: .green100)
            }
        }

        AIBlock(label: r.fromCache ? "AI-explained · demo answer" : "AI-explained in \(app.language.name)", onReport: { showOriginal = true }) {
            Text("What it says").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.ink900)
            Text(e.whatItSays).font(.body17).foregroundStyle(Color.ink900)
        }

        VStack(alignment: .leading, spacing: Space.md) {
            Text("What you need to do").font(.heading).foregroundStyle(Color.ink900)
            ForEach(Array(e.whatToDo.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: Space.md) {
                    Text("\(i + 1)")
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.green800, in: Circle())
                    Text(step).font(.system(size: 15)).foregroundStyle(Color.ink900)
                }
            }
        }
        .card()

        NavigationLink {
            LetterReplyView(
                title: "Reply in German",
                intent: letter.originalText == SampleData.insurerLetter ? SampleData.replyIntent : "",
                context: letter.originalText ?? e.translation ?? e.whatItSays,
                lockedTokens: [e.fileNumber].compactMap { $0 },
                onSent: { app.banner = "Reply sent. We'll remind you before \(e.deadline ?? "the deadline")." }
            )
        } label: {
            Label("Reply in German", systemImage: "arrowshape.turn.up.left")
        }
        .buttonStyle(.primary)

        if let translation = e.translation {
            DisclosureGroup("Full translation", isExpanded: $showTranslation) {
                Text(translation).font(.system(size: 15)).foregroundStyle(Color.ink900).padding(.top, Space.sm)
            }
            .tint(Color.lilac700)
            .card()
        }

        if let original = letter.originalText {
            DisclosureGroup("German original", isExpanded: $showOriginal) {
                Text(original).font(.system(size: 14, design: .serif)).foregroundStyle(Color.ink900).padding(.top, Space.sm)
            }
            .tint(Color.blue500)
            .card(.blue100)
        } else if let data = letter.imageData, let image = UIImage(data: data) {
            DisclosureGroup("German original", isExpanded: $showOriginal) {
                Image(uiImage: image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .tint(Color.blue500)
            .card(.blue100)
        }

        Text("The German original is the one that counts legally. The translation is for understanding only.")
            .font(.caption13).foregroundStyle(Color.ink500)
    }

    private func fact(_ label: String, _ value: String, icon: String, bg: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon).font(.caption13).foregroundStyle(Color.ink500)
            Text(value).font(.system(size: 20, weight: .semibold).monospacedDigit()).foregroundStyle(Color.ink900)
        }
        .padding(Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
