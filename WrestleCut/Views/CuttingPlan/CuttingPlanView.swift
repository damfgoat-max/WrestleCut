import SwiftUI
import Charts

struct CuttingPlanView: View {
    var profile: UserProfile
    private var timeline: [DayTarget] { CutCalculator.timeline(profile: profile) }
    var body: some View {
        NavigationStack { ScrollView { VStack(spacing:16){
            SectionHeader(title:"Cutting Plan", subtitle:"\(profile.totalDays) days • Foundation → Sharpen → Water Phase")
            SafetyBanner(assessment: CutCalculator.assess(profile: profile))
            VStack(alignment:.leading, spacing:8){ Text("DAILY WEIGHT TARGETS").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                Chart(timeline, id:\.date){ item in LineMark(x:.value("Day", item.date), y:.value("lb", item.targetWeightLbs)).foregroundStyle(WCTheme.red).interpolationMethod(.catmullRom); PointMark(x:.value("Day", item.date), y:.value("lb", item.targetWeightLbs)).foregroundStyle(WCTheme.gold).symbolSize(18) }
                .frame(height:220).chartYScale(domain:(profile.goalWeightLbs-2)...(profile.startWeightLbs+2))
            }.wcCard()
            weeklyBreakdown
            VStack(alignment:.leading, spacing:8){ Text("HOW IT WORKS").font(.caption.weight(.black)).foregroundStyle(WCTheme.gold)
                Text("• Early weeks: fat loss from a modest calorie deficit — max 1.5–2% per week.\n• Final 4 days: the remaining drop is timed water, using a load → taper protocol, never complete fluid restriction.\n• If your pace is unsafe, WrestleCut tells you straight — no crash plans.").font(.subheadline).foregroundStyle(WCTheme.textSecondary) }.wcCard()
            ForEach(timeline.prefix(14), id:\.date){ d in HStack{ Text(d.date, format:.dateTime.month().day()).fontWeight(.bold).frame(width:52, alignment:.leading); Text(d.phase).font(.caption).padding(6).background(WCTheme.surface2).clipShape(Capsule()); Spacer(); Text("\(String(format:"%.1f",d.targetWeightLbs)) lb").fontWeight(.bold); Text("\(d.calories) cal").font(.caption).foregroundStyle(WCTheme.textSecondary) }.wcCard() }
            DisclaimerView()
        }.padding() }.wcBackground().navigationTitle("Cutting Plan") }
    }
    private var weeklyBreakdown: some View {
        VStack(alignment:.leading, spacing:8){ Text("WEEKLY BREAKDOWN").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
            let weeks = max(1, profile.totalDays/7)
            ForEach(0..<weeks, id:\.self){ w in HStack{ Text("Week \(w+1)"); Spacer(); if w == weeks-1 && profile.totalDays>10 { Text("Fat + timed water").foregroundStyle(WCTheme.gold) } else { Text("Primarily fat loss").foregroundStyle(WCTheme.textSecondary) } }.font(.subheadline) }
            Text("Estimate only — bodies vary. Your actual scale trend in Progress is what matters.").font(.caption).foregroundStyle(WCTheme.textTertiary)
        }.wcCard()
    }
}
