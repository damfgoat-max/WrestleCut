import Foundation

struct SafetyAssessment { var isSafe: Bool; var weeklyRatePercent: Double; var message: String; var severity: String }
struct DayTarget { var date: Date; var targetWeightLbs: Double; var calories: Int; var proteinG: Double; var carbsG: Double; var fatG: Double; var waterML: Int; var phase: String }

enum CutCalculator {
    static func assess(profile: UserProfile) -> SafetyAssessment {
        let weeks = max(1.0, Double(profile.totalDays) / 7.0)
        let weeklyLbs = profile.totalToLoseLbs / weeks
        let weeklyPct = profile.startWeightLbs > 0 ? (weeklyLbs / profile.startWeightLbs) * 100 : 0
        if weeklyPct <= 2.0 { return SafetyAssessment(isSafe: true, weeklyRatePercent: weeklyPct, message: String(format: "Safe pace: %.1f%% body weight per week. This protects muscle and strength.", weeklyPct), severity: "Safe") }
        if weeklyPct <= 3.0 { return SafetyAssessment(isSafe: false, weeklyRatePercent: weeklyPct, message: String(format: "Aggressive: %.1f%% per week is above the 1.5–2%% safe guideline. Most of the late cut would need to be water — talk to your coach/trainer before attempting this.", weeklyPct), severity: "Caution") }
        return SafetyAssessment(isSafe: false, weeklyRatePercent: weeklyPct, message: String(format: "Unsafe: %.1f%% per week exceeds safe guidelines. Consider a higher weight class or a longer timeline. WrestleCut will NOT build a crash plan — your health comes first.", weeklyPct), severity: "Unsafe")
    }
    static func bmr(profile: UserProfile) -> Double {
        let kg = profile.currentWeightLbs * 0.453592
        let base = 10*kg + 6.25*profile.heightCm - 5*Double(profile.age)
        return profile.biologicalSex == "Female" ? base - 161 : base + 5 // Mifflin-St Jeor
    }
    static func tdee(profile: UserProfile) -> Double { bmr(profile: profile) * (ActivityLevel(rawValue: profile.activityLevelRaw) ?? .high).factor }
    static func calorieTarget(profile: UserProfile, for date: Date = .now) -> Int {
        let floorVal: Double = profile.biologicalSex == "Female" ? 1400 : 1600
        if profile.calorieGoalOverride > 0 { return max(Int(floorVal), profile.calorieGoalOverride) } // user's own goal from More tab, floor still protects
        let daysLeft = max(0, Calendar.current.dateComponents([.day], from: date, to: profile.weighInDate).day ?? 0)
        let maintenance = tdee(profile: profile)
        // Progressive: modest deficit early, slightly larger mid, taper + focus water late. Never below floor.
        var deficit: Double = 400
        if daysLeft <= 3 { deficit = 500 } else if daysLeft <= 10 { deficit = 550 } else { deficit = 400 }
        return Int(max(floorVal, maintenance - deficit).rounded())
    }
    static func macros(profile: UserProfile, calories: Int) -> (protein: Double, carbs: Double, fat: Double) {
        let goalKg = profile.goalWeightLbs * 0.453592
        var protein = goalKg * 2.2 // high protein to protect muscle, explained in app
        var fat = goalKg * 0.8
        if profile.proteinTargetOverride > 0 { protein = profile.proteinTargetOverride }
        if profile.fatTargetOverride > 0 { fat = profile.fatTargetOverride }
        let proteinCal = protein*4, fatCal = fat*9
        var carbs = max(50, (Double(calories) - proteinCal - fatCal)/4)
        if profile.carbsTargetOverride > 0 { carbs = profile.carbsTargetOverride }
        return (protein.rounded(), carbs.rounded(), fat.rounded())
    }
    static func timeline(profile: UserProfile) -> [DayTarget] {
        let cal = Calendar.current
        var result: [DayTarget] = []
        for offset in 0...profile.totalDays {
            guard let date = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: profile.startDate)) else { continue }
            let fraction = profile.totalDays == 0 ? 1 : Double(offset)/Double(profile.totalDays)
            // Non-linear: 70% fat loss spread evenly, 30% water in final 4 days
            let fatFraction: Double
            if offset >= profile.totalDays - 4 { fatFraction = 0.70 + 0.30 * Double(offset - (profile.totalDays-4))/4.0 } else { fatFraction = 0.70 * fraction / max(0.01, 1 - 4.0/Double(max(1,profile.totalDays))) * (Double(max(1,profile.totalDays-4))/Double(max(1,profile.totalDays))) }
            let clamped = min(1, max(0, fatFraction))
            let target = profile.startWeightLbs - profile.totalToLoseLbs * clamped
            let cals = calorieTarget(profile: profile, for: date)
            let m = macros(profile: profile, calories: cals)
            let phase = offset >= profile.totalDays-4 ? "Water Phase" : (fraction < 0.5 ? "Foundation" : "Sharpen")
            result.append(DayTarget(date: date, targetWeightLbs: (target*10).rounded()/10, calories: cals, proteinG: m.protein, carbsG: m.carbs, fatG: m.fat, waterML: HydrationCalculator.dailyTargetML(weightLbs: target, daysUntilWeighIn: profile.totalDays-offset), phase: phase))
        }
        return result
    }
    static func todaysTarget(profile: UserProfile) -> DayTarget? { timeline(profile: profile).first { Calendar.current.isDateInToday($0.date) } ?? timeline(profile: profile).last }
}

enum HydrationCalculator {
    static func dailyTargetML(weightLbs: Double, daysUntilWeighIn: Int) -> Int {
        // Transparent formula: ~40ml per kg bodyweight baseline (≈0.6 oz per lb), adjusted for water loading
        let kg = weightLbs * 0.453592
        var base = kg * 40
        if daysUntilWeighIn == 3 || daysUntilWeighIn == 4 { base = kg * 55 } // load
        else if daysUntilWeighIn == 2 { base = kg * 50 }
        else if daysUntilWeighIn == 1 { base = kg * 25 } // taper, not zero — never advise complete restriction
        else if daysUntilWeighIn == 0 { base = kg * 15 } // sips to weigh-in
        return Int(base.rounded())
    }
    static func explanation(weightLbs: Double) -> String { "Formula: bodyweight in kg × 40 ml. For \(Int(weightLbs)) lb (≈\(Int((weightLbs*0.453592).rounded())) kg) that's about \(dailyTargetML(weightLbs: weightLbs, daysUntilWeighIn: 99)) ml on a normal day. It rises during water loading (3–4 days out) and tapers — never to zero — into weigh-ins." }
}
