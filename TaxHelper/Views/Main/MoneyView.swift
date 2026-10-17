import SwiftUI

struct MoneyView: View {
    @Environment(AppState.self) private var app
    @State private var filter = "All"
    private let filters = ["All", "Tax", "Care"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    Picker(L("Filter"), selection: $filter) {
                        ForEach(filters, id: \.self) { Text(L($0)) }
                    }
                    .pickerStyle(.segmented)

                    ForEach(CaseStatus.allCases, id: \.self) { status in
                        let items = filtered.filter { app.status($0) == status }
                        if !items.isEmpty {
                            Text(status == .approved ? L("Already coming in") : status.label)
                                .font(.heading)
                                .foregroundStyle(Color.ink900)
                                .padding(.top, Space.sm)
                            ForEach(items) { o in
                                NavigationLink(value: o) {
                                    OpportunityRow(opportunity: o, status: app.status(o))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(Space.lg)
            }
            .screenBackground()
            .navigationTitle(L("Money"))
            .navigationDestination(for: Opportunity.self) { OpportunityDetailView(opportunity: $0) }
        }
    }

    private var filtered: [Opportunity] {
        switch filter {
        case "Tax": app.opportunities.filter { $0.category == .tax }
        case "Care": app.opportunities.filter { $0.category != .tax }
        default: app.opportunities
        }
    }
}
