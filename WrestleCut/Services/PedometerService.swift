import Foundation
import CoreMotion

/// Step counting straight from the iPhone's motion coprocessor — NO HealthKit
/// entitlement needed, only the Motion usage description. This is the fallback
/// that keeps the Workout screen showing REAL activity even on installs where
/// the signer stripped HealthKit.
enum PedometerService {
    private static let pedometer = CMPedometer()
    static var isAvailable: Bool { CMPedometer.isStepCountingAvailable() }

    /// Today's steps and distance (km), or nil if motion access is denied/unavailable.
    static func today() async -> (steps: Int, km: Double)? {
        guard isAvailable else { return nil }
        let start = Calendar.current.startOfDay(for: .now)
        return await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: .now) { data, _ in
                guard let data else { continuation.resume(returning: nil); return }
                let km = (data.distance?.doubleValue ?? 0) / 1000
                continuation.resume(returning: (data.numberOfSteps.intValue, km))
            }
        }
    }
}
