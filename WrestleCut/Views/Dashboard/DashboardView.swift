import SwiftUI
import SwiftData

struct DashboardView: View {
    var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\WaterEntry.date, order: .reverse)]) private var waterEntries: [WaterEntry]
    @Query(sort: [SortDescriptor(\FoodLogEntry.date, order: .reverse)]) private var foodLogs: [FoodLogEntry]
    private var todayFood: [FoodLogEntry] { foodLogs.filter{Calendar.current.isDateInToday($0.date)} }
    @Query(sort: [SortDescriptor(\WorkoutEntry.date, order: .reverse)]) private var workoutEntries: [WorkoutEntry]
    @AppStorage("wcHealthAsked") private var healthAsked = false
    @State private var healthActive = 0
    @State private var healthSteps = 0
    private var manualBurn: Int { workoutEntries.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.caloriesBurned } }
    private var todayCalories: Int { todayFood.reduce(0){$0+$1.calories} }
    private var todaySodium: Double { todayFood.reduce(0){$0+$1.sodiumMg} }
    private var sodiumGuide: Int { SodiumGuide.effectiveLimitMg(profile: profile) }
    @State private var showWeightLog = false; @State private var newWeight = ""
    private var todayWater: Int { waterEntries.filter{Calendar.current.isDateInToday($0.date)}.reduce(0){$0+$1.milliliters} }
    private var target: DayTarget? { CutCalculator.todaysTarget(profile: profile) }
    private var waterTarget: Int { profile.waterGoalOverrideML > 0 ? profile.waterGoalOverrideML : HydrationCalculator.dailyTargetML(weightLbs: profile.currentWeightLbs, daysUntilWeighIn: profile.daysUntilWeighIn) }
    private func pushWidgetSnapshot() {
        WidgetSnapshot.save(currentWeight: profile.currentWeightLbs, startWeight: profile.startWeightLbs, goalWeight: profile.goalWeightLbs, daysLeft: profile.daysUntilWeighIn, calories: todayCalories, calorieGoal: target?.calories ?? CutCalculator.calorieTarget(profile: profile), waterML: todayWater, waterGoal: waterTarget, sodiumMg: todaySodium, sodiumLimit: sodiumGuide)
    }
    var body: some View {
        NavigationStack {
            ScrollView { VStack(spacing:20){
                // Header — quiet, modern: the day, and the countdown.
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today").font(.largeTitle.weight(.bold)).foregroundStyle(WCTheme.textPrimary)
                        Text(Date.now.formatted(.dateTime.weekday(.wide).month().day())).font(.subheadline).foregroundStyle(WCTheme.textSecondary)
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        Text("\(profile.daysUntilWeighIn)").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(WCTheme.red)
                        Text("DAYS LEFT").font(.system(size: 9, weight: .black)).foregroundStyle(WCTheme.textSecondary)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(WCTheme.surface).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                }
                // HERO — the cut at a glance.
                VStack(spacing: 14) {
                    HStack(spacing: 18) {
                        ProgressRing(progress: profile.progress, size: 118)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CURRENT WEIGHT").font(.system(size: 10, weight: .black)).foregroundStyle(WCTheme.textTertiary)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", profile.currentWeightLbs)).font(.system(size: 40, weight: .black, design: .rounded)).foregroundStyle(WCTheme.textPrimary)
                                Text("lb").font(.headline.weight(.bold)).foregroundStyle(WCTheme.textSecondary)
                            }
                            Text("\(String(format: "%.1f", profile.remainingLbs)) lb to go").font(.caption.weight(.black)).foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 5).background(WCTheme.red).clipShape(Capsule())
                            Text("Goal \(String(format: "%.1f", profile.goalWeightLbs)) lb").font(.subheadline.weight(.bold)).foregroundStyle(WCTheme.gold)
                        }
                        Spacer()
                    }
                    HStack {
                        Label("Started at \(String(format: "%.1f", profile.startWeightLbs)) lb", systemImage: "flag.fill").font(.caption.weight(.semibold)).foregroundStyle(WCTheme.textSecondary)
                        Spacer()
                        Label("\(profile.streakDays)-day streak", systemImage: "flame.fill").font(.caption.weight(.bold)).foregroundStyle(WCTheme.gold)
                    }
                }.wcCard()
                // Today's targets as clean tiles.
                if let t = target {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        WCStatTile(icon: "flame.fill", tint: WCTheme.gold, value: "\(max(0, t.calories - todayCalories))", label: "CALORIES LEFT", sub: "of \(t.calories) today")
                        WCStatTile(icon: "target", tint: WCTheme.red, value: "\(String(format: "%.1f", t.targetWeightLbs)) lb", label: "TARGET WEIGHT", sub: t.phase)
                    }
                }
                // Water — big number, thick bar, quiet quick-adds.
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ZStack { RoundedRectangle(cornerRadius: 10, style: .continuous).fill(WCTheme.blue.opacity(0.16)).frame(width: 36, height: 36); Image(systemName: "drop.fill").foregroundStyle(WCTheme.blue) }
                        Text("Water").font(.headline.weight(.bold)).foregroundStyle(WCTheme.textPrimary)
                        Spacer()
                        Text("\(Int(Double(todayWater) / Double(max(1, waterTarget)) * 100))%").font(.subheadline.weight(.black)).foregroundStyle(WCTheme.blue)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(todayWater)").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(WCTheme.textPrimary)
                        Text("/ \(waterTarget) ml").font(.subheadline.weight(.semibold)).foregroundStyle(WCTheme.textSecondary)
                    }
                    WCBar(fraction: Double(todayWater) / Double(max(1, waterTarget)), color: WCTheme.blue)
                    HStack(spacing: 10) {
                        ForEach([250, 500, 1000], id: \.self) { ml in
                            Button("+\(ml) ml") { addWater(ml) }
                                .font(.subheadline.weight(.bold)).foregroundStyle(WCTheme.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(WCTheme.surface2).clipShape(Capsule())
                        }
                    }
                }.wcCard()
                // Fuel — macros as bars, sodium watched.
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Today's Fuel", subtitle: "\(todayCalories) of \(target?.calories ?? 0) calories eaten")
                    MacroBar(label: "Protein", value: todayFood.reduce(0) { $0 + $1.proteinG }, target: target?.proteinG ?? 150, color: WCTheme.red)
                    MacroBar(label: "Carbs", value: todayFood.reduce(0) { $0 + $1.carbsG }, target: target?.carbsG ?? 200, color: WCTheme.gold)
                    MacroBar(label: "Fat", value: todayFood.reduce(0) { $0 + $1.fatG }, target: target?.fatG ?? 60, color: WCTheme.blue)
                    HStack { Text("SODIUM").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary); Spacer(); Text("\(Int(todaySodium)) / \(sodiumGuide) mg").font(.subheadline.weight(.bold)).foregroundStyle(todaySodium > Double(sodiumGuide) ? WCTheme.warning : WCTheme.textPrimary) }
                    WCBar(fraction: todaySodium / Double(max(1, sodiumGuide)), color: WCTheme.gold, height: 8)
                    Text(SodiumGuide.note(daysUntilWeighIn: profile.daysUntilWeighIn)).font(.caption2).foregroundStyle(WCTheme.textTertiary)
                }.wcCard()
                // Workout link — same words, modern card.
                NavigationLink { WorkoutView(profile: profile) } label: {
                    HStack(spacing: 12) {
                        ZStack { RoundedRectangle(cornerRadius: 10, style: .continuous).fill(WCTheme.red.opacity(0.16)).frame(width: 40, height: 40); Image(systemName: "flame.fill").foregroundStyle(WCTheme.red) }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Workout Status — steps • log wrestling practice • calories burned.").font(.headline.weight(.bold)).foregroundStyle(WCTheme.textPrimary)
                            Text("\(healthSteps) steps today").font(.caption).foregroundStyle(WCTheme.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(healthActive + manualBurn)").font(.title3.weight(.black)).foregroundStyle(WCTheme.gold)
                            Text("CAL BURNED").font(.system(size: 9, weight: .black)).foregroundStyle(WCTheme.textSecondary)
                        }
                        Image(systemName: "chevron.right").font(.caption.weight(.black)).foregroundStyle(WCTheme.textTertiary)
                    }
                    .frame(minHeight: 56).wcCard()
                }
                WCGradientButton(title: "Log Today's Weight", systemImage: "scalemass.fill") { showWeightLog = true }
                HStack { Text(motivational).font(.subheadline).italic().foregroundStyle(WCTheme.textSecondary); Spacer() }.wcCard()
                SafetyBanner(assessment: CutCalculator.assess(profile: profile))
                DisclaimerView()
            }.padding(20) }
            .wcBackground().navigationTitle("Wrestle Cut")
            .onAppear {
                pushWidgetSnapshot()
                Task {
                    if HealthKitService.stepAuthCode == 1 { _ = await HealthKitService.requestAuthorization() }
                    healthActive = await HealthKitService.todayActiveCalories()
                    healthSteps = await HealthKitService.todaySteps()
                }
            }
            .onChange(of: todayCalories) { _, _ in pushWidgetSnapshot() }
            .onChange(of: todayWater) { _, _ in pushWidgetSnapshot() }
            .onChange(of: todaySodium) { _, _ in pushWidgetSnapshot() }.navigationBarTitleDisplayMode(.inline)
            .alert("Log Weight (lb)", isPresented:$showWeightLog){ TextField("e.g. 157.5", text:$newWeight).keyboardType(.decimalPad); Button("Save"){ if let v=Double(newWeight){ profile.currentWeightLbs=v; context.insert(WeightEntry(weightLbs:v)); try? context.save() } }; Button("Cancel", role:.cancel){} }
        }
    }
    private var motivational: String { let msgs=["One good day at a time.","Discipline beats desperation.","Fuel like you want to win.","Hydrate. Sleep. Execute."]; return msgs[profile.daysUntilWeighIn % msgs.count] }
    private func addWater(_ ml:Int){
        let newTotal = todayWater + ml
        context.insert(WaterEntry(milliliters: ml)); try? context.save()
        WidgetSnapshot.updateWater(ml: newTotal, goal: waterTarget)
    }
}
