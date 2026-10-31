import XCTest
@testable import WrestleCut
final class WrestleCutTests: XCTestCase {
    func testSafetySafePace() { let p = UserProfile(startWeightLbs: 160, currentWeightLbs: 160, goalWeightLbs: 152, startDate: .now, weighInDate: Calendar.current.date(byAdding: .day, value: 28, to: .now)!); XCTAssertTrue(CutCalculator.assess(profile: p).isSafe) }
    func testSafetyUnsafePace() { let p = UserProfile(startWeightLbs: 160, currentWeightLbs: 160, goalWeightLbs: 130, startDate: .now, weighInDate: Calendar.current.date(byAdding: .day, value: 14, to: .now)!); XCTAssertFalse(CutCalculator.assess(profile: p).isSafe) }
    func testMacrosProtein() { let p = UserProfile(goalWeightLbs: 152); let m = CutCalculator.macros(profile: p, calories: 2200); XCTAssertEqual(m.protein, 152, accuracy: 5) }
    func testHydrationNeverZero() { XCTAssertGreaterThan(HydrationCalculator.dailyTargetML(weightLbs: 150, daysUntilWeighIn: 0), 0); XCTAssertGreaterThan(HydrationCalculator.dailyTargetML(weightLbs: 150, daysUntilWeighIn: 1), HydrationCalculator.dailyTargetML(weightLbs: 150, daysUntilWeighIn: 0)) }
    func testCalorieFloor() { let p = UserProfile(age: 16, currentWeightLbs: 120, goalWeightLbs: 115); XCTAssertGreaterThanOrEqual(CutCalculator.calorieTarget(profile: p), 1600) }
    func testFoodAvoidance() { let foods = FoodDatabase.foods(avoiding: ["chicken"]); XCTAssertFalse(foods.contains{ $0.name.lowercased().contains("chicken") && $0.id=="f1" }) }
}
