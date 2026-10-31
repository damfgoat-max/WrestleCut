import Foundation

struct FoodItem: Identifiable, Hashable, Codable {
    var id: String; var name: String; var brand: String; var category: String
    var calories: Int; var proteinG: Double; var carbsG: Double; var fatG: Double; var sodiumMg: Double = 0
    var serving: String; var barcode: String; var priceEstimate: Double; var isBranded: Bool { !brand.isEmpty }
    var displayName: String { brand.isEmpty ? name : "\(brand) \(name)" }
}

struct MealSuggestion: Identifiable {
    var id = UUID(); var mealType: String; var title: String; var items: [FoodItem]
    var prepMinutes: Int; var instructions: String; var ingredients: [String]
    var calories: Int { items.reduce(0){$0+$1.calories} }
    var sodiumMg: Double { items.reduce(0){$0+$1.sodiumMg} }
    var proteinG: Double { items.reduce(0){$0+$1.proteinG} }
    var carbsG: Double { items.reduce(0){$0+$1.carbsG} }
    var fatG: Double { items.reduce(0){$0+$1.fatG} }
}

struct StoreInfo: Identifiable, Hashable {
    var id: String { name + address }
    var name: String; var distanceMiles: Double; var priceLevel: String; var address: String; var carriesNote: String
}

struct DislikeOption: Identifiable, Hashable {
    var id: String; var name: String; var category: String
}
