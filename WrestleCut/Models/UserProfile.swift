import Foundation
import SwiftData

@Model
final class UserProfile {
    var age: Int
    var heightCm: Double
    var heightFeet: Int
    var heightInches: Int
    var biologicalSex: String // "Male" / "Female" - for BMR formula, user-selected
    var activityLevelRaw: String
    var startWeightLbs: Double
    var currentWeightLbs: Double
    var goalWeightLbs: Double
    var startDate: Date
    var weighInDate: Date
    var zipCode: String
    var address: String
    var dislikedFoodIDs: [String]
    var createdAt: Date
    var streakDays: Int
    var lastLogDate: Date?

    init(age: Int = 18, heightCm: Double = 175, heightFeet: Int = 5, heightInches: Int = 9,
         biologicalSex: String = "Male", activityLevelRaw: String = "High",
         startWeightLbs: Double = 160, currentWeightLbs: Double = 160, goalWeightLbs: Double = 152,
         startDate: Date = .now, weighInDate: Date = Calendar.current.date(byAdding: .day, value: 28, to: .now) ?? .now,
         zipCode: String = "", address: String = "", dislikedFoodIDs: [String] = []) {
        self.age = age; self.heightCm = heightCm; self.heightFeet = heightFeet; self.heightInches = heightInches
        self.biologicalSex = biologicalSex; self.activityLevelRaw = activityLevelRaw
        self.startWeightLbs = startWeightLbs; self.currentWeightLbs = currentWeightLbs; self.goalWeightLbs = goalWeightLbs
        self.startDate = startDate; self.weighInDate = weighInDate
        self.zipCode = zipCode; self.address = address; self.dislikedFoodIDs = dislikedFoodIDs
        self.createdAt = .now; self.streakDays = 0; self.lastLogDate = nil
    }
    var totalToLoseLbs: Double { max(0, startWeightLbs - goalWeightLbs) }
    var lostSoFarLbs: Double { max(0, startWeightLbs - currentWeightLbs) }
    var remainingLbs: Double { max(0, currentWeightLbs - goalWeightLbs) }
    var progress: Double { guard totalToLoseLbs > 0 else { return 1 }; return min(1, max(0, lostSoFarLbs / totalToLoseLbs)) }
    var daysUntilWeighIn: Int { max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: weighInDate)).day ?? 0) }
    var totalDays: Int { max(1, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: startDate), to: Calendar.current.startOfDay(for: weighInDate)).day ?? 1) }
    var heightDisplay: String { "\(heightFeet)'\(heightInches)\" • \(Int(heightCm.rounded())) cm" }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case moderate = "Moderate", high = "High", veryHigh = "Very High"
    var id: String { rawValue }
    var factor: Double { switch self { case .moderate: return 1.55; case .high: return 1.725; case .veryHigh: return 1.9 } }
    var label: String { switch self { case .moderate: return "Moderate — practice 3-4x/week"; case .high: return "High — practice 5-6x/week"; case .veryHigh: return "Very High — 2-a-days / camp" } }
}
