import Foundation

/// Fixed rules decide eligibility and amounts. Claude never does.
/// Amounts as of 2026 (Project context §7.2). Check against official sources before the demo.
enum RulesEngine {
    static let assumedTaxRate = 0.30
    static let currentYear = 2026
    static let verifiedOn = "2026-10-17"

    static let gdbLumpSum: [Int: Double] = [
        20: 384, 30: 620, 40: 860, 50: 1140, 60: 1440,
        70: 1780, 80: 2120, 90: 2460, 100: 2840,
    ]
    static let caregiverLumpSum: [Int: Double] = [2: 600, 3: 1100, 4: 1800, 5: 1800]
    static let careAllowanceMonthly: [Int: Double] = [2: 347, 3: 599, 4: 800, 5: 990]
    static let reliefMonthly: Double = 131
    static let respiteYearly: Double = 3539
    static let consumablesMonthly: Double = 42
    static let homeAdaptationMax: Double = 4180

    static func evaluate(_ p: Profile) -> [Opportunity] {
        var result: [Opportunity] = []
        let gdb = p.gdb ?? 0
        let pg = p.pflegegrad ?? 0
        let marks = p.merkzeichen
        let atHome = p.careAtHome ?? false
        let gdbDoc = p.gdbSource == .document
        let pgDoc = p.pflegegradSource == .document
        let child = p.childName.isEmpty ? L("Your child") : p.childName

        func conf(_ fromDocument: Bool, missing: Bool = false) -> Confidence {
            missing ? .needsInfo : (fromDocument ? .confirmed : .likely)
        }

        // 1. Disability lump-sum (§33b EStG)
        var disabilityDeduction: Double = 0
        if gdb >= 20 || marks.contains(.H) || marks.contains(.Bl) || marks.contains(.TBl) {
            let special = marks.contains(.H) || marks.contains(.Bl) || marks.contains(.TBl)
            disabilityDeduction = special ? 7400 : (gdbLumpSum[min(gdb / 10 * 10, 100)] ?? 0)
            result.append(Opportunity(
                id: "tax_disability_lumpsum", category: .tax,
                title: L("Disability lump-sum allowance"),
                germanTerm: "Behinderten-Pauschbetrag",
                summary: L("A fixed tax allowance for your child's disability. It can be transferred to you as a parent. No receipts needed."),
                kind: .taxDeduction, grossAmount: disabilityDeduction, unit: "year",
                valuePerYear: disabilityDeduction * assumedTaxRate, valueOnce: 0,
                confidence: conf(gdbDoc),
                reasons: [
                    Reason(label: L("%@ has a disability degree (GdB) of %@ — at least 20 needed", child, gdb), met: true, fromDocument: gdbDoc),
                    Reason(label: L("You get child benefit for %@, so the allowance can move to you", child), met: p.receivesKindergeld, fromDocument: false),
                ] + (special ? [Reason(label: L("ID mark H, Bl or TBl → higher allowance of €7,400"), met: true, fromDocument: gdbDoc)] : []),
                missingQuestion: nil,
                howToClaim: [L("Open your Taxfix return"), L("Add the child's disability degree in the child section"), L("Taxfix applies the lump-sum automatically")],
                legalSource: "§ 33b (3) EStG", sourceURL: URL(string: "https://www.gesetze-im-internet.de/estg/__33b.html"),
                action: .taxfix, effortMinutes: 5, alreadyReceived: false))
        }

        // 2. Caregiver lump-sum (§33b(6) EStG)
        var caregiverDeduction: Double = 0
        if (pg >= 2 || marks.contains(.H)) && p.careAtHome != false {
            caregiverDeduction = marks.contains(.H) ? 1800 : (caregiverLumpSum[pg] ?? 0)
            result.append(Opportunity(
                id: "tax_caregiver_lumpsum", category: .tax,
                title: L("Caregiver lump-sum allowance"),
                germanTerm: "Pflege-Pauschbetrag",
                summary: L("A tax allowance for caring for your child at home without being paid for it."),
                kind: .taxDeduction, grossAmount: caregiverDeduction, unit: "year",
                valuePerYear: caregiverDeduction * assumedTaxRate, valueOnce: 0,
                confidence: conf(pgDoc, missing: p.careAtHome == nil),
                reasons: [
                    Reason(label: L("Care level (Pflegegrad) %@ — at least 2 needed", pg), met: pg >= 2 || marks.contains(.H), fromDocument: pgDoc),
                    Reason(label: L("You care for %@ at home, unpaid", child), met: atHome, fromDocument: false),
                ],
                missingQuestion: p.careAtHome == nil ? L("Do you care for your child at home?") : nil,
                howToClaim: [L("Open your Taxfix return"), L("Add the care level and that you care at home"), L("Taxfix applies the lump-sum")],
                legalSource: "§ 33b (6) EStG", sourceURL: URL(string: "https://www.gesetze-im-internet.de/estg/__33b.html"),
                action: .taxfix, effortMinutes: 3, alreadyReceived: false))
        }

        // 3. Disability travel allowance
        let travelHigh = marks.contains(.aG) || marks.contains(.Bl) || marks.contains(.TBl) || marks.contains(.H)
        let travelLow = gdb >= 80 || (gdb >= 70 && marks.contains(.G))
        var travelDeduction: Double = 0
        if travelHigh || travelLow {
            travelDeduction = travelHigh ? 4500 : 900
            result.append(Opportunity(
                id: "tax_travel_lumpsum", category: .tax,
                title: L("Disability travel allowance"),
                germanTerm: "Behinderungsbedingte Fahrtkostenpauschale",
                summary: L("A tax allowance for private trips caused by the disability."),
                kind: .taxDeduction, grossAmount: travelDeduction, unit: "year",
                valuePerYear: travelDeduction * assumedTaxRate, valueOnce: 0,
                confidence: conf(gdbDoc),
                reasons: [
                    Reason(label: travelHigh ? L("ID mark aG, Bl, TBl or H → €4,500") : L("GdB ≥ 80, or GdB ≥ 70 with mark G → €900"), met: true, fromDocument: gdbDoc),
                ],
                missingQuestion: nil,
                howToClaim: [L("Open your Taxfix return"), L("Taxfix adds the travel allowance with the disability details")],
                legalSource: "§ 33 (2a) EStG", sourceURL: URL(string: "https://www.gesetze-im-internet.de/estg/__33.html"),
                action: .taxfix, effortMinutes: 2, alreadyReceived: false))
        }

        // 4. Past tax years
        let yearlyTax = (disabilityDeduction + caregiverDeduction + travelDeduction) * assumedTaxRate
        if yearlyTax > 0, let since = p.statusSinceYear, since < currentYear {
            let years = min(4, currentYear - since)
            result.append(Opportunity(
                id: "tax_past_years", category: .tax,
                title: L("Money back for past years"),
                germanTerm: "Steuererklärung für Vorjahre",
                summary: L("The status already applied in earlier years. You can file or amend those tax returns and claim the allowances there too."),
                kind: .taxDeduction, grossAmount: (disabilityDeduction + caregiverDeduction + travelDeduction) * Double(years), unit: "once",
                valuePerYear: 0, valueOnce: yearlyTax * Double(years),
                confidence: .likely,
                reasons: [
                    Reason(label: L("Status since %@ → earlier years to claim: %@", since, years), met: true, fromDocument: false),
                    Reason(label: L("Returns for those years are not final yet (usually up to 4 years back)"), met: true, fromDocument: false),
                ],
                missingQuestion: nil,
                howToClaim: [L("Open Taxfix and choose the earlier year"), L("Add the disability and care details"), L("Submit — the refund comes from the tax office")],
                legalSource: "§ 169 AO (4-year limit)", sourceURL: URL(string: "https://www.gesetze-im-internet.de/ao_1977/__169.html"),
                action: .taxfix, effortMinutes: 15, alreadyReceived: false))
        }

        // 5. Care allowance
        if pg >= 2 && p.careAtHome != false {
            let monthly = careAllowanceMonthly[pg] ?? 0
            result.append(Opportunity(
                id: "care_allowance", category: .care,
                title: L("Care allowance"),
                germanTerm: "Pflegegeld",
                summary: L("A monthly payment from the care insurer when you care for your child at home."),
                kind: .cashBenefit, grossAmount: monthly, unit: "month",
                valuePerYear: monthly * 12, valueOnce: 0,
                confidence: conf(pgDoc, missing: p.careAtHome == nil),
                reasons: [
                    Reason(label: L("Care level %@ — at least 2 needed", pg), met: true, fromDocument: pgDoc),
                    Reason(label: L("Care happens at home"), met: atHome, fromDocument: false),
                ],
                missingQuestion: nil,
                howToClaim: [L("Apply to your care insurer (Pflegekasse)"), L("Payment arrives monthly")],
                legalSource: "§ 37 SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__37.html"),
                action: .letter, effortMinutes: 10, alreadyReceived: p.receivesPflegegeld))
        }

        // 6. Relief amount
        if pg >= 1 {
            result.append(Opportunity(
                id: "care_relief_amount", category: .care,
                title: L("Relief amount"),
                germanTerm: "Entlastungsbetrag",
                summary: L("€131 a month for approved help at home, like a carer or support services. Unused money carries over."),
                kind: .cashBenefit, grossAmount: reliefMonthly, unit: "month",
                valuePerYear: reliefMonthly * 12, valueOnce: 0,
                confidence: conf(pgDoc),
                reasons: [Reason(label: L("Care level %@ — at least 1 needed", pg), met: true, fromDocument: pgDoc)],
                missingQuestion: nil,
                howToClaim: [L("Book an approved support service"), L("Send the invoices to your care insurer"), L("They pay back up to €131 a month")],
                legalSource: "§ 45b SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__45b.html"),
                action: .letter, effortMinutes: 5, alreadyReceived: false))
        }

        // 7. Respite + short-term care budget
        if pg >= 2 {
            result.append(Opportunity(
                id: "care_respite_budget", category: .care,
                title: L("Respite care budget"),
                germanTerm: "Verhinderungs- und Kurzzeitpflege",
                summary: L("Money for someone else to care for your child when you need a break, are ill or on holiday."),
                kind: .cashBenefit, grossAmount: respiteYearly, unit: "year",
                valuePerYear: respiteYearly, valueOnce: 0,
                confidence: conf(pgDoc),
                reasons: [Reason(label: L("Care level %@ — at least 2 needed", pg), met: true, fromDocument: pgDoc)],
                missingQuestion: nil,
                howToClaim: [L("Find a person or service to cover care"), L("Apply to your care insurer"), L("Send the invoices")],
                legalSource: "§§ 39, 42 SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__39.html"),
                action: .letter, effortMinutes: 10, alreadyReceived: false))
        }

        // 8. Care supplies
        if pg >= 1 && p.careAtHome != false {
            result.append(Opportunity(
                id: "care_consumables", category: .care,
                title: L("Care supplies"),
                germanTerm: "Pflegehilfsmittel zum Verbrauch",
                summary: L("Up to €42 a month for gloves, disinfectant, bed protectors and similar supplies."),
                kind: .cashBenefit, grossAmount: consumablesMonthly, unit: "month",
                valuePerYear: consumablesMonthly * 12, valueOnce: 0,
                confidence: conf(pgDoc, missing: p.careAtHome == nil),
                reasons: [
                    Reason(label: L("Care level %@ — at least 1 needed", pg), met: true, fromDocument: pgDoc),
                    Reason(label: L("Care happens at home"), met: atHome, fromDocument: false),
                ],
                missingQuestion: nil,
                howToClaim: [L("Send a short application to your care insurer"), L("Choose a supplier — boxes arrive monthly")],
                legalSource: "§ 40 (2) SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__40.html"),
                action: .letter, effortMinutes: 5, alreadyReceived: false))
        }

        // 9. Home adaptation
        if pg >= 1 {
            result.append(Opportunity(
                id: "care_home_adaptation", category: .care,
                title: L("Home adaptation grant"),
                germanTerm: "Wohnumfeldverbessernde Maßnahmen",
                summary: L("Up to €4,180 per measure to make your home safer or easier for care. Apply before the work starts."),
                kind: .cashBenefit, grossAmount: homeAdaptationMax, unit: "once",
                valuePerYear: 0, valueOnce: 0,
                confidence: .needsInfo,
                reasons: [
                    Reason(label: L("Care level %@ — at least 1 needed", pg), met: true, fromDocument: pgDoc),
                    Reason(label: L("An adaptation at home is needed"), met: false, fromDocument: false),
                ],
                missingQuestion: L("Does your home need changes (safety locks, bathroom, ramp)?"),
                howToClaim: [L("Get a quote for the work"), L("Apply to your care insurer before work starts")],
                legalSource: "§ 40 (4) SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__40.html"),
                action: .letter, effortMinutes: 20, alreadyReceived: false))
        }

        // 10. Caregiver pension credits
        if pg >= 2 {
            let hours = p.caregiverWorkHours
            let worksLittle = (hours ?? 99) <= 30
            result.append(Opportunity(
                id: "pension_caregiver", category: .pension,
                title: L("Pension credits for caring"),
                germanTerm: "Rentenpunkte für Pflegepersonen",
                summary: L("The care insurer pays into your pension while you care. Check that you are registered."),
                kind: .nonCash, grossAmount: 0, unit: "year",
                valuePerYear: 0, valueOnce: 0,
                confidence: hours == nil ? .needsInfo : (worksLittle ? .likely : .needsInfo),
                reasons: [
                    Reason(label: L("Care level %@ — at least 2 needed", pg), met: true, fromDocument: pgDoc),
                    Reason(label: L("You work 30 hours a week or less"), met: worksLittle, fromDocument: false),
                    Reason(label: L("At least 10 hours of care a week, over 2+ days"), met: true, fromDocument: false),
                ],
                missingQuestion: hours == nil ? L("How many hours a week do you work?") : nil,
                howToClaim: [L("Ask your care insurer to confirm you are registered as a caregiver")],
                legalSource: "§ 44 SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__44.html"),
                action: .letter, effortMinutes: 5, alreadyReceived: false))
        }

        // No status yet → first step
        if gdb == 0 && pg == 0 && p.gdb != nil && p.pflegegrad != nil {
            result.append(Opportunity(
                id: "apply_status", category: .start,
                title: L("Apply for a disability degree or care level"),
                germanTerm: "GdB-Antrag / Pflegegrad-Antrag",
                summary: L("Most support starts with an official disability degree (GdB) or care level (Pflegegrad). Applying is free."),
                kind: .info, grossAmount: 0, unit: "once", valuePerYear: 0, valueOnce: 0,
                confidence: .needsInfo,
                reasons: [Reason(label: L("No disability degree or care level yet"), met: true, fromDocument: false)],
                missingQuestion: nil,
                howToClaim: [L("Apply for a GdB at the state disability office (Versorgungsamt)"), L("Apply for a care level at your care insurer")],
                legalSource: "§ 152 SGB IX · § 18 SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_9_2018/__152.html"),
                action: .letter, effortMinutes: 20, alreadyReceived: false))
        }

        return result
    }

    /// Legal deadlines that follow from the profile alone, so the parent sees them before any letter arrives.
    static func deadlines(_ p: Profile, _ opportunities: [Opportunity], today: Date = .now) -> [Deadline] {
        let cal = Calendar.current
        let y = currentYear
        let month = cal.component(.month, from: today)
        let endOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: cal.date(from: cal.dateComponents([.year, .month], from: today))!)!
        let endOfMonthText = String(format: "%02d.%02d.%d", cal.component(.day, from: endOfMonth), month, cal.component(.year, from: endOfMonth))
        let pg = p.pflegegrad ?? 0
        func opp(_ id: String) -> Opportunity? { opportunities.first { $0.id == id } }
        var result: [Deadline] = []

        if let o = opp("care_allowance"), !o.alreadyReceived {
            result.append(Deadline(
                id: "apply_care_allowance", title: L("Apply for care allowance — it's paid only from the month you apply"),
                date: endOfMonthText, steps: o.howToClaim, source: "§ 33 (1) SGB XI", opportunityID: o.id))
        }

        if let o = opp("apply_status") {
            result.append(Deadline(
                id: "apply_status", title: L("Apply now — support starts from the month you apply"),
                date: endOfMonthText, steps: o.howToClaim, source: "§ 33 (1) SGB XI", opportunityID: o.id))
        }

        if p.receivesPflegegeld, pg >= 2, p.careAtHome != false {
            let quarterly = pg >= 4
            let periodEnd = quarterly ? ((month - 1) / 3 + 1) * 3 : (month <= 6 ? 6 : 12)
            let day = periodEnd == 6 || periodEnd == 9 ? 30 : 31
            result.append(Deadline(
                id: "advice_visit_\(y)_\(periodEnd)", title: L("Send proof of the care advice visit"),
                date: String(format: "%02d.%02d.%d", day, periodEnd, y),
                steps: [L("Book the advice visit with an approved care service"), L("Ask for the written proof (Nachweis)"), L("Send it to your care insurer")],
                source: "§ 37 (3) SGB XI", opportunityID: opp("care_allowance")?.id))
        }

        if let o = opp("care_respite_budget") {
            result.append(Deadline(
                id: "respite_\(y)", title: L("Respite care budget %@ runs out", y),
                date: "31.12.\(y)", steps: o.howToClaim, source: "§ 42a SGB XI", opportunityID: o.id))
        }

        if let o = opp("care_relief_amount") {
            result.append(Deadline(
                id: "relief_\(y)", title: L("Relief amount %@: unused money expires", y),
                date: "30.06.\(y + 1)", steps: o.howToClaim, source: "§ 45b SGB XI", opportunityID: o.id))
        }

        if let o = opp("tax_past_years"), let since = p.statusSinceYear {
            let earliest = max(since, y - 4)
            result.append(Deadline(
                id: "tax_\(earliest)", title: L("Tax refund for %@: last day to file", earliest),
                date: "31.12.\(earliest + 4)", steps: o.howToClaim, source: "§ 169 AO", opportunityID: o.id))
        }

        return result
    }

    /// Next best action: € × likelihood ÷ effort.
    static func rank(_ opportunities: [Opportunity]) -> [Opportunity] {
        opportunities.sorted { score($0) > score($1) }
    }

    static func score(_ o: Opportunity) -> Double {
        let likelihood: Double = switch o.confidence {
        case .confirmed: 1.0
        case .likely: 0.8
        case .needsInfo: 0.4
        }
        let value = o.valuePerYear + o.valueOnce + (o.kind == .info ? 500 : 0)
        return value * likelihood / Double(max(o.effortMinutes, 1))
    }

    static func totals(_ opportunities: [Opportunity]) -> (perYear: Double, once: Double) {
        let open = opportunities.filter { !$0.alreadyReceived }
        return (open.reduce(0) { $0 + $1.valuePerYear }, open.reduce(0) { $0 + $1.valueOnce })
    }
}
