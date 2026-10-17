import Foundation
import Observation

/// In-app UI translation. Keys are the English strings.
/// German and Russian ship with the app; other languages are translated once by Claude and cached on the phone.
@Observable
final class L10n {
    static let shared = L10n()

    var lang: Lang = .en
    var translating = false
    var failed = false
    private var cached: [Lang: [String: String]] = [:]

    private init() {
        for lang in Lang.allCases where Self.builtIn[lang] == nil {
            if let data = UserDefaults.standard.data(forKey: Self.cacheKey(lang)),
               let table = try? JSONDecoder().decode([String: String].self, from: data) {
                cached[lang] = table
            }
        }
    }

    static let builtIn: [Lang: [String: String]] = [.de: Strings.de, .ru: Strings.ru]

    func table(for lang: Lang) -> [String: String]? {
        Self.builtIn[lang] ?? cached[lang]
    }

    func text(_ key: String) -> String {
        guard lang != .en else { return key }
        return table(for: lang)?[key] ?? key
    }

    /// Asks Claude (via the backend) to translate the whole UI table, once per language.
    func ensure(_ lang: Lang) async {
        guard lang != .en, table(for: lang) == nil, !translating else { return }
        translating = true
        failed = false
        defer { translating = false }
        do {
            let result = try await AIService.translateUI(keys: Strings.allKeys, language: lang)
            cached[lang] = result
            if let data = try? JSONEncoder().encode(result) {
                UserDefaults.standard.set(data, forKey: Self.cacheKey(lang))
            }
        } catch {
            print("UI translation failed: \(error)")
            failed = true
        }
    }

    private static func cacheKey(_ lang: Lang) -> String { "l10n.v1.\(lang.rawValue)" }
}

/// Translate a UI string. `%@` placeholders are filled in order with `args`.
func L(_ key: String, _ args: CustomStringConvertible...) -> String {
    var result = L10n.shared.text(key)
    for arg in args {
        guard let range = result.range(of: "%@") else { break }
        result.replaceSubrange(range, with: arg.description)
    }
    return result
}
