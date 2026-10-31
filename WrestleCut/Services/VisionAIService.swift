import Foundation
import UIKit
import Security

/// Cloud-vision for the food scanner: Groq's Llama 4 vision model.
/// Groq's API has a genuinely free tier — the user pastes their own free key
/// (console.groq.com, no credit card) in More → AI Vision, and it lives only in
/// the iOS Keychain. Without a key, the free on-device + Open Food Facts
/// pipeline is used instead.
enum VisionAIProvider: String, CaseIterable {
    case groq = "groq"
    var displayName: String { "Groq Llama Vision (FREE)" }
    var model: String { "meta-llama/llama-4-scout-17b-16e-instruct" }
}

struct AIFoodResult {
    var name: String
    var brand: String
    var serving: String
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var sodiumMg: Double
    var ingredients: String
}

enum KeychainStore {
    static func set(_ value: String, account: String) {
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.wrestlecut.aivision", kSecAttrAccount as String: account]
        SecItemDelete(base as CFDictionary)
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return }
        var attrs = base
        attrs[kSecValueData as String] = data
        SecItemAdd(attrs as CFDictionary, nil)
    }
    static func get(_ account: String) -> String {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.wrestlecut.aivision", kSecAttrAccount as String: account, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

enum VisionAIService {
    static var provider: VisionAIProvider { .groq }
    static var apiKey: String { KeychainStore.get(VisionAIProvider.groq.rawValue) }
    static var isConfigured: Bool { !apiKey.isEmpty }

    private static let prompt = """
        You are an expert nutritionist. Look at this food photo and identify the actual food or drink. \
        If a brand or label is visible, use the exact brand and product name. Estimate one realistic serving as shown. \
        Reply with ONLY a JSON object, no other text: \
        {"name":"...","brand":"...","serving":"...","calories":0,"protein":0,"carbs":0,"fat":0,"sodiumMg":0,"ingredients":"..."}
        """

    static func analyze(image: UIImage) async -> AIFoodResult? {
        guard isConfigured, let base64 = jpegBase64(image) else { return nil }
        do {
            return try await analyzeGroq(base64: base64)
        } catch { return nil }
    }

    private static func jpegBase64(_ image: UIImage) -> String? {
        let maxSide: CGFloat = 1024
        let size = image.size
        let scale = min(1, maxSide / max(size.width, size.height))
        var resized = image
        if scale < 1 {
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            resized = UIGraphicsImageRenderer(size: newSize).image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        }
        return resized.jpegData(compressionQuality: 0.7)?.base64EncodedString()
    }

    /// Groq chat-vision call (OpenAI-compatible endpoint), Llama 4 Scout vision model.
    private static func analyzeGroq(base64: String) async throws -> AIFoodResult? {
        var req = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 45
        let body: [String: Any] = [
            "model": VisionAIProvider.groq.model,
            "max_tokens": 700,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)"]]
                ]
            ]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else { return nil }
        return parse(content)
    }

    private static func parse(_ text: String) -> AIFoodResult? {
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") else { return nil }
        let slice = String(text[start...end])
        guard let data = slice.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String, !name.isEmpty else { return nil }
        func num(_ key: String) -> Double {
            if let d = json[key] as? Double { return d }
            if let i = json[key] as? Int { return Double(i) }
            if let s = json[key] as? String { return Double(s) ?? 0 }
            return 0
        }
        return AIFoodResult(
            name: name,
            brand: (json["brand"] as? String) ?? "",
            serving: (json["serving"] as? String) ?? "1 serving",
            calories: Int(num("calories")),
            proteinG: num("protein"), carbsG: num("carbs"), fatG: num("fat"),
            sodiumMg: num("sodiumMg"),
            ingredients: (json["ingredients"] as? String) ?? ""
        )
    }
}
