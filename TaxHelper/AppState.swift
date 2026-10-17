import Foundation
import Observation

enum Stage: String, Codable {
    case language, welcome, profile, result, main
}

@Observable
final class AppState {
    var stage: Stage { didSet { save() } }
    var language: Lang { didSet { save() } }
    var profile: Profile { didSet { save() } }
    var statuses: [String: CaseStatus] { didSet { save() } }
    var profileStep: Int { didSet { save() } }
    var letters: [Letter] = []
    var deadlines: [Deadline] = []
    var banner: String?

    var opportunities: [Opportunity] {
        RulesEngine.rank(RulesEngine.evaluate(profile))
    }

    var openOpportunities: [Opportunity] {
        opportunities.filter { !$0.alreadyReceived && status($0) != .approved && status($0) != .submitted }
    }

    var nextBestAction: Opportunity? {
        openOpportunities.first { status($0) == .found && $0.kind != .nonCash }
    }

    /// Money already coming in (received benefits + items marked submitted/approved), per year.
    var securedPerYear: Double {
        opportunities
            .filter { $0.alreadyReceived || status($0) == .submitted || status($0) == .approved }
            .reduce(0) { $0 + $1.valuePerYear + $1.valueOnce }
    }

    var openPerYear: Double {
        openOpportunities.reduce(0) { $0 + $1.valuePerYear }
    }

    var openOnce: Double {
        openOpportunities.reduce(0) { $0 + $1.valueOnce }
    }

    func status(_ o: Opportunity) -> CaseStatus {
        if o.alreadyReceived { return .approved }
        return statuses[o.id] ?? .found
    }

    func setStatus(_ o: Opportunity, _ s: CaseStatus) {
        statuses[o.id] = s
    }

    func addDeadline(_ title: String, _ date: String) {
        guard !deadlines.contains(where: { $0.title == title && $0.date == date }) else { return }
        deadlines.insert(Deadline(title: title, date: date, urgent: true), at: 0)
    }

    func reset() {
        profile = Profile()
        statuses = [:]
        profileStep = 0
        letters = []
        stage = .language
    }

    // MARK: Persistence (pause and resume)

    private struct Saved: Codable {
        var stage: Stage
        var language: Lang
        var profile: Profile
        var statuses: [String: CaseStatus]
        var profileStep: Int
    }

    private static let key = "appState.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(Saved.self, from: data) {
            stage = saved.stage
            language = saved.language
            profile = saved.profile
            statuses = saved.statuses
            profileStep = saved.profileStep
        } else {
            stage = .language
            language = .en
            profile = Profile()
            statuses = [:]
            profileStep = 0
        }
    }

    private func save() {
        let saved = Saved(stage: stage, language: language, profile: profile, statuses: statuses, profileStep: profileStep)
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
