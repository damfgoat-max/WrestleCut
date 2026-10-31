import SwiftUI
import SwiftData

struct NutritionView: View {
    var profile: UserProfile
    @State private var variant = 0
    @State private var swapped: [String: MealSuggestion] = [:]
    private var calories: Int { CutCalculator.calorieTarget(profile: profile) }
    private var macros: (protein:Double, carbs:Double, fat:Double) { CutCalculator.macros(profile: profile, calories: calories) }
    private var plan: [MealSuggestion] { FoodDatabase.mealPlan(profile: profile, variant: variant) }
    var body: some View {
        NavigationStack { ScrollView { VStack(spacing:16){
            SectionHeader(title:"Today's Fuel", subtitle:"Avoiding your \(profile.dislikedFoodIDs.count) disliked/allergy foods")
            VStack(spacing:10){ HStack{ VStack(alignment:.leading){ Text("\(calories)").font(.title.weight(.black)); Text("CALORIES TODAY").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)}; Spacer(); Button("Shuffle Plan"){ variant += 1 }.buttonStyle(.bordered).tint(WCTheme.gold) }
                MacroBar(label:"Protein", value: macros.protein, target: macros.protein, color: WCTheme.red)
                MacroBar(label:"Carbs", value: macros.carbs, target: macros.carbs, color: WCTheme.gold)
                MacroBar(label:"Fat", value: macros.fat, target: macros.fat, color: .cyan)
                Text("Why: BMR (Mifflin-St Jeor) × activity − modest deficit. Protein 2.2 g/kg goal weight protects muscle.").font(.caption).foregroundStyle(WCTheme.textTertiary)
            }.wcCard()
            ForEach(plan){ meal in MealCard(meal: meal, zip: profile.zipCode) }
            DisclaimerView()
        }.padding() }.wcBackground().navigationTitle("Nutrition") }
    }
}
struct MealCard: View {
    var meal: MealSuggestion; var zip: String; @State private var expanded = false
    var body: some View {
        VStack(alignment:.leading, spacing:10){
            HStack{ Text(meal.mealType.uppercased()).font(.caption.weight(.black)).foregroundStyle(WCTheme.gold); Spacer(); Text("\(meal.prepMinutes) min").font(.caption).foregroundStyle(WCTheme.textSecondary); Text("\(meal.calories) cal").fontWeight(.bold) }
            Text(meal.title).font(.title3.weight(.black))
            Text("\(Int(meal.proteinG))g P • \(Int(meal.carbsG))g C • \(Int(meal.fatG))g F").font(.subheadline).foregroundStyle(WCTheme.textSecondary)
            ForEach(meal.items){ item in VStack(alignment:.leading, spacing:4){
                Text(item.displayName).fontWeight(.semibold); Text("\(item.serving) • \(item.calories) cal").font(.caption).foregroundStyle(WCTheme.textSecondary)
                if item.isBranded { ForEach(StoreService.nearbyStores(zip: zip, for: item).prefix(3)){ store in HStack{ Image(systemName:"storefront").foregroundStyle(WCTheme.gold); Text("\(store.name) — \(String(format:"%.1f",store.distanceMiles)) mi").font(.caption); Spacer(); Text(store.carriesNote).font(.caption2).foregroundStyle(WCTheme.textTertiary).lineLimit(1) } } }
            } }
            Button(expanded ? "Hide Instructions" : "Prep & Ingredients"){ expanded.toggle() }.font(.subheadline.weight(.bold)).foregroundStyle(WCTheme.redBright)
            if expanded { Text("Ingredients: \(meal.ingredients.joined(separator:", "))").font(.subheadline); Text(meal.instructions).font(.subheadline).foregroundStyle(WCTheme.textSecondary) }
        }.wcCard()
    }
}
