import Foundation
import UIKit
import Security

/// Optional cloud-vision upgrade for the food scanner: GPT-4o or Claude-level identification.
/// The app stays 100% free — this only activates when the USER pastes their own API key in
/// More → AI Vision (Pro). The key lives in the iOS Keychain, never in app files or logs.
/// Without a key, the free on-device + Open Food Facts pipeline is used instead.
enum VisionAIProvider: String, CaseIterable {
    case gemini = "gemini"
    case groq = "groq"
    case openAI = "openai"
    case claude = "claude"
    var displayName: String {
        switch self {
        case .gemini: return "Google Gemini (FREE)"
        case .groq: return "Groq Llama Vision (FREE)"
        case .openAI: return "OpenAI GPT-4o"
        case .claude: return "Claude (Anthropic)"
        }
    }
    var model: String {
        switch self {
        case .gemini: return "gemini-2.5-flash"
        case .groq: return "meta-llama/llama-4-scout-17b-16e-instruct"
        case .openAI: return "gpt-4o"
        case .claude: return "claude-sonnet-4-5"
        }
    }
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
    static var provider: VisionAIProvider {
        VisionAIProvider(rawValue: UserDefaults.standard.string(forKey: "wcAIProvider") ?? "gemini") ?? .gemini
    }
    static var apiKey: String { KeychainStore.get(provider.rawValue) }
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
            switch provider {
            case .gemini: return try await analyzeGemini(base64: base64)
            case .groq: return try await analyzeOpenAICompatible(base64: base64, endpoint: "https://api.groq.com/openai/v1/chat/completions", model: VisionAIProvider.groq.model, jsonMode: false)
            case .openAI: return try await analyzeOpenAICompatible(base64: base64, endpoint: "https://api.openai.com/v1/chat/completions", model: VisionAIProvider.openAI.model, jsonMode: true)
            case .claude: return try await analyzeClaude(base64: base64)
            }
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

    /// Google Gemini — its API has a genuinely FREE tier (key from Google AI Studio, no card),
    /// so this is the zero-cost cloud-vision path. Same strict-JSON nutrition prompt.
    private static func analyzeGemini(base64: String) async throws -> AIFoodResult? {
        var req = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(VisionAIProvider.gemini.model):generateContent")!)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 45
        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": base64]]
                ]
            ]],
            "generationConfig": ["responseMimeType": "application/json", "maxOutputTokens": 700]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first(where: { $0["text"] != nil })?["text"] as? String else { return nil }
        return parse(text)
    }

    /// Shared OpenAI-compatible chat-vision call — used by OpenAI itself and by Groq (free tier).
    private static func analyzeOpenAICompatible(base64: String, endpoint: String, model: String, jsonMode: Bool) async throws -> AIFoodResult? {
        var req = URLRequest(url: URL(string: endpoint)!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 45
        var body: [String: Any] = [
            "model": model,
            "max_tokens": 700,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)"]]
                ]
            ]]
        ]
        if jsonMode { body["response_format"] = ["type": "json_object"] }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else { return nil }
        return parse(content)
    }

    private static func analyzeClaude(base64: String) async throws -> AIFoodResult? {
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 45
        let body: [String: Any] = [
            "model": VisionAIProvider.claude.model,
            "max_tokens": 700,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image", "source": ["type": "base64", "media_type": "image/jpeg", "data": base64]],
                    ["type": "text", "text": prompt]
                ]
            ]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String else { return nil }
        return parse(text)
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
