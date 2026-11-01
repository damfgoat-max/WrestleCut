import Foundation

/// USDA FoodData Central — the US government's food database. Used as the second
/// lookup source for photo identification (after Open Food Facts): when a photo or
/// label names a food, its real USDA nutrition beats any model's guess. Searches run
/// with the shared DEMO_KEY; failures are silent and simply yield no results.
enum USDAFoodDataService {
    static func search(query: String) async -> [OFFProduct] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 3, let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(encoded)&pageSize=6&dataType=Foundation,Branded,SR%20Legacy&api_key=DEMO_KEY") else { return [] }
        var req = URLRequest(url: url)
        req.timeoutInterval = 12
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let foods = json["foods"] as? [[String: Any]] else { return [] }
            return foods.compactMap { parse($0) }.filter { $0.calories > 0 || $0.proteinG > 0 }
        } catch { return [] }
    }

    private static func parse(_ food: [String: Any]) -> OFFProduct? {
        guard let name = food["description"] as? String, !name.isEmpty else { return nil }
        let brand = (food["brandOwner"] as? String) ?? (food["brandName"] as? String) ?? ""
        var nutrients: [String: Double] = [:]
        for n in (food["foodNutrients"] as? [[String: Any]]) ?? [] {
            if let key = n["nutrientName"] as? String, let v = n["value"] as? NSNumber { nutrients[key] = v.doubleValue }
        }
        // FDC search returns per-100g values; scale branded foods to their label serving.
        var factor = 1.0
        var serving = "100 g"
        if let grams = (food["servingSize"] as? NSNumber)?.doubleValue, grams > 0 {
            factor = grams / 100
            let unit = (food["servingSizeUnit"] as? String) ?? "g"
            let house = (food["householdServingFullText"] as? String) ?? ""
            serving = house.isEmpty ? "\(Int(grams)) \(unit)" : house
        }
        return OFFProduct(
            name: name.capitalized, brand: brand, ingredients: "",
            serving: serving,
            calories: Int(((nutrients["Energy"] ?? 0) * factor).rounded()),
            proteinG: (nutrients["Protein"] ?? 0) * factor,
            carbsG: (nutrients["Carbohydrate, by difference"] ?? 0) * factor,
            fatG: (nutrients["Total lipid (fat)"] ?? 0) * factor,
            sodiumMg: (nutrients["Sodium, Na"] ?? 0) * factor
        )
    }
}
