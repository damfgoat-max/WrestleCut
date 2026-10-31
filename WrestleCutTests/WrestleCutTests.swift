import XCTest
@testable import WrestleCut
final class WrestleCutTests: XCTestCase {
    func testSafetySafePace() { let p = UserProfile(startWeightLbs: 160, currentWeightLbs: 160, goalWeightLbs: 152, startDate: .now, weighInDate: Calendar.current.date(byAdding: .day, value: 28, to: .now)!); XCTAssertTrue(CutCalculator.assess(profile: p).isSafe) }
    func testSafetyUnsafePace() { let p = UserProfile(startWeightLbs: 160, currentWeightLbs: 160, goalWeightLbs: 130, startDate: .now, weighInDate: Calendar.current.date(byAdding: .day, value: 14, to: .now)!); XCTAssertFalse(CutCalculator.assess(profile: p).isSafe) }
    func testMacrosProtein() { let p = UserProfile(goalWeightLbs: 152); let m = CutCalculator.macros(profile: p, calories: 2200); XCTAssertEqual(m.protein, 152, accuracy: 5) }
    func testHydrationNeverZero() { XCTAssertGreaterThan(HydrationCalculator.dailyTargetML(weightLbs: 150, daysUntilWeighIn: 0), 0); XCTAssertGreaterThan(HydrationCalculator.dailyTargetML(weightLbs: 150, daysUntilWeighIn: 1), HydrationCalculator.dailyTargetML(weightLbs: 150, daysUntilWeighIn: 0)) }
    func testCalorieFloor() { let p = UserProfile(age: 16, currentWeightLbs: 120, goalWeightLbs: 115); XCTAssertGreaterThanOrEqual(CutCalculator.calorieTarget(profile: p), 1600) }
    func testFoodAvoidance() { let foods = FoodDatabase.foods(avoiding: ["chicken"]); XCTAssertFalse(foods.contains{ $0.name.lowercased().contains("chicken") && $0.id=="f1" }) }
    func testWaterParserML() { XCTAssertEqual(WaterAmountParser.milliliters(from: "420ml"), 420); XCTAssertEqual(WaterAmountParser.milliliters(from: "420"), 420) }
    func testWaterParserOz() { XCTAssertEqual(WaterAmountParser.milliliters(from: "16oz"), 473); XCTAssertEqual(WaterAmountParser.milliliters(from: "16 fl oz"), 473) }
    func testWaterParserLiters() { XCTAssertEqual(WaterAmountParser.milliliters(from: "1.2L"), 1200); XCTAssertEqual(WaterAmountParser.milliliters(from: "1.2 liters"), 1200) }
    func testWaterParserInvalid() { XCTAssertNil(WaterAmountParser.milliliters(from: "abc")); XCTAssertNil(WaterAmountParser.milliliters(from: "")) }
    func testSodiumGuideTaper() { XCTAssertGreaterThan(SodiumGuide.dailyGuideMg(daysUntilWeighIn: 10), SodiumGuide.dailyGuideMg(daysUntilWeighIn: 0)) }
    func testSodiumInDatabase() { XCTAssertTrue(FoodDatabase.allFoods.allSatisfy { $0.sodiumMg >= 0 }); XCTAssertEqual(FoodDatabase.allFoods.count, 24) }
}
