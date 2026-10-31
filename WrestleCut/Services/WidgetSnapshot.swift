import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// The app and its Home Screen widgets can't share the SwiftData store directly,
/// so the app publishes a small stats snapshot into the shared App Group every time
/// the numbers change, and tells WidgetKit to refresh. Widgets read only this snapshot.
enum WidgetSnapshot {
    static let groupID = "group.com.wrestlecut.app"

    static func save(currentWeight: Double, startWeight: Double, goalWeight: Double, daysLeft: Int,
                     calories: Int, calorieGoal: Int, waterML: Int, waterGoal: Int,
                     sodiumMg: Double, sodiumLimit: Int) {
        guard let defaults = UserDefaults(suiteName: groupID) else { return }
        defaults.set(currentWeight, forKey: "snap_currentWeight")
        defaults.set(startWeight, forKey: "snap_startWeight")
        defaults.set(goalWeight, forKey: "snap_goalWeight")
        defaults.set(daysLeft, forKey: "snap_daysLeft")
        defaults.set(calories, forKey: "snap_calories")
        defaults.set(calorieGoal, forKey: "snap_calorieGoal")
        defaults.set(waterML, forKey: "snap_waterML")
        defaults.set(waterGoal, forKey: "snap_waterGoal")
        defaults.set(sodiumMg, forKey: "snap_sodiumMg")
        defaults.set(sodiumLimit, forKey: "snap_sodiumLimit")
        defaults.set(Date.now.timeIntervalSince1970, forKey: "snap_updatedAt")
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "WrestleCutWidget")
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
