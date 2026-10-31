import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    var profile: UserProfile
    @Query(sort:\WeightEntry.date, order:.forward) private var weights: [WeightEntry]
    @Query private var foods: [FoodLogEntry]; @Query private var waters: [WaterEntry]
    private var timeline: [DayTarget] { CutCalculator.timeline(profile: profile) }
    var body: some View {
        NavigationStack { ScrollView { VStack(spacing:16){
            SectionHeader(title:"Progress & Analytics", subtitle:"Actual vs predicted — trust the trend")
            VStack(alignment:.leading, spacing:8){ Text("WEIGHT TREND").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                if weights.isEmpty { EmptyState(icon:"chart.line.downtrend.xyaxis", title:"No weight entries yet", message:"Log your weight on the Home tab to see your trend.") }
                else { Chart { ForEach(timeline, id:\.date){ t in LineMark(x:.value("Day",t.date), y:.value("Predicted",t.targetWeightLbs)).foregroundStyle(WCTheme.gold).lineStyle(StrokeStyle(dash:[5])) }
                    ForEach(weights){ w in LineMark(x:.value("Day",w.date), y:.value("Actual",w.weightLbs)).foregroundStyle(WCTheme.red); PointMark(x:.value("Day",w.date), y:.value("Actual",w.weightLbs)).foregroundStyle(.white) }
                    }.frame(height:220) }
            }.wcCard()
            HStack(spacing:12){ statCard(title:"Lost", value:"\(String(format:"%.1f",profile.lostSoFarLbs)) lb"); statCard(title:"Remaining", value:"\(String(format:"%.1f",profile.remainingLbs)) lb"); statCard(title:"Streak", value:"\(profile.streakDays) days") }
            VStack(alignment:.leading, spacing:8){ Text("WEEKLY SUMMARY").font(.caption.weight(.black)).foregroundStyle(WCTheme.gold)
                Text("• Calorie adherence: \(foods.isEmpty ? "— log food to see this" : "\(foods.count) entries logged")\n• Water consistency: \(waters.isEmpty ? "— log water to see this" : "\(waters.count) water logs")\n• Keep protein high, sleep 8+ hours, and weigh at the same time daily (morning, after bathroom, before food) for a clean trend.").font(.subheadline).foregroundStyle(WCTheme.textSecondary) }.wcCard()
            // Profile / reset
            VStack(alignment:.leading, spacing:6){ Text("YOUR PROFILE").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary); Text("\(profile.heightDisplay) • Age \(profile.age) • ZIP \(profile.zipCode.isEmpty ? "—" : profile.zipCode)"); Text("Avoiding: \(profile.dislikedFoodIDs.joined(separator:", "))").font(.caption).foregroundStyle(WCTheme.textTertiary) }.wcCard()
            DisclaimerView()
        }.padding() }.wcBackground().navigationTitle("Progress") }
    }
    private func statCard(title:String,value:String)->some View { VStack{ Text(value).font(.headline.weight(.black)); Text(title).font(.caption).foregroundStyle(WCTheme.textSecondary) }.frame(maxWidth:.infinity).wcCard() }
}
