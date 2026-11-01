import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]
    var body: some View {
        Group {
            if let profile = profiles.first {
                MainTabView(profile: profile)
            } else {
                OnboardingView()
            }
        }
        // Follows the system appearance — the theme palette supports light + dark.
        .tint(WCTheme.red)
    }
}

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    var profile: UserProfile
    // Live widget publishing: this view wraps every tab, and its queries observe the whole
    // store — so logging food, adding water or weighing in ANYWHERE refreshes the widgets instantly.
    @Query private var allFood: [FoodLogEntry]
    @Query private var allWater: [WaterEntry]
    @Query private var allWeights: [WeightEntry]
    private var todayCalories: Int { allFood.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.calories } }
    private var todaySodium: Double { allFood.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.sodiumMg } }
    private var todayWater: Int { allWater.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.milliliters } }
    private var waterGoal: Int { profile.waterGoalOverrideML > 0 ? profile.waterGoalOverrideML : HydrationCalculator.dailyTargetML(weightLbs: profile.currentWeightLbs, daysUntilWeighIn: profile.daysUntilWeighIn) }
    private var currentWeight: Double { allWeights.sorted { $0.date > $1.date }.first?.weightLbs ?? profile.currentWeightLbs }
    private func publishWidgets() {
        WidgetSnapshot.save(currentWeight: currentWeight, startWeight: profile.startWeightLbs, goalWeight: profile.goalWeightLbs, daysLeft: profile.daysUntilWeighIn, calories: todayCalories, calorieGoal: CutCalculator.todaysTarget(profile: profile)?.calories ?? CutCalculator.calorieTarget(profile: profile), waterML: todayWater, waterGoal: waterGoal, sodiumMg: todaySodium, sodiumLimit: SodiumGuide.effectiveLimitMg(profile: profile))
    }
    var body: some View {
        TabView {
            DashboardView(profile: profile).tabItem { Label("Home", systemImage: "house.fill") }
            NutritionView(profile: profile).tabItem { Label("Meals", systemImage: "fork.knife") }
            TrackerView(profile: profile).tabItem { Label("Food", systemImage: "barcode.viewfinder") }
            HydrationView(profile: profile).tabItem { Label("Water", systemImage: "drop.fill") }
            MoreView(profile: profile).tabItem { Label("More", systemImage: "slider.horizontal.3") }
        }
        .onAppear { NotificationService.sync(profile: profile); publishWidgets() }
        .onChange(of: todayCalories) { _, _ in publishWidgets() }
        .onChange(of: todayWater) { _, _ in publishWidgets() }
        .onChange(of: todaySodium) { _, _ in publishWidgets() }
        .onChange(of: scenePhase) { _, phase in if phase == .background || phase == .inactive { publishWidgets() } }
        .onChange(of: currentWeight) { _, _ in publishWidgets() }
        .onChange(of: profile.goalWeightLbs) { _, _ in publishWidgets() }
        .onChange(of: profile.startWeightLbs) { _, _ in publishWidgets() }
        .onChange(of: profile.daysUntilWeighIn) { _, _ in publishWidgets() }
        .onChange(of: profile.waterGoalOverrideML) { _, _ in publishWidgets() }
        .onChange(of: profile.sodiumLimitOverrideMg) { _, _ in publishWidgets() }
        .onChange(of: profile.calorieGoal) { _, _ in publishWidgets() }
    }
}
