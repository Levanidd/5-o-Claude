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
        let child = p.childName.isEmpty ? "Your child" : p.childName

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
                title: "Disability lump-sum allowance",
                germanTerm: "Behinderten-Pauschbetrag",
                summary: "A fixed tax allowance for your child's disability. It can be transferred to you as a parent. No receipts needed.",
                kind: .taxDeduction, grossAmount: disabilityDeduction, unit: "year",
                valuePerYear: disabilityDeduction * assumedTaxRate, valueOnce: 0,
                confidence: conf(gdbDoc),
                reasons: [
                    Reason(label: "\(child) has a disability degree (GdB) of \(gdb) — at least 20 needed", met: true, fromDocument: gdbDoc),
                    Reason(label: "You get child benefit for \(child), so the allowance can move to you", met: p.receivesKindergeld, fromDocument: false),
                ] + (special ? [Reason(label: "ID mark H, Bl or TBl → higher allowance of €7,400", met: true, fromDocument: gdbDoc)] : []),
                missingQuestion: nil,
                howToClaim: ["Open your Taxfix return", "Add the child's disability degree in the child section", "Taxfix applies the lump-sum automatically"],
                legalSource: "§ 33b (3) EStG", sourceURL: URL(string: "https://www.gesetze-im-internet.de/estg/__33b.html"),
                action: .taxfix, effortMinutes: 5, alreadyReceived: false))
        }

        // 2. Caregiver lump-sum (§33b(6) EStG)
        var caregiverDeduction: Double = 0
        if (pg >= 2 || marks.contains(.H)) && p.careAtHome != false {
            caregiverDeduction = marks.contains(.H) ? 1800 : (caregiverLumpSum[pg] ?? 0)
            result.append(Opportunity(
                id: "tax_caregiver_lumpsum", category: .tax,
                title: "Caregiver lump-sum allowance",
                germanTerm: "Pflege-Pauschbetrag",
                summary: "A tax allowance for caring for your child at home without being paid for it.",
                kind: .taxDeduction, grossAmount: caregiverDeduction, unit: "year",
                valuePerYear: caregiverDeduction * assumedTaxRate, valueOnce: 0,
                confidence: conf(pgDoc, missing: p.careAtHome == nil),
                reasons: [
                    Reason(label: "Care level (Pflegegrad) \(pg) — at least 2 needed", met: pg >= 2 || marks.contains(.H), fromDocument: pgDoc),
                    Reason(label: "You care for \(child) at home, unpaid", met: atHome, fromDocument: false),
                ],
                missingQuestion: p.careAtHome == nil ? "Do you care for your child at home?" : nil,
                howToClaim: ["Open your Taxfix return", "Add the care level and that you care at home", "Taxfix applies the lump-sum"],
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
                title: "Disability travel allowance",
                germanTerm: "Behinderungsbedingte Fahrtkostenpauschale",
                summary: "A tax allowance for private trips caused by the disability.",
                kind: .taxDeduction, grossAmount: travelDeduction, unit: "year",
                valuePerYear: travelDeduction * assumedTaxRate, valueOnce: 0,
                confidence: conf(gdbDoc),
                reasons: [
                    Reason(label: travelHigh ? "ID mark aG, Bl, TBl or H → €4,500" : "GdB ≥ 80, or GdB ≥ 70 with mark G → €900", met: true, fromDocument: gdbDoc),
                ],
                missingQuestion: nil,
                howToClaim: ["Open your Taxfix return", "Taxfix adds the travel allowance with the disability details"],
                legalSource: "§ 33 (2a) EStG", sourceURL: URL(string: "https://www.gesetze-im-internet.de/estg/__33.html"),
                action: .taxfix, effortMinutes: 2, alreadyReceived: false))
        }

        // 4. Past tax years
        let yearlyTax = (disabilityDeduction + caregiverDeduction + travelDeduction) * assumedTaxRate
        if yearlyTax > 0, let since = p.statusSinceYear, since < currentYear {
            let years = min(4, currentYear - since)
            result.append(Opportunity(
                id: "tax_past_years", category: .tax,
                title: "Money back for past years",
                germanTerm: "Steuererklärung für Vorjahre",
                summary: "The status already applied in earlier years. You can file or amend those tax returns and claim the allowances there too.",
                kind: .taxDeduction, grossAmount: (disabilityDeduction + caregiverDeduction + travelDeduction) * Double(years), unit: "once",
                valuePerYear: 0, valueOnce: yearlyTax * Double(years),
                confidence: .likely,
                reasons: [
                    Reason(label: "Status since \(since) → \(years) earlier year\(years == 1 ? "" : "s") can be claimed", met: true, fromDocument: false),
                    Reason(label: "Returns for those years are not final yet (usually up to 4 years back)", met: true, fromDocument: false),
                ],
                missingQuestion: nil,
                howToClaim: ["Open Taxfix and choose the earlier year", "Add the disability and care details", "Submit — the refund comes from the tax office"],
                legalSource: "§ 169 AO (4-year limit)", sourceURL: URL(string: "https://www.gesetze-im-internet.de/ao_1977/__169.html"),
                action: .taxfix, effortMinutes: 15, alreadyReceived: false))
        }

        // 5. Care allowance
        if pg >= 2 && p.careAtHome != false {
            let monthly = careAllowanceMonthly[pg] ?? 0
            result.append(Opportunity(
                id: "care_allowance", category: .care,
                title: "Care allowance",
                germanTerm: "Pflegegeld",
                summary: "A monthly payment from the care insurer when you care for your child at home.",
                kind: .cashBenefit, grossAmount: monthly, unit: "month",
                valuePerYear: monthly * 12, valueOnce: 0,
                confidence: conf(pgDoc, missing: p.careAtHome == nil),
                reasons: [
                    Reason(label: "Care level \(pg) — at least 2 needed", met: true, fromDocument: pgDoc),
                    Reason(label: "Care happens at home", met: atHome, fromDocument: false),
                ],
                missingQuestion: nil,
                howToClaim: ["Apply to your care insurer (Pflegekasse)", "Payment arrives monthly"],
                legalSource: "§ 37 SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__37.html"),
                action: .letter, effortMinutes: 10, alreadyReceived: p.receivesPflegegeld))
        }

        // 6. Relief amount
        if pg >= 1 {
            result.append(Opportunity(
                id: "care_relief_amount", category: .care,
                title: "Relief amount",
                germanTerm: "Entlastungsbetrag",
                summary: "€131 a month for approved help at home, like a carer or support services. Unused money carries over.",
                kind: .cashBenefit, grossAmount: reliefMonthly, unit: "month",
                valuePerYear: reliefMonthly * 12, valueOnce: 0,
                confidence: conf(pgDoc),
                reasons: [Reason(label: "Care level \(pg) — at least 1 needed", met: true, fromDocument: pgDoc)],
                missingQuestion: nil,
                howToClaim: ["Book an approved support service", "Send the invoices to your care insurer", "They pay back up to €131 a month"],
                legalSource: "§ 45b SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__45b.html"),
                action: .letter, effortMinutes: 5, alreadyReceived: false))
        }

        // 7. Respite + short-term care budget
        if pg >= 2 {
            result.append(Opportunity(
                id: "care_respite_budget", category: .care,
                title: "Respite care budget",
                germanTerm: "Verhinderungs- und Kurzzeitpflege",
                summary: "Money for someone else to care for your child when you need a break, are ill or on holiday.",
                kind: .cashBenefit, grossAmount: respiteYearly, unit: "year",
                valuePerYear: respiteYearly, valueOnce: 0,
                confidence: conf(pgDoc),
                reasons: [Reason(label: "Care level \(pg) — at least 2 needed", met: true, fromDocument: pgDoc)],
                missingQuestion: nil,
                howToClaim: ["Find a person or service to cover care", "Apply to your care insurer", "Send the invoices"],
                legalSource: "§§ 39, 42 SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__39.html"),
                action: .letter, effortMinutes: 10, alreadyReceived: false))
        }

        // 8. Care supplies
        if pg >= 1 && p.careAtHome != false {
            result.append(Opportunity(
                id: "care_consumables", category: .care,
                title: "Care supplies",
                germanTerm: "Pflegehilfsmittel zum Verbrauch",
                summary: "Up to €42 a month for gloves, disinfectant, bed protectors and similar supplies.",
                kind: .cashBenefit, grossAmount: consumablesMonthly, unit: "month",
                valuePerYear: consumablesMonthly * 12, valueOnce: 0,
                confidence: conf(pgDoc, missing: p.careAtHome == nil),
                reasons: [
                    Reason(label: "Care level \(pg) — at least 1 needed", met: true, fromDocument: pgDoc),
                    Reason(label: "Care happens at home", met: atHome, fromDocument: false),
                ],
                missingQuestion: nil,
                howToClaim: ["Send a short application to your care insurer", "Choose a supplier — boxes arrive monthly"],
                legalSource: "§ 40 (2) SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__40.html"),
                action: .letter, effortMinutes: 5, alreadyReceived: false))
        }

        // 9. Home adaptation
        if pg >= 1 {
            result.append(Opportunity(
                id: "care_home_adaptation", category: .care,
                title: "Home adaptation grant",
                germanTerm: "Wohnumfeldverbessernde Maßnahmen",
                summary: "Up to €4,180 per measure to make your home safer or easier for care. Apply before the work starts.",
                kind: .cashBenefit, grossAmount: homeAdaptationMax, unit: "once",
                valuePerYear: 0, valueOnce: 0,
                confidence: .needsInfo,
                reasons: [
                    Reason(label: "Care level \(pg) — at least 1 needed", met: true, fromDocument: pgDoc),
                    Reason(label: "An adaptation at home is needed", met: false, fromDocument: false),
                ],
                missingQuestion: "Does your home need changes (safety locks, bathroom, ramp)?",
                howToClaim: ["Get a quote for the work", "Apply to your care insurer before work starts"],
                legalSource: "§ 40 (4) SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__40.html"),
                action: .letter, effortMinutes: 20, alreadyReceived: false))
        }

        // 10. Caregiver pension credits
        if pg >= 2 {
            let hours = p.caregiverWorkHours
            let worksLittle = (hours ?? 99) <= 30
            result.append(Opportunity(
                id: "pension_caregiver", category: .pension,
                title: "Pension credits for caring",
                germanTerm: "Rentenpunkte für Pflegepersonen",
                summary: "The care insurer pays into your pension while you care. Check that you are registered.",
                kind: .nonCash, grossAmount: 0, unit: "year",
                valuePerYear: 0, valueOnce: 0,
                confidence: hours == nil ? .needsInfo : (worksLittle ? .likely : .needsInfo),
                reasons: [
                    Reason(label: "Care level \(pg) — at least 2 needed", met: true, fromDocument: pgDoc),
                    Reason(label: "You work 30 hours a week or less", met: worksLittle, fromDocument: false),
                    Reason(label: "At least 10 hours of care a week, over 2+ days", met: true, fromDocument: false),
                ],
                missingQuestion: hours == nil ? "How many hours a week do you work?" : nil,
                howToClaim: ["Ask your care insurer to confirm you are registered as a caregiver"],
                legalSource: "§ 44 SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_11/__44.html"),
                action: .letter, effortMinutes: 5, alreadyReceived: false))
        }

        // No status yet → first step
        if gdb == 0 && pg == 0 && p.gdb != nil && p.pflegegrad != nil {
            result.append(Opportunity(
                id: "apply_status", category: .start,
                title: "Apply for a disability degree or care level",
                germanTerm: "GdB-Antrag / Pflegegrad-Antrag",
                summary: "Most support starts with an official disability degree (GdB) or care level (Pflegegrad). Applying is free.",
                kind: .info, grossAmount: 0, unit: "once", valuePerYear: 0, valueOnce: 0,
                confidence: .needsInfo,
                reasons: [Reason(label: "No disability degree or care level yet", met: true, fromDocument: false)],
                missingQuestion: nil,
                howToClaim: ["Apply for a GdB at the state disability office (Versorgungsamt)", "Apply for a care level at your care insurer"],
                legalSource: "§ 152 SGB IX · § 18 SGB XI", sourceURL: URL(string: "https://www.gesetze-im-internet.de/sgb_9_2018/__152.html"),
                action: .letter, effortMinutes: 20, alreadyReceived: false))
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
