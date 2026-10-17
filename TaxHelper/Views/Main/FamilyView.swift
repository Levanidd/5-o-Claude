import SwiftUI

struct FamilyView: View {
    @Environment(AppState.self) private var app
    @AppStorage("backendURL") private var backendURL = "http://127.0.0.1:8787"
    @AppStorage("demoMode") private var demoMode = false
    @State private var confirmReset = false

    var body: some View {
        @Bindable var state = app
        NavigationStack {
            Form {
                Section("Child") {
                    row("Name", app.profile.childName.isEmpty ? "—" : app.profile.childName)
                    row("Disability degree (GdB)", app.profile.gdb.map { $0 == 0 ? "None yet" : "\($0)" } ?? "—",
                        doc: app.profile.gdbSource == .document)
                    row("ID marks", app.profile.merkzeichen.isEmpty ? "None" : app.profile.merkzeichen.map(\.rawValue).sorted().joined(separator: ", "))
                    row("Care level (Pflegegrad)", app.profile.pflegegrad.map { $0 == 0 ? "None" : "\($0)" } ?? "—",
                        doc: app.profile.pflegegradSource == .document)
                    row("Since", app.profile.statusSinceYear.map(String.init) ?? "—")
                }
                Section("Caregiver") {
                    row("Name", app.profile.parentName.isEmpty ? "—" : app.profile.parentName)
                    row("Work hours / week", app.profile.caregiverWorkHours.map { $0 == 0 ? "Not working" : ($0 <= 30 ? "≤ 30" : "> 30") } ?? "—")
                    row("Care at home", app.profile.careAtHome.map { $0 ? "Yes" : "No" } ?? "—")
                }
                Section {
                    Button("Edit answers") {
                        app.profileStep = 0
                        app.stage = .profile
                    }
                    Button("Load demo family (Priya & Arjun)") { app.profile = .demo }
                }
                Section {
                    Picker("App language", selection: $state.language) {
                        ForEach(Lang.allCases) { Text("\($0.flag) \($0.name)").tag($0) }
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("Claude explains letters and cards in this language. Letters to offices stay in German.")
                }
                Section {
                    TextField("Backend URL", text: $backendURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Toggle("Demo mode (cached AI answers)", isOn: $demoMode)
                } header: {
                    Text("AI connection")
                } footer: {
                    Text("On a real iPhone, use your Mac's IP, e.g. http://192.168.1.20:8787. Demo mode works without network.")
                }
                Section {
                    Button("Delete my data", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Information, not legal or tax advice. Amounts are estimates. Official decisions come from the authorities.")
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Family")
            .confirmationDialog("Delete all data on this phone?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { app.reset() }
            }
        }
    }

    private func row(_ label: String, _ value: String, doc: Bool = false) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.ink500)
            Spacer()
            if doc { AILabel(text: "From document") }
            Text(value).foregroundStyle(Color.ink900).fontWeight(.medium)
        }
    }
}
