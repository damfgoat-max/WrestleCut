import SwiftUI
import SwiftData

struct NutritionView: View {
    var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\FoodLogEntry.date, order: .forward)]) private var allLogs: [FoodLogEntry]
    @State private var variant = 0
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)

    private let mealOrder = ["Breakfast", "Lunch", "Dinner", "Snack"]
    private var calories: Int { CutCalculator.calorieTarget(profile: profile) }
    private var macros: (protein: Double, carbs: Double, fat: Double) { CutCalculator.macros(profile: profile, calories: calories) }
    private var plan: [MealSuggestion] { FoodDatabase.mealPlan(profile: profile, variant: variant) }
    private var weekdayName: String { selectedDate.formatted(.dateTime.weekday(.wide)) }
    private var dayLogs: [FoodLogEntry] { allLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) } }
    private func logs(for meal: String) -> [FoodLogEntry] { dayLogs.filter { $0.mealType == meal } }

    var body: some View {
        NavigationStack {
            ScrollView { VStack(spacing: 18) {
                dayNavigator
                timeline
                plannerSection
                DisclaimerView()
            }.padding() }
            .wcBackground().navigationTitle("Meals")
        }
    }

    private var dayNavigator: some View {
        HStack(spacing: 10) {
            Button { shiftDay(-1) } label: { Image(systemName: "chevron.left").font(.title3.weight(.black)).frame(width: 52, height: 52).background(WCTheme.surface2).clipShape(Circle()) }
            VStack(spacing: 2) {
                Text(weekdayName).font(.title2.weight(.black))
                Text(selectedDate, format: .dateTime.month(.wide).day().year()).font(.subheadline).foregroundStyle(WCTheme.textSecondary)
            }.frame(maxWidth: .infinity)
            if !Calendar.current.isDateInToday(selectedDate) {
                Button("Today") { selectedDate = Calendar.current.startOfDay(for: .now) }.font(.subheadline.weight(.black)).buttonStyle(.bordered).tint(WCTheme.gold)
            }
            Button { shiftDay(1) } label: { Image(systemName: "chevron.right").font(.title3.weight(.black)).frame(width: 52, height: 52).background(WCTheme.surface2).clipShape(Circle()) }
        }.foregroundStyle(.white).wcCard()
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "\(weekdayName)'s Timeline", subtitle: "Everything you ate, by meal — clean and simple")
            ForEach(Array(mealOrder.enumerated()), id: \.element) { index, meal in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        Circle().fill(index == 0 ? WCTheme.red : WCTheme.gold).frame(width: 14, height: 14).padding(.top, 6)
                        if index < mealOrder.count - 1 { Rectangle().fill(Color.white.opacity(0.14)).frame(width: 2).frame(maxHeight: .infinity) }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(weekdayName) - \(meal == "Snack" ? "Snacks" : meal)").font(.headline.weight(.black))
                            Spacer()
                            let items = logs(for: meal)
                            if !items.isEmpty { Text("\(items.reduce(0) { $0 + $1.calories }) cal").font(.subheadline.weight(.black)).foregroundStyle(WCTheme.gold) }
                        }
                        let items = logs(for: meal)
                        if items.isEmpty {
                            Text(emptyExample(for: meal)).font(.subheadline).foregroundStyle(WCTheme.textTertiary)
                        } else {
                            ForEach(items) { log in
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(log.foodName).font(.subheadline.weight(.semibold))
                                        Text("P \(Int(log.proteinG))g • C \(Int(log.carbsG))g • F \(Int(log.fatG))g • Na \(Int(log.sodiumMg)) mg").font(.caption).foregroundStyle(WCTheme.textSecondary)
                                    }
                                    Spacer()
                                    Text("\(log.calories) cal").font(.subheadline.weight(.bold)).foregroundStyle(WCTheme.textSecondary)
                                }
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 18)
                }
            }
            Text("Log food from the Food tab (scan, photo, search, or manual) — pick the meal there and it lands here on this day's timeline.").font(.caption).foregroundStyle(WCTheme.textTertiary)
        }.wcCard()
    }

    private func emptyExample(for meal: String) -> String {
        switch meal {
        case "Breakfast": return "Nothing yet — e.g. Monday - Breakfast: eggs + oats"
        case "Lunch": return "Nothing yet — e.g. Monday - Lunch: 4oz chicken breast, 100g rice"
        case "Dinner": return "Nothing yet — e.g. Monday - Dinner: salmon + sweet potato"
        default: return "Nothing yet — e.g. Monday - Snack: protein shake"
        }
    }

    private var plannerSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Today's Plan", subtitle: "Suggested meals that avoid your \(profile.dislikedFoodIDs.count) disliked/allergy foods")
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading) { Text("\(calories)").font(.title.weight(.black)); Text("CALORIE GOAL").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary) }
                    Spacer()
                    Button("Shuffle Plan") { variant += 1 }.buttonStyle(.bordered).tint(WCTheme.gold).frame(minHeight: 44)
                }
                MacroBar(label: "Protein", value: macros.protein, target: macros.protein, color: WCTheme.red)
                MacroBar(label: "Carbs", value: macros.carbs, target: macros.carbs, color: WCTheme.gold)
                MacroBar(label: "Fat", value: macros.fat, target: macros.fat, color: .cyan)
                Text("Why: BMR (Mifflin-St Jeor) × activity − modest deficit. Protein 2.2 g/kg goal weight protects muscle. Sodium is tracked in the Food tab against your daily guide.").font(.caption).foregroundStyle(WCTheme.textTertiary)
            }.wcCard()
            ForEach(plan) { meal in MealCard(meal: meal, zip: profile.zipCode) { addPlanToDay(meal) } }
        }
    }

    private func shiftDay(_ days: Int) { selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate }

    private func addPlanToDay(_ meal: MealSuggestion) {
        let cal = Calendar.current
        let hour = meal.mealType == "Breakfast" ? 7 : meal.mealType == "Lunch" ? 12 : meal.mealType == "Dinner" ? 18 : 20
        let when = cal.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        for item in meal.items {
            context.insert(FoodLogEntry(date: when, foodName: item.displayName, brand: item.brand, calories: item.calories, proteinG: item.proteinG, carbsG: item.carbsG, fatG: item.fatG, sodiumMg: item.sodiumMg, mealType: meal.mealType))
        }
        try? context.save()
    }
}

struct MealCard: View {
    var meal: MealSuggestion; var zip: String; var onAdd: (() -> Void)? = nil
    @State private var expanded = false
    @State private var added = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text(meal.mealType.uppercased()).font(.caption.weight(.black)).foregroundStyle(WCTheme.gold); Spacer(); Text("\(meal.prepMinutes) min").font(.caption).foregroundStyle(WCTheme.textSecondary); Text("\(meal.calories) cal").fontWeight(.bold) }
            Text(meal.title).font(.title3.weight(.black))
            Text("\(Int(meal.proteinG))g P • \(Int(meal.carbsG))g C • \(Int(meal.fatG))g F • \(Int(meal.sodiumMg)) mg Na").font(.subheadline).foregroundStyle(WCTheme.textSecondary)
            ForEach(meal.items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName).fontWeight(.semibold)
                    Text("\(item.serving) • \(item.calories) cal • Na \(Int(item.sodiumMg)) mg").font(.caption).foregroundStyle(WCTheme.textSecondary)
                    if item.isBranded {
                        ForEach(StoreService.nearbyStores(zip: zip, for: item).prefix(3)) { store in
                            HStack { Image(systemName: "storefront").foregroundStyle(WCTheme.gold); Text("\(store.name) — \(String(format: "%.1f", store.distanceMiles)) mi").font(.caption); Spacer(); Text(store.carriesNote).font(.caption2).foregroundStyle(WCTheme.textTertiary).lineLimit(1) }
                        }
                    }
                }
            }
            HStack(spacing: 10) {
                Button(expanded ? "Hide Prep" : "Prep & Ingredients") { expanded.toggle() }.font(.subheadline.weight(.bold)).foregroundStyle(WCTheme.redBright).frame(minHeight: 44)
                Spacer()
                if let onAdd {
                    Button { onAdd(); added = true } label: { Label(added ? "Added" : "Add to Day", systemImage: added ? "checkmark.circle.fill" : "plus.circle.fill").font(.subheadline.weight(.black)) }
                        .buttonStyle(.bordered).tint(added ? WCTheme.success : WCTheme.red).frame(minHeight: 44)
                }
            }
            if expanded { Text("Ingredients: \(meal.ingredients.joined(separator: ", "))").font(.subheadline); Text(meal.instructions).font(.subheadline).foregroundStyle(WCTheme.textSecondary) }
        }.wcCard()
    }
}
