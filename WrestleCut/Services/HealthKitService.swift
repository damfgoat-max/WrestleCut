import Foundation
import HealthKit

/// Reads today's activity from Apple Health (steps + active energy) so the cut
/// dashboard can show real calories burned. Read-only; everything degrades
/// gracefully to manual logging when Health is unavailable or not authorized.
enum HealthKitService {
    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    private static var store: HKHealthStore? { isAvailable ? HKHealthStore() : nil }

    static func requestAuthorization() async -> Bool {
        guard let store else { return false }
        let read: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.basalEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKObjectType.workoutType()
        ]
        do {
            try await store.requestAuthorization(toShare: [], read: read)
            return true
        } catch { return false }
    }

    private static func todaySum(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let store, let type = HKQuantityType.quantityType(forIdentifier: id) else { return 0 }
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }

    static func todaySteps() async -> Int { Int(await todaySum(.stepCount, unit: .count())) }
    static func todayBasalCalories() async -> Int { Int(await todaySum(.basalEnergyBurned, unit: .kilocalorie())) }

    /// Minutes of actual recorded workouts today (Apple Watch / Health workouts).
    static func todayWorkoutMinutes() async -> Int {
        guard let store else { return 0 }
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let total = (samples as? [HKWorkout])?.reduce(0.0) { $0 + $1.duration } ?? 0
                continuation.resume(returning: Int(total / 60))
            }
            store.execute(query)
        }
    }
    static func todayActiveCalories() async -> Int { Int(await todaySum(.activeEnergyBurned, unit: .kilocalorie())) }
    static func todayExerciseMinutes() async -> Int { Int(await todaySum(.appleExerciseTime, unit: .minute())) }
}
