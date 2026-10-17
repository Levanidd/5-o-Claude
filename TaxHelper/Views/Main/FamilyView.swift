import SwiftUI

struct FamilyView: View {
    @Environment(AppState.self) private var app
    @AppStorage("backendURL") private var backendURL = AIService.defaultURL
    @AppStorage("demoMode") private var demoMode = false
    @State private var confirmReset = false

    var body: some View {
        @Bindable var state = app
        NavigationStack {
            Form {
                Section(L("Child")) {
                    row("Name", app.profile.childName.isEmpty ? "—" : app.profile.childName)
                    row("Disability degree (GdB)", app.profile.gdb.map { $0 == 0 ? "None yet" : "\($0)" } ?? "—",
                        doc: app.profile.gdbSource == .document)
                    row("ID marks", app.profile.merkzeichen.isEmpty ? "None" : app.profile.merkzeichen.map(\.rawValue).sorted().joined(separator: ", "))
                    row("Care level (Pflegegrad)", app.profile.pflegegrad.map { $0 == 0 ? "None" : "\($0)" } ?? "—",
                        doc: app.profile.pflegegradSource == .document)
                    row("Since", app.profile.statusSinceYear.map(String.init) ?? "—")
                }
                Section(L("Caregiver")) {
                    row("Name", app.profile.parentName.isEmpty ? "—" : app.profile.parentName)
                    row("Work hours / week", app.profile.caregiverWorkHours.map { $0 == 0 ? "Not working" : ($0 <= 30 ? "≤ 30" : "> 30") } ?? "—")
                    row("Care at home", app.profile.careAtHome.map { $0 ? "Yes" : "No" } ?? "—")
                }
                Section {
                    Button(L("Edit answers")) {
                        app.profileStep = 0
                        app.stage = .profile
                    }
                    Button(L("Load demo family (Priya & Arjun)")) { app.profile = .demo }
                }
                Section {
                    Picker(L("App language"), selection: $state.language) {
                        ForEach(Lang.allCases) { Text("\($0.flag) \($0.name)").tag($0) }
                    }
                } header: {
                    Text(L("Language"))
                } footer: {
                    Text(L("The app and Claude's explanations use this language. Letters to offices stay in German."))
                }
                Section {
                    TextField(L("Backend URL"), text: $backendURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Toggle(L("Demo mode (cached AI answers)"), isOn: $demoMode)
                } header: {
                    Text(L("AI connection"))
                } footer: {
                    Text(L("On a real iPhone, use your Mac's IP, e.g. http://192.168.1.20:8787. Demo mode works without network."))
                }
                Section {
                    Button(L("Delete my data"), role: .destructive) { confirmReset = true }
                        .confirmationDialog(L("Delete all data on this phone?"), isPresented: $confirmReset, titleVisibility: .visible) {
                            Button(L("Delete"), role: .destructive) { app.reset() }
                            Button(L("Cancel"), role: .cancel) {}
                        } message: {
                            Text(L("Your answers, letters and deadlines on this phone will be deleted. This can't be undone."))
                        }
                } footer: {
                    Text(L("Information, not legal or tax advice. Amounts are estimates. Official decisions come from the authorities."))
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle(L("Family"))
        }
    }

    private func row(_ label: String, _ value: String, doc: Bool = false) -> some View {
        HStack {
            Text(L(label)).foregroundStyle(Color.ink500)
            Spacer()
            if doc { AILabel(text: L("From document")) }
            Text(L(value)).foregroundStyle(Color.ink900).fontWeight(.medium)
        }
    }
}
