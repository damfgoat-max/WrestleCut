import Foundation
import SwiftData

@Model final class WeightEntry {
    var date: Date; var weightLbs: Double; var note: String
    init(date: Date = .now, weightLbs: Double, note: String = "") { self.date = date; self.weightLbs = weightLbs; self.note = note }
}
@Model final class WaterEntry {
    var date: Date; var milliliters: Int
    init(date: Date = .now, milliliters: Int) { self.date = date; self.milliliters = milliliters }
}
@Model final class FoodLogEntry {
    var date: Date; var foodName: String; var brand: String; var calories: Int; var proteinG: Double; var carbsG: Double; var fatG: Double; var sodiumMg: Double = 0; var mealType: String
    init(date: Date = .now, foodName: String, brand: String = "", calories: Int, proteinG: Double, carbsG: Double, fatG: Double, sodiumMg: Double = 0, mealType: String = "Snack") {
        self.date = date; self.foodName = foodName; self.brand = brand; self.calories = calories; self.proteinG = proteinG; self.carbsG = carbsG; self.fatG = fatG; self.sodiumMg = sodiumMg; self.mealType = mealType
    }
}
@Model final class WorkoutEntry {
    var date: Date; var kind: String; var minutes: Int; var caloriesBurned: Int
    init(date: Date = .now, kind: String, minutes: Int, caloriesBurned: Int) { self.date = date; self.kind = kind; self.minutes = minutes; self.caloriesBurned = caloriesBurned }
}
