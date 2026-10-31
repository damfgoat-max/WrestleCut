import SwiftUI
import SwiftData
import Charts

struct HydrationView: View {
    var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\WaterEntry.date, order: .reverse)]) private var entries: [WaterEntry]
    @State private var customAmount = ""
    private var customML: Int? { WaterAmountParser.milliliters(from: customAmount) }
    private var todayML: Int { entries.filter{Calendar.current.isDateInToday($0.date)}.reduce(0){$0+$1.milliliters} }
    private var targetML: Int { if profile.waterGoalOverrideML > 0 { return profile.waterGoalOverrideML }; return HydrationCalculator.dailyTargetML(weightLbs: profile.currentWeightLbs, daysUntilWeighIn: profile.daysUntilWeighIn) }
    var body: some View {
        NavigationStack { ScrollView { VStack(spacing:16){
            SectionHeader(title:"Hydration Coach", subtitle: HydrationCalculator.explanation(weightLbs: profile.currentWeightLbs))
            ZStack{ Circle().stroke(Color.cyan.opacity(0.15), lineWidth:18).frame(width:190, height:190); Circle().trim(from:0,to:min(1,Double(todayML)/Double(max(1,targetML)))).stroke(Color.cyan, style:StrokeStyle(lineWidth:18,lineCap:.round)).frame(width:190, height:190).rotationEffect(.degrees(-90)); VStack{ Text("\(todayML) ml").font(.title.weight(.black)); Text("of \(targetML) ml").foregroundStyle(WCTheme.textSecondary); Text("💧 \(String(format:"%.1f", Double(todayML)/250)) bottles (250ml)").font(.caption) } }.padding()
            VStack(spacing:12){
                Text("TYPE YOUR WATER AMOUNT").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary).frame(maxWidth:.infinity, alignment:.leading)
                HStack(spacing:10){
                    TextField("420ml, 16oz, 1.2L…", text:$customAmount).keyboardType(.numbersAndPunctuation)
                        .font(.system(size:26, weight:.black, design:.rounded)).foregroundStyle(WCTheme.gold)
                        .frame(minHeight:56).padding(.horizontal,12)
                        .background(WCTheme.surface2).clipShape(RoundedRectangle(cornerRadius:14, style:.continuous))
                    Button{ if let ml = customML { add(ml); customAmount = ""; KeyboardDismiss.now() } } label:{
                        Image(systemName:"plus").font(.system(size:30, weight:.black)).foregroundStyle(.white)
                            .frame(width:64, height:64)
                            .background(LinearGradient(colors:[WCTheme.redBright, WCTheme.red], startPoint:.top, endPoint:.bottom))
                            .clipShape(Circle()).shadow(color:WCTheme.red.opacity(0.45), radius:8, y:4)
                    }.disabled(customML == nil).opacity(customML == nil ? 0.4 : 1).accessibilityLabel("Add custom water amount")
                }
                HStack{ Text(customML != nil ? "That's \(customML!) ml — tap + to add it" : "Examples: 420ml  •  16oz  •  1.2 liters  •  2 cups  •  plain number = ml").font(.caption).foregroundStyle(WCTheme.textTertiary); Spacer() }
                Text("No preset buttons — your amount, your call. Type it exactly how you think it: 420ml, 16.9 oz, 1.5 liters.").font(.caption).foregroundStyle(WCTheme.textTertiary).frame(maxWidth: .infinity, alignment: .leading)
            }.wcCard()
            VStack(alignment:.leading, spacing:8){ Text("WATER LOADING — FINAL DAYS").font(.caption.weight(.black)).foregroundStyle(WCTheme.gold)
                Text("• 4–3 days out: HIGH (\(HydrationCalculator.dailyTargetML(weightLbs: profile.currentWeightLbs, daysUntilWeighIn: 3)) ml) — trains your body to excrete water.\n• 2 days out: still elevated.\n• 1 day out: taper to \(HydrationCalculator.dailyTargetML(weightLbs: profile.currentWeightLbs, daysUntilWeighIn: 1)) ml — never zero.\n• Weigh-in day: small sips only until you step on the scale, then follow Recovery immediately.").font(.subheadline).foregroundStyle(WCTheme.textSecondary) }.wcCard()
            VStack(alignment:.leading, spacing:8){ Text("LAST 7 DAYS").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                let last7 = (0..<7).reversed().map{ off -> (Date,Int) in let d=Calendar.current.date(byAdding:.day,value:-off,to:.now)!; return (d, entries.filter{Calendar.current.isDate($0.date,inSameDayAs:d)}.reduce(0){$0+$1.milliliters}) }
                Chart(last7, id:\.0){ item in BarMark(x:.value("Day", item.0, unit:.day), y:.value("ml", item.1)).foregroundStyle(Color.cyan) }.frame(height:160)
            }.wcCard()
            Text("Reminders: Turn on notifications in iOS Settings for WrestleCut. Sip steadily — don't chug a day's water at night.").font(.caption).foregroundStyle(WCTheme.textTertiary)
            DisclaimerView()
        }.padding() }.wcBackground().keyboardDoneBar().scrollDismissesKeyboard(.interactively).navigationTitle("Hydration") }
    }
    private func add(_ ml:Int){
        let newTotal = todayML + ml
        context.insert(WaterEntry(milliliters: ml)); try? context.save()
        WidgetSnapshot.updateWater(ml: newTotal, goal: targetML)
    }
}
