import SwiftUI
import SwiftData

struct DashboardView: View {
    var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\WaterEntry.date, order: .reverse)]) private var waterEntries: [WaterEntry]
    @Query(sort: [SortDescriptor(\FoodLogEntry.date, order: .reverse)]) private var foodLogs: [FoodLogEntry]
    private var todayFood: [FoodLogEntry] { foodLogs.filter{Calendar.current.isDateInToday($0.date)} }
    private var todayCalories: Int { todayFood.reduce(0){$0+$1.calories} }
    private var todaySodium: Double { todayFood.reduce(0){$0+$1.sodiumMg} }
    private var sodiumGuide: Int { SodiumGuide.effectiveLimitMg(profile: profile) }
    @State private var showWeightLog = false; @State private var newWeight = ""
    private var todayWater: Int { waterEntries.filter{Calendar.current.isDateInToday($0.date)}.reduce(0){$0+$1.milliliters} }
    private var target: DayTarget? { CutCalculator.todaysTarget(profile: profile) }
    private var waterTarget: Int { HydrationCalculator.dailyTargetML(weightLbs: profile.currentWeightLbs, daysUntilWeighIn: profile.daysUntilWeighIn) }
    var body: some View {
        NavigationStack {
            ScrollView { VStack(spacing:16){
                HStack(alignment:.top){ VStack(alignment:.leading, spacing:4){ Text("MAKE THE WEIGHT.").font(.title.weight(.black)); Text("Stay strong. Dominate.").foregroundStyle(WCTheme.gold).fontWeight(.bold) }; Spacer(); VStack{ Text("\(profile.daysUntilWeighIn)").font(.title.weight(.black)).foregroundStyle(WCTheme.red); Text("DAYS LEFT").font(.caption2.weight(.black)) }.wcCard() }
                HStack(spacing:16){ ProgressRing(progress: profile.progress); VStack(alignment:.leading, spacing:10){
                    Text("Current").font(.caption).foregroundStyle(WCTheme.textSecondary); Text("\(String(format:"%.1f",profile.currentWeightLbs)) lb").font(.title2.weight(.black))
                    Text("Goal").font(.caption).foregroundStyle(WCTheme.textSecondary); Text("\(String(format:"%.1f",profile.goalWeightLbs)) lb").font(.title2.weight(.black)).foregroundStyle(WCTheme.gold)
                    Text("\(String(format:"%.1f",profile.remainingLbs)) lb to go").font(.subheadline.weight(.bold)).foregroundStyle(WCTheme.red)
                }; Spacer() }.wcCard()
                if let t = target { HStack{ VStack(alignment:.leading){ Text("TODAY'S TARGET").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary); Text("\(String(format:"%.1f",t.targetWeightLbs)) lb").font(.title3.weight(.black)); Text("\(t.calories) cal • \(Int(t.proteinG))g protein").font(.caption).foregroundStyle(WCTheme.textSecondary) }; Spacer(); Image(systemName:"target").foregroundStyle(WCTheme.gold).font(.title) }.wcCard() }
                VStack(alignment:.leading, spacing:10){
                    HStack{ SectionHeader(title:"Water", subtitle:"\(todayWater) / \(waterTarget) ml"); Spacer(); Text("\(Int(Double(todayWater)/Double(max(1,waterTarget))*100))%").fontWeight(.black).foregroundStyle(WCTheme.gold) }
                    ProgressView(value: min(1, Double(todayWater)/Double(max(1,waterTarget)))).tint(.cyan).scaleEffect(y:2)
                    HStack(spacing:10){ ForEach([250,500,1000], id:\.self){ ml in Button("+\(ml) ml"){ addWater(ml) }.buttonStyle(.bordered).tint(.cyan).fontWeight(.bold) } }
                }.wcCard()
                VStack(alignment:.leading, spacing:10){
                    Text("TODAY'S FUEL — AT A GLANCE").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                    HStack(spacing:14){
                        VStack(alignment:.leading, spacing:2){ Text("\(todayCalories)").font(.title2.weight(.black)); Text("of \(target?.calories ?? 0) cal").font(.caption).foregroundStyle(WCTheme.textSecondary) }
                        Divider().frame(height:36)
                        VStack(alignment:.leading, spacing:2){ Text("\(Int(todayFood.reduce(0){$0+$1.proteinG}))g").font(.title2.weight(.black)).foregroundStyle(WCTheme.red); Text("protein").font(.caption).foregroundStyle(WCTheme.textSecondary) }
                        VStack(alignment:.leading, spacing:2){ Text("\(Int(todayFood.reduce(0){$0+$1.carbsG}))g").font(.title2.weight(.black)).foregroundStyle(WCTheme.gold); Text("carbs").font(.caption).foregroundStyle(WCTheme.textSecondary) }
                        VStack(alignment:.leading, spacing:2){ Text("\(Int(todayFood.reduce(0){$0+$1.fatG}))g").font(.title2.weight(.black)).foregroundStyle(.cyan); Text("fat").font(.caption).foregroundStyle(WCTheme.textSecondary) }
                    }
                    HStack{ Text("SODIUM").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary); Spacer(); Text("\(Int(todaySodium)) / \(sodiumGuide) mg").font(.subheadline.weight(.bold)).foregroundStyle(todaySodium > Double(sodiumGuide) ? WCTheme.warning : .white) }
                    ProgressView(value: min(1, todaySodium/Double(max(1,sodiumGuide)))).tint(.orange).scaleEffect(y:2)
                    Text(SodiumGuide.note(daysUntilWeighIn: profile.daysUntilWeighIn)).font(.caption2).foregroundStyle(WCTheme.textTertiary)
                }.wcCard()
                HStack{ Label("Streak: \(profile.streakDays) days", systemImage:"flame.fill").foregroundStyle(WCTheme.gold).fontWeight(.bold); Spacer(); Text(motivational).font(.subheadline).italic() }.wcCard()
                Button("Log Today's Weight"){ showWeightLog = true }.frame(maxWidth:.infinity).padding().background(WCTheme.surface2).clipShape(RoundedRectangle(cornerRadius:14))
                SafetyBanner(assessment: CutCalculator.assess(profile: profile))
                DisclaimerView()
            }.padding() }
            .wcBackground().navigationTitle("Wrestle Cut").navigationBarTitleDisplayMode(.inline)
            .alert("Log Weight (lb)", isPresented:$showWeightLog){ TextField("e.g. 157.5", text:$newWeight).keyboardType(.decimalPad); Button("Save"){ if let v=Double(newWeight){ profile.currentWeightLbs=v; context.insert(WeightEntry(weightLbs:v)); try? context.save() } }; Button("Cancel", role:.cancel){} }
        }
    }
    private var motivational: String { let msgs=["One good day at a time.","Discipline beats desperation.","Fuel like you want to win.","Hydrate. Sleep. Execute."]; return msgs[profile.daysUntilWeighIn % msgs.count] }
    private func addWater(_ ml:Int){ context.insert(WaterEntry(milliliters: ml)); try? context.save() }
}
