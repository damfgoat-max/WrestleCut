import SwiftUI
import SwiftData

/// Workout Status: Apple Health activity (steps + active calories) plus manual
/// session logging — Wrestling Practice first-class, with a MET-based burn estimate.
struct WorkoutView: View {
    var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var workouts: [WorkoutEntry]
    @Query private var foodLog: [FoodLogEntry]
    @State private var steps = 0
    @State private var motionSteps = 0
    @State private var motionKm = 0.0
    @State private var activeCalories = 0
    @State private var basalCalories = 0
    @State private var workoutMinutes = 0
    @State private var exerciseMinutes = 0
    @State private var healthNote = ""
    @AppStorage("wcHealthAsked") private var healthAsked = false
    @State private var kind = "Wrestling Practice"
    @State private var minutes = 90

    private let kinds: [(String, Double)] = [
        ("Wrestling Practice", 9.0), ("Live Goes", 10.0), ("Drilling", 6.0),
        ("Conditioning", 8.0), ("Lifting", 5.0), ("Running", 9.8), ("Other", 6.0)
    ]
    private var todayWorkouts: [WorkoutEntry] { workouts.filter { Calendar.current.isDateInToday($0.date) } }
    private var manualBurn: Int { todayWorkouts.reduce(0) { $0 + $1.caloriesBurned } }
    // Activity shown on screen: Apple Health when it answers, otherwise the iPhone's
    // own motion sensor (steps + distance) — so this screen works on ANY install.
    private var displaySteps: Int { steps > 0 ? steps : motionSteps }
    private var motionActiveKcal: Int { Int(motionKm * (profile.currentWeightLbs * 0.453592) * 1.02) }
    private var displayActive: Int { activeCalories > 0 ? activeCalories : motionActiveKcal }
    private var usingMotion: Bool { steps == 0 && activeCalories == 0 && motionSteps > 0 }
    private var totalBurned: Int { displayActive + manualBurn }
    private var eatenToday: Int { foodLog.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.calories } }
    /// Estimated daily deficit: what you ate minus everything you burned (basal + active + logged).
    private var deficit: Int { (basalCalories + totalBurned) - eatenToday }
    private var met: Double { kinds.first { $0.0 == kind }?.1 ?? 6.0 }
    private var estimatedBurn: Int {
        let kg = profile.currentWeightLbs * 0.453592
        return Int(met * kg * (Double(minutes) / 60.0))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("\(totalBurned)").font(.system(size: 52, weight: .black, design: .rounded)).foregroundStyle(WCTheme.gold)
                    Text("CALORIES BURNED TODAY").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                    Text("\(usingMotion ? "Motion sensor" : "Apple Health") \(displayActive) + logged sessions \(manualBurn)")
                        .font(.caption).foregroundStyle(WCTheme.textTertiary)
                }.frame(maxWidth: .infinity).wcCard()

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Apple Health", subtitle: "Steps and activity, pulled automatically")
                    if HealthKitService.isAvailable {
                        HStack(spacing: 12) {
                            healthStat("Steps", "\(displaySteps)", "figure.walk")
                            healthStat("Active Cal", "\(displayActive)", "flame.fill")
                            healthStat("Exercise", "\(exerciseMinutes) min", "timer")
                        }
                        Text("Health access: \(HealthKitService.stepAuthorizationText())").font(.caption.weight(.bold)).foregroundStyle(WCTheme.textSecondary)
                        if usingMotion { Text("Showing your iPhone's motion-sensor steps — Apple Health isn't connected on this install, but your activity still counts.").font(.caption).foregroundStyle(WCTheme.gold) }
                        if let err = HealthKitService.lastError, !err.isEmpty { Text("Health error: \(err)").font(.caption).foregroundStyle(WCTheme.redBright) }
                        HStack(spacing: 12) {
                            healthStat("Basal Cal", "\(basalCalories)", "moon.zzz.fill")
                            healthStat("Workouts", "\(workoutMinutes) min", "figure.wrestling")
                            healthStat("Eaten", "\(eatenToday)", "fork.knife")
                        }
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ESTIMATED DEFICIT TODAY").font(.system(size: 9, weight: .black)).foregroundStyle(WCTheme.textSecondary)
                                Text(deficit >= 0 ? "\(deficit) cal deficit" : "\(abs(deficit)) cal over").font(.headline.weight(.black)).foregroundStyle(deficit >= 0 ? WCTheme.gold : WCTheme.redBright)
                                Text("Eaten \(eatenToday) vs burned \(basalCalories + totalBurned) (basal + active + logged sessions)").font(.caption2).foregroundStyle(WCTheme.textTertiary)
                            }
                            Spacer()
                        }.wcCard()
                        if !healthNote.isEmpty { Text(healthNote).font(.caption).foregroundStyle(WCTheme.textSecondary) }
                        Button { Task { await connectHealth() } } label: {
                            Label("Connect Apple Health", systemImage: "heart.text.square.fill")
                                .font(.headline.weight(.black)).frame(maxWidth: .infinity, minHeight: 52)
                        }.buttonStyle(.bordered).tint(WCTheme.red)
                    } else {
                        Text("Apple Health isn't available on this device — manual logging below still tracks everything.")
                            .font(.subheadline).foregroundStyle(WCTheme.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Log a Session", subtitle: "Burn estimated from your body weight")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 8)], spacing: 8) {
                        ForEach(kinds, id: \.0) { k in
                            Button(k.0) { kind = k.0 }
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(kind == k.0 ? WCTheme.red : WCTheme.surface2)
                                .foregroundStyle(kind == k.0 ? .white : WCTheme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    Stepper(value: $minutes, in: 5...300, step: 5) {
                        HStack { Text("Duration").font(.headline.weight(.bold)); Spacer(); Text("\(minutes) min").font(.title3.weight(.black)).foregroundStyle(WCTheme.gold) }
                    }.frame(minHeight: 52)
                    HStack {
                        Text("Estimated burn").font(.subheadline.weight(.bold)).foregroundStyle(WCTheme.textSecondary)
                        Spacer()
                        Text("≈ \(estimatedBurn) cal").font(.title3.weight(.black)).foregroundStyle(WCTheme.gold)
                    }
                    WCGradientButton(title: "LOG \(kind.uppercased())") {
                        context.insert(WorkoutEntry(kind: kind, minutes: minutes, caloriesBurned: estimatedBurn))
                        try? context.save()
                    }
                    Text("If your watch already counted this session in Apple Health, skip the manual log so you don't double-count it.")
                        .font(.caption2).foregroundStyle(WCTheme.textTertiary)
                }

                if !todayWorkouts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Today's Sessions", subtitle: "Tap the trash to remove one")
                        ForEach(todayWorkouts) { w in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(w.kind).fontWeight(.semibold)
                                    Text("\(w.minutes) min").font(.caption).foregroundStyle(WCTheme.textSecondary)
                                }
                                Spacer()
                                Text("\(w.caloriesBurned) cal").fontWeight(.black).foregroundStyle(WCTheme.gold)
                                Button(role: .destructive) { context.delete(w); try? context.save() } label: {
                                    Image(systemName: "trash").frame(width: 44, height: 44)
                                }
                            }.wcCard()
                        }
                    }
                }
                Text("Burn numbers are estimates — use the trend, not any single day, to judge your cut.")
                    .font(.caption2).foregroundStyle(WCTheme.textTertiary)
            }.padding()
        }
        .wcBackground()
        .navigationTitle("Workout Status")
        .task {
            await refreshHealth()
            // First time here: trigger the real iOS HealthKit permission prompt automatically.
            // The asked-flag is set ONLY after the request actually completes — if the prompt
            // could not be shown (e.g. this install is missing its Health permission), we keep
            // asking on the next visit instead of latching off forever.
            if !healthAsked {
                let ok = await HealthKitService.requestAuthorization()
                if ok { healthAsked = true }
                await refreshHealth()
                if !ok {
                    healthNote = "iOS couldn't show the Health permission prompt — this install may be missing its Health permission (signing). Manual session logging below still tracks your burn."
                } else if steps == 0 && activeCalories == 0 {
                    healthNote = "If your steps show zero, allow Wrestle Cut in iPhone Settings → Health → Data Access & Devices."
                }
            }
        }
    }

    private func healthStat(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(WCTheme.gold)
            Text(value).font(.headline.weight(.black))
            Text(label.uppercased()).font(.system(size: 9, weight: .black)).foregroundStyle(WCTheme.textSecondary)
        }.frame(maxWidth: .infinity).wcCard()
    }

    private func refreshHealth() async {
        guard HealthKitService.isAvailable else { return }
        steps = await HealthKitService.todaySteps()
        activeCalories = await HealthKitService.todayActiveCalories()
        if let motion = await PedometerService.today() { motionSteps = motion.steps; motionKm = motion.km }
        basalCalories = await HealthKitService.todayBasalCalories()
        workoutMinutes = await HealthKitService.todayWorkoutMinutes()
        exerciseMinutes = await HealthKitService.todayExerciseMinutes()
    }

    private func connectHealth() async {
        let ok = await HealthKitService.requestAuthorization()
        await refreshHealth()
        healthNote = ok
            ? (steps == 0 && activeCalories == 0 ? "Connected. No activity recorded yet today — or check iPhone Settings → Health → Data Access if this stays at zero." : "Connected and up to date.")
            : "Couldn't connect: \(HealthKitService.lastError ?? "unknown error") — your motion-sensor steps above still count."
    }
}
