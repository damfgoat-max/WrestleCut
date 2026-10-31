import SwiftUI
import SwiftData

@main
struct WrestleCutApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [UserProfile.self, WeightEntry.self, WaterEntry.self, FoodLogEntry.self, WorkoutEntry.self])
    }
}
