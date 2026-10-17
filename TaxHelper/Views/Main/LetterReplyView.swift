import SwiftUI

/// The parent says it in their language → formal German letter, side by side with a translation.
struct LetterReplyView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    let title: String
    @State var intent: String
    let context: String
    let lockedTokens: [String]
    let onSent: () -> Void

    @State private var draft: AIResult<GermanDraft>?
    @State private var loading = false
    @State private var mode = "Side by side"
    @State private var sent = false
    @State private var copied: String?

    init(title: String, intent: String, context: String, lockedTokens: [String], onSent: @escaping () -> Void) {
        self.title = title
        _intent = State(initialValue: intent)
        self.context = context
        self.lockedTokens = lockedTokens
        self.onSent = onSent
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                VStack(alignment: .leading, spacing: Space.sm) {
                    Text(L("Say it in %@", app.language.name)).font(.heading).foregroundStyle(Color.ink900)
                    Text(L("Write what you want to tell the office. Claude turns it into a correct, formal German letter."))
                        .font(.system(size: 15)).foregroundStyle(Color.ink500)
                    TextEditor(text: $intent)
                        .font(.body17)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(Space.sm)
                        .background(Color.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.border))
                }

                Button {
                    Task { await generate() }
                } label: {
                    if loading { ProgressView().tint(.white) }
                    else { Label(draft == nil ? L("Write my German letter") : L("Write again"), systemImage: "sparkles") }
                }
                .buttonStyle(.aiPrimary)
                .disabled(intent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || loading)

                if let draft { result(draft) }
            }
            .padding(Space.lg)
        }
        .screenBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func result(_ r: AIResult<GermanDraft>) -> some View {
        let d = r.value
        AILabel(text: r.fromCache ? L("AI-drafted · demo answer") : L("AI-drafted · please review"))

        Picker(L("View"), selection: $mode) {
            Text(L("Side by side")).tag("Side by side")
            Text(L("German")).tag("German")
            Text(app.language.name).tag("Translation")
        }
        .pickerStyle(.segmented)

        switch mode {
        case "German":
            letterBlock(L("Deutsch · sent to the office"), d.letterDe, accent: .blue500, bg: .blue100)
        case "Translation":
            letterBlock(L("%@ · for you to understand", app.language.name), d.translation, accent: .lilac700, bg: .lilac100)
        default:
            HStack(alignment: .top, spacing: Space.sm) {
                letterBlock("Deutsch", d.letterDe, accent: .blue500, bg: .blue100, small: true)
                letterBlock(app.language.name, d.translation, accent: .lilac700, bg: .lilac100, small: true)
            }
        }

        let tokens = Array(Set((d.lockedTokens ?? []) + lockedTokens)).sorted()
        if !tokens.isEmpty {
            VStack(alignment: .leading, spacing: Space.sm) {
                Text(L("Locked details (copied exactly)")).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.ink900)
                FlowChips(tokens: tokens, letter: d.letterDe)
            }
            .card()
        }

        if sent {
            Label(L("Marked as sent. We'll track the reply."), systemImage: "checkmark.circle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.green800)
                .card(.green100)
        } else {
            ShareLink(item: d.letterDe, subject: Text(L("Brief")), preview: SharePreview(L("German letter"))) {
                Label(L("Share / print German letter"), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.primary)
            Button(L("I've sent it")) {
                sent = true
                Haptics.success()
                onSent()
            }
            .buttonStyle(.secondary)
        }

        Text(L("Check the letter before sending. The German version is the one that counts legally."))
            .font(.caption13).foregroundStyle(Color.ink500)
    }

    private func letterBlock(_ label: String, _ text: String, accent: Color, bg: Color, small: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            HStack {
                Text(label).font(.caption13).foregroundStyle(accent)
                Spacer(minLength: Space.xs)
                Button { copy(text) } label: {
                    Image(systemName: copied == text ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .padding(.vertical, -Space.sm)
                .accessibilityLabel(copied == text ? L("Copied") : L("Copy"))
            }
            Text(text)
                .font(.system(size: small ? 12 : 15))
                .foregroundStyle(Color.ink900)
                .textSelection(.enabled)
        }
        .padding(small ? Space.md : Space.lg)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            Rectangle().fill(accent).frame(width: 3).clipShape(Capsule()).padding(.vertical, Space.md)
        }
    }

    private func copy(_ text: String) {
        UIPasteboard.general.string = text
        Haptics.success()
        withAnimation { copied = text }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { if copied == text { copied = nil } }
        }
    }

    private func generate() async {
        loading = true
        let r = await AIService.draftGermanLetter(
            intent: intent, context: context, profile: app.profile,
            lockedTokens: lockedTokens, language: app.language
        )
        withAnimation { draft = r }
        loading = false
        Haptics.success()
    }
}

private struct FlowChips: View {
    let tokens: [String]
    let letter: String

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), alignment: .leading)], alignment: .leading, spacing: Space.sm) {
            ForEach(tokens, id: \.self) { t in
                let ok = letter.contains(t)
                Chip(text: t, icon: ok ? "lock.fill" : "exclamationmark.triangle", fg: ok ? .ink900 : .danger, bg: ok ? .paper : .gold100)
            }
        }
    }
}
