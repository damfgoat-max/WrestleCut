import Foundation
#if canImport(Vision) && canImport(UIKit)
import Vision
import UIKit
#endif

/// Parses free-typed water amounts a tired athlete might type: "420", "420ml", "16oz", "16 fl oz", "1.2L", "1.2 liters", "2 cups".
/// Plain numbers are treated as millilitres. Returns nil when there's no usable number.
enum WaterAmountParser {
    static func milliliters(from raw: String) -> Int? {
        let s = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard !s.isEmpty else { return nil }
        // Extract the first number (integer or decimal).
        var numStr = ""; var seenDot = false
        for ch in s {
            if ch.isNumber { numStr.append(ch) }
            else if ch == "." && !seenDot && !numStr.isEmpty { numStr.append(ch); seenDot = true }
            else if !numStr.isEmpty { break }
        }
        guard let value = Double(numStr), value > 0 else { return nil }
        let mlPerUnit: Double
        if s.contains("ml") || s.contains("millilit") { mlPerUnit = 1 }
        else if s.contains("oz") { mlPerUnit = 29.5735 }
        else if s.contains("liter") || s.contains("litre") || s.hasSuffix("l") || s.contains(" l") { mlPerUnit = 1000 }
        else if s.contains("cup") { mlPerUnit = 240 }
        else if s.contains("gal") { mlPerUnit = 3785 }
        else { mlPerUnit = 1 } // a plain number = ml
        return Int((value * mlPerUnit).rounded())
    }
    /// Human preview for the confirm label, e.g. "16oz = 473 ml".
    static func preview(from raw: String) -> String? {
        guard let ml = milliliters(from: raw) else { return nil }
        return "= \(ml) ml"
    }
}

/// Transparent sodium guidance for wrestlers. Sodium is an electrolyte you LOSE in sweat —
/// this is a guide to watch, not a medical rule, and the final-days taper should be coach-guided.
enum SodiumGuide {
    static func dailyGuideMg(daysUntilWeighIn: Int) -> Int {
        if daysUntilWeighIn <= 1 { return 1500 }
        if daysUntilWeighIn <= 3 { return 2000 }
        return 2600
    }
    static func effectiveLimitMg(profile: UserProfile) -> Int {
        profile.sodiumLimitOverrideMg > 0 ? profile.sodiumLimitOverrideMg : dailyGuideMg(daysUntilWeighIn: profile.daysUntilWeighIn)
    }
    static func note(daysUntilWeighIn: Int) -> String {
        if daysUntilWeighIn <= 1 { return "Weigh-in window: lower sodium helps release water — but you still need some, especially if you're sweating. Coach-guided only." }
        if daysUntilWeighIn <= 3 { return "Taper zone: start easing sodium down with your water load. Don't crash it to zero." }
        return "Normal training guide ≈2,600 mg/day. Heavy sweat sessions replace sodium — salty food after hard practice is normal and healthy."
    }
}

#if canImport(Vision) && canImport(UIKit)
/// On-device food photo detection using Apple's Vision image classification.
/// It looks at the photo on the phone (nothing is uploaded), returns what it thinks the food is,
/// and the app matches those labels against the wrestler food database. The athlete always confirms before logging.
enum FoodPhotoService {
    struct Detection: Identifiable { var id = UUID(); var label: String; var confidence: Float }

    static func detect(in image: UIImage, completion: @escaping ([Detection]) -> Void) {
        guard let cg = image.cgImage else { completion([]); return }
        let classify = VNClassifyImageRequest()
        let ocr = VNRecognizeTextRequest()
        ocr.recognitionLevel = .accurate
        ocr.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([classify, ocr])
            let results = (classify.results ?? []).filter { $0.confidence > 0.03 }.prefix(20).map { Detection(label: $0.identifier, confidence: $0.confidence) }
            // Read any text on the packaging and surface recognized brands first.
            let text = (ocr.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ").lowercased()
            var brandHits: [Detection] = []
            for word in brandWords where text.contains(word) { brandHits.append(Detection(label: word, confidence: 0.99)) }
            if !text.isEmpty { brandHits.append(Detection(label: "label text: \(text.prefix(60))", confidence: 0.5)) }
            DispatchQueue.main.async { completion(brandHits + results) }
        }
    }

    /// Keyword map from Vision labels to our database foods.
    private static let keywordMap: [(String, String)] = [
        ("banana", "f14"), ("chicken", "f1"), ("turkey", "f21"), ("rice", "f2"), ("egg", "f5"), ("omelet", "f5"), ("omelette", "f5"),
        ("oat", "f20"), ("cereal", "f20"), ("salmon", "f8"), ("fish", "f8"), ("tuna", "f9"), ("yogurt", "f4"), ("yoghurt", "f4"),
        ("milk", "f22"), ("peanut", "f16"), ("berry", "f23"), ("berries", "f23"), ("strawberr", "f23"), ("blueberr", "f23"),
        ("potato", "f10"), ("sweet potato", "f10"), ("fries", "f10"), ("bar", "f18"), ("shake", "f3"), ("protein", "f3"),
        ("smoothie", "f3"), ("bread", "f11"), ("toast", "f11"), ("bagel", "f11"), ("cake", "f11"), ("muffin", "f11"),
        ("rotisserie", "f19"), ("roast chicken", "f19"), ("sandwich", "f21"), ("wrap", "f21"), ("deli", "f21"),
        ("oatmeal", "f20"), ("granola", "f18"), ("electrolyte", "f24"), ("sports drink", "f24"), ("gatorade", "f24"),
        ("quinoa", "f2"), ("pasta", "f2"), ("noodle", "f2"), ("steak", "f1"), ("beef", "f1"), ("burger", "f1"),
        ("fairlife", "f3"), ("core power", "f3"), ("premier protein", "f3"), ("muscle milk", "f3"), ("gatorade zero", "f24"),
        ("rice", "g1"), ("broccoli", "g2"), ("green bean", "g3"), ("salad", "g4"), ("lettuce", "g4"),
        ("chicken", "g5"), ("beef", "g6"), ("steak", "g7"), ("pork", "g8"), ("cod", "g9"), ("white fish", "g9"),
        ("shrimp", "g10"), ("pasta", "g11"), ("spaghetti", "g11"), ("mashed potato", "g12"), ("fries", "g13"),
        ("pizza", "g14"), ("burger", "g15"), ("avocado", "g16"), ("apple", "g17"), ("orange juice", "g18"),
        ("starkist", "f9"), ("star kist", "f9"), ("chobani", "f4"), ("fage", "f4"), ("tyson", "f1")
    ]
    /// Brand words we can read off packaging with text recognition — a huge accuracy boost for branded items.
    private static let brandWords = ["fairlife", "core power", "premier protein", "muscle milk", "gatorade zero", "quaker", "kirkland", "great value", "starkist", "chobani", "fage", "tyson"]
    static func matchedFoods(for detections: [Detection], avoiding disliked: [String]) -> [FoodItem] {
        var seen = Set<String>(); var out: [FoodItem] = []
        for det in detections {
            let label = det.label.lowercased()
            for (keyword, foodID) in keywordMap where label.contains(keyword) {
                if seen.insert(foodID).inserted, let food = FoodDatabase.allFoods.first(where: { $0.id == foodID }), !disliked.contains(foodID) {
                    out.append(food)
                }
            }
        }
        return out
    }
}
#endif
