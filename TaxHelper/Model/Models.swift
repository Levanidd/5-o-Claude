import Foundation

enum Lang: String, Codable, CaseIterable, Identifiable {
    case en, de, tr, ar, uk, ru, pl, es
    var id: String { rawValue }

    var name: String {
        switch self {
        case .en: "English"
        case .de: "Deutsch"
        case .tr: "Türkçe"
        case .ar: "العربية"
        case .uk: "Українська"
        case .ru: "Русский"
        case .pl: "Polski"
        case .es: "Español"
        }
    }

    var flag: String {
        switch self {
        case .en: "🇬🇧"
        case .de: "🇩🇪"
        case .tr: "🇹🇷"
        case .ar: "🇸🇦"
        case .uk: "🇺🇦"
        case .ru: "🇷🇺"
        case .pl: "🇵🇱"
        case .es: "🇪🇸"
        }
    }
}

enum Merkzeichen: String, Codable, CaseIterable, Identifiable {
    case G, aG, H, Bl, TBl, B, Gl
    var id: String { rawValue }

    var meaning: String {
        switch self {
        case .G: L("Walking impaired")
        case .aG: L("Severely walking impaired")
        case .H: L("Helpless (needs constant help)")
        case .Bl: L("Blind")
        case .TBl: L("Deafblind")
        case .B: L("Needs a companion")
        case .Gl: L("Deaf")
        }
    }
}

/// Where a profile value came from. Values read from a confirmed document make rules "confirmed".
enum ValueSource: String, Codable {
    case answer, document
}

struct Profile: Codable, Equatable {
    var parentName = ""
    var childName = ""
    var gdb: Int?
    var gdbSource: ValueSource = .answer
    var merkzeichen: Set<Merkzeichen> = []
    var pflegegrad: Int?
    var pflegegradSource: ValueSource = .answer
    var careAtHome: Bool?
    var caregiverWorkHours: Int?
    var statusSinceYear: Int?
    var receivesKindergeld = false
    var receivesPflegegeld = false
    var newToGermany: Bool?
    var state = "BE"

    static let demo = Profile(
        parentName: "Priya",
        childName: "Arjun",
        gdb: 50,
        merkzeichen: [],
        pflegegrad: 3,
        careAtHome: true,
        caregiverWorkHours: 20,
        statusSinceYear: 2025,
        receivesKindergeld: true,
        receivesPflegegeld: true,
        newToGermany: true
    )
}

enum Confidence: String, Codable {
    case confirmed, likely, needsInfo

    var label: String {
        switch self {
        case .confirmed: L("Confirmed")
        case .likely: L("Likely")
        case .needsInfo: L("Needs 1 answer")
        }
    }
}

enum Kind: String, Codable {
    case taxDeduction, cashBenefit, nonCash, info
}

enum ClaimAction: String, Codable {
    case taxfix, letter, info
}

enum CaseStatus: String, Codable, CaseIterable {
    case found, inProgress, submitted, approved

    var label: String {
        switch self {
        case .found: L("Found")
        case .inProgress: L("In progress")
        case .submitted: L("Submitted")
        case .approved: L("Approved")
        }
    }
}

struct Reason: Identifiable, Hashable {
    var id: String { label }
    let label: String
    let met: Bool
    let fromDocument: Bool
}

enum Category: String {
    case tax, care, pension, start

    var icon: String {
        switch self {
        case .tax: "eurosign.circle"
        case .care: "heart.circle"
        case .pension: "building.columns.circle"
        case .start: "doc.badge.plus"
        }
    }
}

struct Opportunity: Identifiable, Hashable {
    let id: String
    let category: Category
    let title: String
    let germanTerm: String
    let summary: String
    let kind: Kind
    /// Gross amount: deduction for tax items, payment for cash items.
    let grossAmount: Double
    let unit: String
    /// Comparable money per year: estimated tax saving (≈30%) for deductions, cash per year for benefits.
    let valuePerYear: Double
    /// One-off money (e.g. past tax years, home adaptation).
    let valueOnce: Double
    let confidence: Confidence
    let reasons: [Reason]
    let missingQuestion: String?
    let howToClaim: [String]
    let legalSource: String
    let sourceURL: URL?
    let action: ClaimAction
    let effortMinutes: Int
    let alreadyReceived: Bool

    var valueLabel: String {
        switch kind {
        case .taxDeduction: L("tax saving ≈")
        case .cashBenefit: L("paid to you")
        case .nonCash: L("builds your pension")
        case .info: L("first step")
        }
    }

    /// Facts sent to Claude. No names.
    var ruleData: [String: Any] {
        [
            "id": id,
            "title": title,
            "germanTerm": germanTerm,
            "summary": summary,
            "kind": kind.rawValue,
            "amount": grossAmount,
            "unit": unit,
            "estimatedValuePerYear": valuePerYear,
            "conditionsMet": reasons.filter(\.met).map(\.label),
            "conditionsMissing": reasons.filter { !$0.met }.map(\.label),
            "howToClaim": howToClaim,
            "legalSource": legalSource,
        ]
    }
}

// MARK: - AI results

struct LetterExplanation: Codable, Equatable {
    var sender: String?
    var subject: String?
    var whatItSays: String
    var whatToDo: [String]
    var deadline: String?
    var amount: String?
    var fileNumber: String?
    var lockedTokens: [String]?
    var translation: String?
}

struct GermanDraft: Codable, Equatable {
    var letterDe: String
    var translation: String
    var lockedTokens: [String]?
}

struct OpportunityExplanation: Codable, Equatable {
    var plainExplanation: String
    var whyBullets: [String]
    var howToSteps: [String]
}

struct CardAnswer: Codable, Equatable {
    var answer: String
    var citedSource: String?
    var escalate: Bool?
}

struct ExtractedDocument: Codable, Equatable {
    var docType: String?
    var pflegegrad: Int?
    var gdb: Int?
    var merkzeichen: [String]?
    var validFrom: String?
    var fileNumber: String?
    var childName: String?
    var summary: String?
    var confidence: String?
}

struct Letter: Identifiable {
    let id = UUID()
    var originalText: String?
    var imageData: Data?
    var explanation: LetterExplanation?
}

struct Deadline: Identifiable, Hashable {
    let id: String
    let title: String
    /// dd.MM.yyyy, as printed on German letters.
    let date: String
    let steps: [String]
    var source: String?
    var opportunityID: String?

    private static let parser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    var due: Date? { Self.parser.date(from: date) }

    var daysLeft: Int? {
        guard let due else { return nil }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: .now), to: cal.startOfDay(for: due)).day
    }

    var urgent: Bool { (daysLeft ?? .max) <= 60 }
}
