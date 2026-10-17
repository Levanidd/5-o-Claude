import PhotosUI
import SwiftUI

struct CaptureView: View {
    @Environment(AppState.self) private var app
    @State private var photo: PhotosPickerItem?
    @State private var letter: Letter?
    @State private var showDocScan = false
    @State private var showCamera = false
    @State private var captured: Data?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    Text(L("One place for every paper. Claude reads it, explains it in %@ and tells you what to do.", app.language.name))
                        .font(.body17)
                        .foregroundStyle(Color.ink500)

                    VStack(alignment: .leading, spacing: Space.md) {
                        Label(L("Letter from an office"), systemImage: "envelope.open")
                            .font(.heading).foregroundStyle(Color.ink900)
                        Text(L("What it says · what to do · deadline · amount")).font(.system(size: 15)).foregroundStyle(Color.ink500)
                        if CameraPicker.isAvailable {
                            Button { showCamera = true } label: {
                                Label(L("Take a photo"), systemImage: "camera")
                            }
                            .buttonStyle(.aiPrimary)
                            PhotosPicker(selection: $photo, matching: .images) {
                                Label(L("Choose a photo"), systemImage: "photo.on.rectangle")
                            }
                            .buttonStyle(.secondary)
                        } else {
                            PhotosPicker(selection: $photo, matching: .images) {
                                Label(L("Take or choose a photo"), systemImage: "camera")
                            }
                            .buttonStyle(.aiPrimary)
                        }
                        Button(L("Use sample letter from care insurer (MUSTER)")) {
                            letter = Letter(originalText: SampleData.insurerLetter)
                        }
                        .buttonStyle(.secondary)
                    }
                    .card()

                    Button { showDocScan = true } label: {
                        row("doc.text.viewfinder", "Care-level decision or disability ID", "Updates your profile and estimate")
                    }
                    NavigationLink {
                        LetterReplyView(title: L("Write to an office"), intent: "", context: "", lockedTokens: [], onSent: {})
                    } label: {
                        row("square.and.pencil", "Write a letter in German", "Say it in your language, get a formal German letter")
                    }
                }
                .padding(Space.lg)
            }
            .screenBackground()
            .navigationTitle(L("Capture"))
            .navigationDestination(item: $letter) { LetterExplainView(letter: $0) }
            .sheet(isPresented: $showDocScan) { DocumentScanView() }
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                if let captured { letter = Letter(imageData: captured) }
                captured = nil
            }) {
                CameraPicker { captured = $0 }.ignoresSafeArea()
            }
            .onChange(of: photo) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        letter = Letter(imageData: data)
                    }
                    photo = nil
                }
            }
        }
    }

    private func row(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(spacing: Space.md) {
            Image(systemName: icon).font(.system(size: 24)).foregroundStyle(Color.lilac700).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(L(title)).font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.ink900)
                Text(L(text)).font(.system(size: 13)).foregroundStyle(Color.ink500)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color.ink500)
        }
        .card()
    }
}

extension Letter: Hashable {
    static func == (lhs: Letter, rhs: Letter) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
