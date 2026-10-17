import Foundation
import UIKit

/// Talks to our small backend (server/server.py), which calls Claude.
/// The API key never lives in the app. If the backend fails, we fall back to cached demo answers.
struct AIResult<T> {
    let value: T
    let fromCache: Bool
}

enum AIService {
    static let defaultURL: String = {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8787"
        #else
        let fromBuild = Bundle.main.object(forInfoDictionaryKey: "BackendURL") as? String ?? ""
        return fromBuild.isEmpty ? "http://127.0.0.1:8787" : fromBuild
        #endif
    }()

    static var baseURL: String {
        let saved = UserDefaults.standard.string(forKey: "backendURL") ?? ""
        return saved.isEmpty ? defaultURL : saved
    }

    static var demoMode: Bool {
        UserDefaults.standard.bool(forKey: "demoMode")
    }

    static func post<T: Decodable>(_ path: String, _ body: [String: Any], as: T.Type, timeout: TimeInterval = 90) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func withFallback<T>(_ fallback: T, _ call: () async throws -> T) async -> AIResult<T> {
        if demoMode { return AIResult(value: fallback, fromCache: true) }
        do {
            return AIResult(value: try await call(), fromCache: false)
        } catch {
            print("AI call failed, using demo answer: \(error)")
            return AIResult(value: fallback, fromCache: true)
        }
    }

    static func imagePayload(_ data: Data?) -> [String: Any] {
        guard let data, let image = UIImage(data: data) else { return [:] }
        let maxSide: CGFloat = 1600
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let jpeg = resized.jpegData(compressionQuality: 0.8) else { return [:] }
        return ["imageBase64": jpeg.base64EncodedString(), "mediaType": "image/jpeg"]
    }

    static func explainLetter(text: String?, image: Data?, language: Lang) async -> AIResult<LetterExplanation> {
        var body = imagePayload(image)
        body["text"] = text ?? ""
        body["language"] = language.rawValue
        return await withFallback(SampleData.letterExplanation) {
            try await post("/api/explain-letter", body, as: LetterExplanation.self)
        }
    }

    static func draftGermanLetter(intent: String, context: String, profile: Profile, lockedTokens: [String], language: Lang) async -> AIResult<GermanDraft> {
        let body: [String: Any] = [
            "intent": intent,
            "context": context,
            "language": language.rawValue,
            "lockedTokens": lockedTokens,
            "profile": [
                "parentName": profile.parentName.isEmpty ? "Priya Sharma" : profile.parentName + " Sharma",
                "parentAddress": "Musterstraße 12, 10437 Berlin",
                "childName": profile.childName.isEmpty ? "Arjun Sharma" : profile.childName + " Sharma",
                "pflegegrad": profile.pflegegrad ?? 0,
                "gdb": profile.gdb ?? 0,
            ],
        ]
        return await withFallback(SampleData.germanDraft) {
            try await post("/api/draft-letter", body, as: GermanDraft.self)
        }
    }

    static func explainOpportunity(_ o: Opportunity, language: Lang) async -> AIResult<OpportunityExplanation> {
        await withFallback(SampleData.opportunityExplanation(o)) {
            try await post("/api/explain-opportunity", ["rule": o.ruleData, "language": language.rawValue], as: OpportunityExplanation.self)
        }
    }

    static func answerOnCard(_ question: String, _ o: Opportunity, language: Lang) async -> AIResult<CardAnswer> {
        await withFallback(SampleData.cardAnswer(question: question, o)) {
            try await post("/api/answer-on-card", ["rule": o.ruleData, "question": question, "language": language.rawValue], as: CardAnswer.self)
        }
    }

    private struct UITranslation: Decodable { let translations: [String: String] }

    static func translateUI(keys: [String], language: Lang) async throws -> [String: String] {
        let result = try await post("/api/translate-ui", ["keys": keys, "language": language.rawValue], as: UITranslation.self, timeout: 300)
        return result.translations
    }

    static func extractDocument(text: String?, image: Data?, language: Lang) async -> AIResult<ExtractedDocument> {
        var body = imagePayload(image)
        body["text"] = text ?? ""
        body["language"] = language.rawValue
        return await withFallback(SampleData.extractedDecision) {
            try await post("/api/extract-document", body, as: ExtractedDocument.self)
        }
    }
}
