import SwiftUI

/// One question per screen, with a live "€ found" meter on top.
struct ProfileFlowView: View {
    @Environment(AppState.self) private var app
    @State private var showScan = false

    private let stepCount = 10

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    question
                }
                .padding(Space.xl)
                .id(app.profileStep)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            }
            footer
        }
        .screenBackground()
        .sheet(isPresented: $showScan) {
            DocumentScanView { app.stage = .result }
        }
    }

    // MARK: Header with € meter

    private var header: some View {
        let totals = RulesEngine.totals(RulesEngine.evaluate(app.profile))
        return VStack(alignment: .leading, spacing: Space.md) {
            HStack {
                Button {
                    withAnimation { if app.profileStep > 0 { app.profileStep -= 1 } else { app.stage = .welcome } }
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Color.ink900)
                .accessibilityLabel(L("Back"))
                ProgressView(value: Double(app.profileStep + 1), total: Double(stepCount))
                    .tint(Color.green500)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(L("€ found so far"))
                    .font(.caption13)
                    .foregroundStyle(Color.green800)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("≈ " + euro(totals.perYear))
                        .font(.system(size: 40, weight: .semibold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText(value: totals.perYear))
                        .foregroundStyle(Color.green800)
                    Text(L("/ year")).font(.caption13).foregroundStyle(Color.ink500)
                }
                if totals.once > 0 {
                    Text(L("+ %@ from past years", euro(totals.once)))
                        .font(.caption13)
                        .foregroundStyle(Color.green800)
                        .contentTransition(.numericText(value: totals.once))
                }
            }
            .padding(Space.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green100, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: totals.perYear)
        }
        .padding(.horizontal, Space.xl)
        .padding(.top, Space.sm)
    }

    // MARK: Questions

    @ViewBuilder
    private var question: some View {
        @Bindable var state = app
        switch app.profileStep {
        case 0:
            title(L("First, who are we helping?"), why: "We use first names only to make letters and explanations personal. They stay on your phone.")
            field("Your first name", text: $state.profile.parentName, placeholder: "e.g. Priya")
            field("Your child's first name", text: $state.profile.childName, placeholder: "e.g. Arjun")
        case 1:
            title(L("Does %@ have an official disability degree (GdB)?", childName), why: "The disability degree decides your tax allowance. It's on the disability ID or the decision letter.")
            single(["Not yet", "20", "30", "40", "50", "60", "70", "80", "90", "100"],
                   selected: app.profile.gdb.map { $0 == 0 ? "Not yet" : "\($0)" }) { value in
                app.profile.gdb = Int(value) ?? 0
            }
        case 2:
            title(L("Any letters (ID marks) on the disability ID?"), why: "Marks like H or aG unlock much higher allowances. Most children have none.")
            multiMarks
        case 3:
            title(L("Does %@ have a care level (Pflegegrad)?", childName), why: "The care level unlocks monthly care money and support budgets from the care insurer.")
            single(["None", "1", "2", "3", "4", "5"],
                   selected: app.profile.pflegegrad.map { $0 == 0 ? "None" : "\($0)" }) { value in
                app.profile.pflegegrad = Int(value) ?? 0
            }
        case 4:
            title(L("Do you care for %@ at home?", childName), why: "Care at home unlocks the caregiver tax allowance and care allowance.")
            single(["Yes, we care at home", "No, mostly in a care facility"],
                   selected: app.profile.careAtHome.map { $0 ? "Yes, we care at home" : "No, mostly in a care facility" }) { value in
                app.profile.careAtHome = value.hasPrefix("Yes")
            }
        case 5:
            title(L("How many hours a week do you work?"), why: "If you work 30 hours or less, the care insurer can pay into your pension.")
            single(["Not working", "Up to 30 hours", "More than 30 hours"],
                   selected: app.profile.caregiverWorkHours.map { $0 == 0 ? "Not working" : ($0 <= 30 ? "Up to 30 hours" : "More than 30 hours") }) { value in
                app.profile.caregiverWorkHours = value == "Not working" ? 0 : (value == "Up to 30 hours" ? 20 : 40)
            }
        case 6:
            title(L("Since when has %@ had this status?", childName), why: "If it started earlier, you can often claim money back for past tax years.")
            single(["2026", "2025", "2024", "2023", "2022 or earlier"],
                   selected: app.profile.statusSinceYear.map { $0 <= 2022 ? "2022 or earlier" : "\($0)" }) { value in
                app.profile.statusSinceYear = Int(value.prefix(4))
            }
        case 7:
            title(L("What do you already receive?"), why: "So we don't suggest things you already have.")
            toggleRow("Child benefit (Kindergeld)", isOn: $state.profile.receivesKindergeld)
            toggleRow("Care allowance (Pflegegeld)", isOn: $state.profile.receivesPflegegeld)
        case 8:
            title(L("Did you move to Germany in the last 3 years?"), why: "Newcomers get a short checklist, and foreign diagnoses often need a German assessment.")
            single(["Yes", "No"], selected: app.profile.newToGermany.map { $0 ? "Yes" : "No" }) { value in
                app.profile.newToGermany = value == "Yes"
            }
        default:
            title(L("Have the care-level decision at hand?"), why: "Take a photo and Claude reads the values for you. You confirm each one. This makes your estimate more certain.")
            HStack(spacing: Space.md) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.lilac700)
                VStack(alignment: .leading, spacing: 4) {
                    AILabel(text: L("AI-read"))
                    Text(L("Care-level decision (Pflegegrad-Bescheid) or disability ID"))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.ink500)
                }
            }
            .card(.lilac100)
            Button(L("Scan a document")) { showScan = true }
                .buttonStyle(.aiPrimary)
        }
    }

    private var childName: String { app.profile.childName.isEmpty ? L("your child") : app.profile.childName }

    private var footer: some View {
        VStack {
            Button(app.profileStep == stepCount - 1 ? L("Skip and see my result") : L("Next")) {
                Haptics.tap()
                withAnimation(.snappy) {
                    if app.profileStep < stepCount - 1 { app.profileStep += 1 } else { app.stage = .result }
                }
            }
            .buttonStyle(.primary)
        }
        .padding(Space.xl)
        .background(Color.paper)
    }

    private func title(_ text: String, why: String) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text(L(text)).font(.title).foregroundStyle(Color.ink900)
            Label(L(why), systemImage: "questionmark.circle")
                .font(.system(size: 15))
                .foregroundStyle(Color.ink500)
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L(label)).font(.caption13).foregroundStyle(Color.ink500)
            TextField(L(placeholder), text: text)
                .font(.body17)
                .padding(Space.lg)
                .background(Color.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.border))
        }
    }

    private func single(_ options: [String], selected: String?, onSelect: @escaping (String) -> Void) -> some View {
        VStack(spacing: Space.sm) {
            ForEach(options, id: \.self) { option in
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { onSelect(option) }
                } label: {
                    optionRow(option, selected: selected == option)
                }
            }
        }
    }

    private var multiMarks: some View {
        VStack(spacing: Space.sm) {
            Button {
                app.profile.merkzeichen = []
            } label: {
                optionRow("No marks", selected: app.profile.merkzeichen.isEmpty)
            }
            ForEach(Merkzeichen.allCases) { mark in
                Button {
                    Haptics.tap()
                    withAnimation {
                        if app.profile.merkzeichen.contains(mark) { app.profile.merkzeichen.remove(mark) }
                        else { app.profile.merkzeichen.insert(mark) }
                    }
                } label: {
                    optionRow(mark.rawValue + " — " + mark.meaning, selected: app.profile.merkzeichen.contains(mark))
                }
            }
        }
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        Button { isOn.wrappedValue.toggle() } label: {
            optionRow(label, selected: isOn.wrappedValue, checkbox: true)
        }
    }

    private func optionRow(_ label: String, selected: Bool, checkbox: Bool = false) -> some View {
        HStack {
            Text(L(label)).font(.system(size: 17, weight: .medium)).foregroundStyle(Color.ink900)
            Spacer()
            Image(systemName: selected ? (checkbox ? "checkmark.square.fill" : "checkmark.circle.fill") : (checkbox ? "square" : "circle"))
                .foregroundStyle(selected ? Color.green500 : Color.border)
                .font(.system(size: 22))
        }
        .padding(Space.lg)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(selected ? Color.green500 : Color.border, lineWidth: selected ? 2 : 1)
        )
    }
}
