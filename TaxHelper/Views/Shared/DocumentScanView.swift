import PhotosUI
import SwiftUI

/// Scan, then confirm: Claude reads the fields, the parent confirms each one.
struct DocumentScanView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    var onDone: () -> Void = {}

    @State private var photo: PhotosPickerItem?
    @State private var loading = false
    @State private var result: AIResult<ExtractedDocument>?
    @State private var acceptGdb = true
    @State private var acceptPg = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    if loading {
                        ProgressView(L("Claude is reading your document…"))
                            .tint(Color.lilac700)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let result {
                        confirmation(result)
                    } else {
                        picker
                    }
                }
                .padding(Space.xl)
            }
            .screenBackground()
            .navigationTitle(L("Scan document"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(L("Close")) { dismiss() } }
            }
        }
        .onChange(of: photo) { _, item in
            guard let item else { return }
            Task {
                let data = try? await item.loadTransferable(type: Data.self)
                await read(text: nil, image: data)
            }
        }
    }

    private var picker: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            Text(L("Take a photo of the care-level decision or disability ID."))
                .font(.body17)
                .foregroundStyle(Color.ink500)
            PhotosPicker(selection: $photo, matching: .images) {
                Label(L("Choose a photo"), systemImage: "camera")
            }
            .buttonStyle(.aiPrimary)
            Button(L("Use sample decision (MUSTER)")) {
                Task { await read(text: SampleData.careLevelDecision, image: nil) }
            }
            .buttonStyle(.secondary)
        }
    }

    private func confirmation(_ r: AIResult<ExtractedDocument>) -> some View {
        let doc = r.value
        return VStack(alignment: .leading, spacing: Space.lg) {
            AIBlock(label: r.fromCache ? L("AI-read · demo answer") : L("AI-read")) {
                Text(doc.summary ?? L("Here's what we read."))
                    .font(.body17)
                    .foregroundStyle(Color.ink900)
            }

            Text(L("Please check these values")).font(.heading).foregroundStyle(Color.ink900)

            if let pg = doc.pflegegrad {
                confirmRow(L("Care level (Pflegegrad)"), "\(pg)", isOn: $acceptPg)
            }
            if let gdb = doc.gdb {
                confirmRow(L("Disability degree (GdB)"), "\(gdb)", isOn: $acceptGdb)
            }
            if let since = doc.validFrom {
                infoRow(L("Valid from"), since)
            }
            if let file = doc.fileNumber {
                infoRow(L("File number"), file)
            }

            Button(L("Confirm and update my estimate")) {
                apply(doc)
                Haptics.success()
                dismiss()
                onDone()
            }
            .buttonStyle(.primary)

            Button(L("Retake")) { result = nil; photo = nil }
                .buttonStyle(.secondary)
        }
    }

    private func confirmRow(_ label: String, _ value: String, isOn: Binding<Bool>) -> some View {
        Button { isOn.wrappedValue.toggle() } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.caption13).foregroundStyle(Color.ink500)
                    Text(value).font(.heading).foregroundStyle(Color.ink900)
                }
                Spacer()
                Label(isOn.wrappedValue ? L("Correct") : L("Ignore"), systemImage: isOn.wrappedValue ? "checkmark.circle.fill" : "xmark.circle")
                    .font(.caption13)
                    .foregroundStyle(isOn.wrappedValue ? Color.green800 : Color.ink500)
            }
            .card()
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption13).foregroundStyle(Color.ink500)
            Spacer()
            Label(value, systemImage: "lock.fill").font(.system(size: 15, weight: .medium)).foregroundStyle(Color.ink900)
        }
        .padding(.horizontal, Space.xs)
    }

    private func read(text: String?, image: Data?) async {
        loading = true
        result = await AIService.extractDocument(text: text, image: image, language: app.language)
        loading = false
    }

    private func apply(_ doc: ExtractedDocument) {
        if acceptPg, let pg = doc.pflegegrad {
            app.profile.pflegegrad = pg
            app.profile.pflegegradSource = .document
        }
        if acceptGdb, let gdb = doc.gdb {
            app.profile.gdb = gdb
            app.profile.gdbSource = .document
            let marks = (doc.merkzeichen ?? []).compactMap(Merkzeichen.init(rawValue:))
            app.profile.merkzeichen = Set(marks)
        }
        if app.profile.childName.isEmpty, let name = doc.childName {
            app.profile.childName = name
        }
        if let from = doc.validFrom, let year = Int(from.suffix(4)) {
            app.profile.statusSinceYear = year
        }
    }
}
