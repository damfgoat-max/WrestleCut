import Foundation

/// A real product found in Open Food Facts — the free, open, worldwide food database
/// (the same data behind most barcode nutrition apps). Per-serving values are preferred;
/// otherwise per-100g values are scaled to the product's serving size.
struct OFFProduct {
    var name: String
    var brand: String
    var ingredients: String
    var serving: String
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var sodiumMg: Double
    var displayName: String { brand.isEmpty ? name : "\(name) (\(brand))" }
}

enum OpenFoodFactsService {
    /// Looks up a barcode in Open Food Facts. Needs internet; returns nil when the product
    /// isn't in the database or the device is offline — the app then offers manual entry.
    static func lookup(barcode: String) async -> OFFProduct? {
        let code = barcode.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty, let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(code).json") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("WrestleCut/1.0 (wrestling weight-cut tracker)", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 12
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            return parse(data)
        } catch { return nil }
    }

    /// Searches Open Food Facts by product/brand name — used when a photo's label text is read,
    /// and for live online search in the Food tab. Returns best matches first.
    static func search(query: String) async -> [OFFProduct] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 3, let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)&search_simple=1&action=process&json=1&page_size=8&fields=product_name,product_name_en,brands,ingredients_text,ingredients_text_en,serving_size,serving_quantity,product_quantity,nutriments") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("WrestleCut/1.0 (wrestling weight-cut tracker)", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 12
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let products = json["products"] as? [[String: Any]] else { return [] }
            return products.compactMap { parseProduct($0) }.filter { $0.calories > 0 || $0.proteinG > 0 }
        } catch { return [] }
    }

    static func parse(_ data: Data) -> OFFProduct? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int, status == 1,
              let product = json["product"] as? [String: Any] else { return nil }
        return parseProduct(product)
    }

    static func parseProduct(_ product: [String: Any]) -> OFFProduct? {
        let name = (product["product_name"] as? String) ?? (product["product_name_en"] as? String) ?? ""
        guard !name.isEmpty else { return nil }
        let brandsRaw = (product["brands"] as? String) ?? ""
        let brand = brandsRaw.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
        let ingredients = (product["ingredients_text"] as? String) ?? (product["ingredients_text_en"] as? String) ?? ""
        let servingText = (product["serving_size"] as? String) ?? ""
        let n = (product["nutriments"] as? [String: Any]) ?? [:]

        func num(_ dict: [String: Any], _ key: String) -> Double? {
            if let v = dict[key] as? NSNumber { return v.doubleValue }
            if let s = dict[key] as? String { return Double(s) }
            return nil
        }
        // Per-serving first; else scale per-100g by the serving weight in grams.
        let servingGrams = num(product, "serving_quantity") ?? num(product, "product_quantity")
        func value(_ base: String) -> Double {
            if let v = num(n, "\(base)_serving") { return v }
            if let per100 = num(n, "\(base)_100g") {
                if let g = servingGrams { return per100 * g / 100 }
                return per100
            }
            return 0
        }
        let calories = value("energy-kcal")
        let protein = value("proteins")
        let carbs = value("carbohydrates")
        let fat = value("fat")
        // Sodium: nutriments store grams. Prefer the direct sodium field; else derive from salt (sodium ≈ salt × 0.4).
        var sodiumMg = value("sodium") * 1000
        if sodiumMg == 0 { sodiumMg = value("salt") * 400 }
        return OFFProduct(
            name: name, brand: brand, ingredients: ingredients,
            serving: servingText.isEmpty ? "1 serving" : servingText,
            calories: Int(calories.rounded()), proteinG: protein, carbsG: carbs, fatG: fat, sodiumMg: sodiumMg
        )
    }
}
