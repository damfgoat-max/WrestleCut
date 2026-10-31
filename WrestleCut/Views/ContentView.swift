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
            NutritionView(profile: profile).tabItem { Label("Meals", systemImage: "fork.knife") }
            TrackerView(profile: profile).tabItem { Label("Food", systemImage: "barcode.viewfinder") }
            HydrationView(profile: profile).tabItem { Label("Water", systemImage: "drop.fill") }
            MoreView(profile: profile).tabItem { Label("More", systemImage: "slider.horizontal.3") }
        }
    }
}
