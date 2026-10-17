import SwiftUI

struct ConfidenceBadge: View {
    let confidence: Confidence

    var body: some View {
        switch confidence {
        case .confirmed:
            Chip(text: confidence.label, icon: "checkmark.seal.fill", fg: .white, bg: .green500)
        case .likely:
            Chip(text: confidence.label, icon: "checkmark.circle", fg: .green800, bg: .green100)
        case .needsInfo:
            Chip(text: confidence.label, icon: "questionmark.circle", fg: .ink900, bg: .gold100)
        }
    }
}

struct StatusBadge: View {
    let status: CaseStatus

    var body: some View {
        switch status {
        case .found: Chip(text: status.label, icon: "sparkle.magnifyingglass")
        case .inProgress: Chip(text: status.label, icon: "pencil", fg: .blue500, bg: .blue100)
        case .submitted: Chip(text: status.label, icon: "paperplane", fg: .blue500, bg: .blue100)
        case .approved: Chip(text: status.label, icon: "checkmark", fg: .green800, bg: .green100)
        }
    }
}

struct OpportunityAmount: View {
    let opportunity: Opportunity

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(opportunity.valueLabel).font(.system(size: 11, weight: .medium)).foregroundStyle(Color.ink500)
            Text(amountText)
                .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.green800)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var amountText: String {
        let o = opportunity
        switch o.kind {
        case .nonCash: return "✓"
        case .info: return "Free"
        default:
            if o.valueOnce > 0 { return euro(o.valueOnce) }
            if o.unit == "once" { return "up to " + euro(o.grossAmount) }
            if o.unit == "month" { return euro(o.grossAmount) + "/mo" }
            return euro(o.valuePerYear) + "/yr"
        }
    }
}

struct OpportunityRow: View {
    let opportunity: Opportunity
    let status: CaseStatus

    var body: some View {
        HStack(alignment: .top, spacing: Space.md) {
            Image(systemName: opportunity.category.icon)
                .font(.system(size: 28))
                .foregroundStyle(Color.green800)
            VStack(alignment: .leading, spacing: 6) {
                Text(opportunity.title).font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.ink900)
                Text(opportunity.germanTerm).font(.system(size: 13).italic()).foregroundStyle(Color.ink500)
                HStack(spacing: 6) {
                    ConfidenceBadge(confidence: opportunity.confidence)
                    if status != .found { StatusBadge(status: status) }
                    else { Chip(text: "\(opportunity.effortMinutes) min", icon: "clock") }
                }
            }
            Spacer(minLength: 0)
            OpportunityAmount(opportunity: opportunity)
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}
