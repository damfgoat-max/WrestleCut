import SwiftUI

struct RecoveryView: View {
    var profile: UserProfile
    private var isWeighInDay: Bool { profile.daysUntilWeighIn == 0 }
    private var rehydrationML: Int { Int((profile.totalToLoseLbs*0.453592)*1500*1.5) } // 1.5L per kg lost as guideline ceiling, paced
    var body: some View {
        ScrollView { VStack(spacing:16){
            if isWeighInDay { Text("🚨 WEIGH-IN DAY — RECOVERY IS ACTIVE").font(.headline.weight(.black)).foregroundStyle(.black).padding().frame(maxWidth:.infinity).background(WCTheme.gold).clipShape(RoundedRectangle(cornerRadius:14)) }
            else { Text("Activates in full on weigh-in day (\(profile.daysUntilWeighIn) days). Read it now so you have supplies ready.").font(.subheadline).foregroundStyle(WCTheme.textSecondary).wcCard() }
            SectionHeader(title:"Rehydration Protocol", subtitle:"Replace 125–150% of fluid lost, paced over hours — not all at once")
            timelineCard(time:"0–15 min after weigh-in", title:"Electrolytes first", body:"500–750 ml oral rehydration / electrolyte drink. Sodium ~1.0–1.5 g/L, potassium, and a source of magnesium from food/drink as directed on the product. Sip, don't chug.")
            timelineCard(time:"15–60 min", title:"Keep sipping + first carbs", body:"Another 500 ml. Add fast + slow carbs: banana, rice, oats, sports drink. Avoid a huge fatty meal right away — it slows gastric emptying.")
            timelineCard(time:"1–4 hours", title:"Build to \(rehydrationML) ml total (paced)", body:"Continue fluids with electrolytes and regular meals every 60–90 min. Target mostly clear/pale-yellow urine, steady energy, no dizziness.")
            timelineCard(time:"4–24 hours", title:"Normal meals, extra sodium/potassium", body:"Balanced meals with carbs + protein (1.2–1.6 g/kg protein/day for recovery), salty foods, fruit, dairy if tolerated. Sleep is your #1 recovery tool.")
            timelineCard(time:"24–48 hours", title:"Back to baseline", body:"Normal hydration (kg × 40 ml), normal training fueling. Monitor weight — it should rebound toward your natural walking weight, that's healthy and expected.")
            VStack(alignment:.leading, spacing:8){ Text("⚠️ WARNING SIGNS — GET HELP").fontWeight(.black).foregroundStyle(WCTheme.redBright)
                Text("Confusion, fainting, vomiting you can't stop, very dark/no urine for 8+ hours, rapid heartbeat, severe headache, or swelling. Stop, tell an adult/coach/trainer, and seek medical care. No match is worth your health.").font(.subheadline) }.wcCard()
            DisclaimerView()
        }.padding() }.wcBackground().navigationTitle("Recovery")
    }
    private func timelineCard(time:String,title:String,body:String)->some View { VStack(alignment:.leading, spacing:6){ Text(time).font(.caption.weight(.black)).foregroundStyle(WCTheme.gold); Text(title).font(.headline); Text(body).font(.subheadline).foregroundStyle(WCTheme.textSecondary) }.frame(maxWidth:.infinity, alignment:.leading).wcCard() }
}
