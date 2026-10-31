import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]
    var body: some View {
        Group {
            if let profile = profiles.first {
                MainTabView(profile: profile)
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
        .tint(WCTheme.red)
    }
}

struct MainTabView: View {
    var profile: UserProfile
    var body: some View {
        TabView {
            DashboardView(profile: profile).tabItem { Label("Home", systemImage: "house.fill") }
            CuttingPlanView(profile: profile).tabItem { Label("Plan", systemImage: "calendar.badge.clock") }
            NutritionView(profile: profile).tabItem { Label("Nutrition", systemImage: "fork.knife") }
            TrackerView(profile: profile).tabItem { Label("Tracker", systemImage: "barcode.viewfinder") }
            HydrationView(profile: profile).tabItem { Label("Hydration", systemImage: "drop.fill") }
            RecoveryView(profile: profile).tabItem { Label("Recovery", systemImage: "arrow.clockwise.heart.fill") }
            ProgressAnalyticsView(profile: profile).tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
    }
}
