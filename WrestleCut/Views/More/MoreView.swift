import SwiftUI
import WidgetKit
import SwiftData

/// The More tab is mission control: every goal, target, weight and profile setting in the app
/// can be changed here. Blank target fields mean "Automatic" — the app calculates it for you.
struct MoreView: View {
    var profile: UserProfile
    @Environment(\.modelContext) private var context
    @State private var loaded = false
    @State private var saved = false
    // Targets ("" = automatic)
    @State private var calorieGoal = ""; @State private var proteinG = ""; @State private var carbsG = ""; @State private var fatG = ""
    @State private var waterML = ""; @State private var sodiumMg = ""
    // Weights
    @State private var currentWeight = ""; @State private var startWeight = ""; @State private var goalWeight = ""; @State private var weightClass = ""
    // Profile
    @State private var age = 18; @State private var sex = "Male"; @State private var activity = ActivityLevel.high
    @State private var feet = 5; @State private var inches = 9
    @State private var startDate = Date.now; @State private var weighInDate = Date.now
    @State private var zip = ""; @State private var disliked: Set<String> = []
    // Reminders (persisted preferences)
    @AppStorage("wcNotifEnabled") private var notifEnabled = false
    @AppStorage("wcNotifBreakfast") private var nBreakfast = true
    @AppStorage("wcNotifBreakfastMin") private var nBreakfastMin = 450
    @AppStorage("wcNotifLunch") private var nLunch = true
    @AppStorage("wcNotifLunchMin") private var nLunchMin = 750
    @AppStorage("wcNotifDinner") private var nDinner = true
    @AppStorage("wcNotifDinnerMin") private var nDinnerMin = 1110
    @AppStorage("wcNotifMorning") private var nMorning = true
    @AppStorage("wcNotifMorningMin") private var nMorningMin = 420
    @AppStorage("wcNotifWater") private var nWater = true
    @AppStorage("wcNotifWeighIn") private var nWeighIn = true
    @State private var notifDenied = false
    // AI Vision (Pro) — user's own API key, stored in Keychain
    @AppStorage("wcAIProvider") private var aiProviderRaw = "groq"
    @State private var aiKeyText = ""
    @State private var geminiKeyText = ""
    @State private var aiSavedNote = "" 

    private let classes = ["106", "113", "120", "126", "132", "138", "144", "150", "157", "165", "175", "190", "215", "285"]
    private var autoCalories: Int { CutCalculator.calorieTarget(profile: profile) }
    private var autoMacros: (protein: Double, carbs: Double, fat: Double) { CutCalculator.macros(profile: profile, calories: autoCalories) }
    private var autoWater: Int { HydrationCalculator.dailyTargetML(weightLbs: profile.currentWeightLbs, daysUntilWeighIn: 99) }
    private var autoSodium: Int { SodiumGuide.dailyGuideMg(daysUntilWeighIn: profile.daysUntilWeighIn) }

    var body: some View {
        NavigationStack {
            ScrollView { VStack(spacing: 18) {
                targetsSection
                remindersSection
                aiVisionSection
                widgetsSection
                weightsSection
                profileSection
                planLinksSection
                Button("Reset All Targets to Automatic") { resetTargets() }.font(.subheadline.weight(.bold)).foregroundStyle(WCTheme.warning).frame(minHeight: 44)
                WCGradientButton(title: saved ? "✓ SAVED" : "SAVE ALL CHANGES") { saveAll() }
                Text("Changes apply everywhere instantly — Dashboard, Food, Water, Meals and Plan all read from here.").font(.caption).foregroundStyle(WCTheme.textTertiary).multilineTextAlignment(.center)
                DisclaimerView()
            }.padding() }
            .wcBackground().keyboardDoneBar().scrollDismissesKeyboard(.interactively)
            .navigationTitle("More — Settings")
            .onAppear { if !loaded { load(); loaded = true } }
        }
    }

    private var targetsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Daily Targets", subtitle: "Leave a field blank to keep it automatic")
            targetField("CALORIE GOAL (CAL)", auto: "\(autoCalories)", text: $calorieGoal, unit: "cal")
            HStack(spacing: 12) { targetField("PROTEIN (G)", auto: "\(Int(autoMacros.protein))", text: $proteinG, unit: "g"); targetField("CARBS (G)", auto: "\(Int(autoMacros.carbs))", text: $carbsG, unit: "g") }
            HStack(spacing: 12) { targetField("FAT (G)", auto: "\(Int(autoMacros.fat))", text: $fatG, unit: "g"); targetField("SODIUM LIMIT (MG)", auto: "\(autoSodium)", text: $sodiumMg, unit: "mg") }
            targetField("WATER GOAL (ML)", auto: "\(autoWater)", text: $waterML, unit: "ml")
            Text("Safety floor still applies to calories (min \(profile.biologicalSex == "Female" ? 1400 : 1600)) — a custom goal below the floor is raised to the floor.").font(.caption2).foregroundStyle(WCTheme.textTertiary)
        }
    }

    private var remindersSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Reminders", subtitle: "Smart nudges for meals, water, weigh-ins")
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("All Reminders").font(.headline.weight(.bold))
                    Text(notifEnabled ? "On — tap Save All Changes below to apply times" : "Off").font(.caption).foregroundStyle(WCTheme.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $notifEnabled).tint(WCTheme.red).labelsHidden()
                    .onChange(of: notifEnabled) { _, on in
                        if on { Task { let granted = await NotificationService.requestAuthorization(); if !granted { notifDenied = true } } }
                    }
            }.wcCard()
            if notifDenied { Text("Notifications are turned off for Wrestle Cut in iPhone Settings — enable them there (Settings → Wrestle Cut → Notifications), then flip this on again.").font(.caption).foregroundStyle(WCTheme.warning) }
            if notifEnabled {
                reminderRow("Log Breakfast", icon: "sunrise.fill", on: $nBreakfast, minutes: $nBreakfastMin)
                reminderRow("Log Lunch", icon: "sun.max.fill", on: $nLunch, minutes: $nLunchMin)
                reminderRow("Log Dinner", icon: "moon.fill", on: $nDinner, minutes: $nDinnerMin)
                reminderRow("Morning Weigh-In", icon: "scalemass.fill", on: $nMorning, minutes: $nMorningMin)
                HStack {
                    Image(systemName: "drop.fill").foregroundStyle(.cyan)
                    Text("Water Reminders").font(.headline.weight(.bold))
                    Text("10a • 2p • 5p • 8p").font(.caption).foregroundStyle(WCTheme.textSecondary)
                    Spacer()
                    Toggle("", isOn: $nWater).tint(WCTheme.red).labelsHidden()
                }.frame(minHeight: 56).wcCard()
                HStack {
                    Image(systemName: "trophy.fill").foregroundStyle(WCTheme.gold)
                    VStack(alignment: .leading, spacing: 2) { Text("Weigh-In Day Alerts").font(.headline.weight(.bold)); Text("Night before at 8 PM + weigh-in morning at 7 AM").font(.caption).foregroundStyle(WCTheme.textSecondary) }
                    Spacer()
                    Toggle("", isOn: $nWeighIn).tint(WCTheme.red).labelsHidden()
                }.frame(minHeight: 56).wcCard()
            }
        }
    }

    private func reminderRow(_ title: String, icon: String, on: Binding<Bool>, minutes: Binding<Int>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(WCTheme.gold)
            Text(title).font(.headline.weight(.bold))
            Spacer()
            if on.wrappedValue {
                DatePicker("", selection: timeBinding(minutes), displayedComponents: .hourAndMinute).labelsHidden()
            }
            Toggle("", isOn: on).tint(WCTheme.red).labelsHidden()
        }.frame(minHeight: 56).wcCard()
    }

    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: minutes.wrappedValue / 60, minute: minutes.wrappedValue % 60, second: 0, of: .now) ?? .now },
            set: { let c = Calendar.current.dateComponents([.hour, .minute], from: $0); minutes.wrappedValue = (c.hour ?? 0) * 60 + (c.minute ?? 0) }
        )
    }


    @AppStorage("wcWidgetLastPublish") private var widgetLastPublish: Double = 0
    @State private var widgetNote = ""

    private var widgetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Widgets", subtitle: "Home Screen live sync")
            if widgetLastPublish > 0 {
                Text("Last widget update sent: \(Date(timeIntervalSince1970: widgetLastPublish), format: .dateTime.hour().minute().second())")
                    .font(.caption).foregroundStyle(WCTheme.textSecondary)
            } else {
                Text("No widget update has been sent yet — log food or water, then check here.")
                    .font(.caption).foregroundStyle(WCTheme.textSecondary)
            }
            Text("The widget shows its own Updated time in small print. If the widget's time stays frozen while this one keeps moving, the install didn't preserve the shared app group: remove the widget, re-add it once — and if it still freezes, your signing tool needs app groups kept on for the widget.")
                .font(.caption2).foregroundStyle(WCTheme.textTertiary)
            Button {
                WidgetCenter.shared.reloadAllTimelines()
                widgetNote = "Refresh requested — give iOS a few seconds on the Home Screen."
            } label: {
                Label("Refresh Widgets Now", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.bold)).frame(maxWidth: .infinity).padding(.vertical, 6)
            }.buttonStyle(.bordered).tint(WCTheme.gold)
            if !widgetNote.isEmpty { Text(widgetNote).font(.caption2).foregroundStyle(WCTheme.success) }
        }.wcCard()
    }

    private var aiVisionSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "AI Vision", subtitle: "Gemini or Groq — free keys, identifies any food")
            VStack(alignment: .leading, spacing: 10) {
                Text("For identification of ANY food (the full AI brain), add a free key below — Gemini is strongest, Groq also works. Keys are stored only in your iPhone's Keychain, never in the app. With no key, the scanner still works keyless: on-device reading + Open Food Facts web search + reference foods.")
                    .font(.caption).foregroundStyle(WCTheme.textSecondary)
                Text("GEMINI API KEY — FREE AT AISTUDIO.GOOGLE.COM (NEW KEYS START WITH AQ.)").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                SecureField("Paste your Gemini key", text: $geminiKeyText)
                    .font(.body).frame(minHeight: 48).textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                HStack(spacing: 10) {
                    WCGradientButton(title: "SAVE GEMINI KEY") {
                        KeychainStore.set(geminiKeyText.trimmingCharacters(in: .whitespacesAndNewlines), account: "gemini")
                        aiSavedNote = geminiKeyText.isEmpty ? "" : "Saved. Photo scans now use Google Gemini (gemini-2.5-flash) — it can identify any food in a photo."
                    }
                    if !geminiKeyText.isEmpty {
                        Button("Remove") { KeychainStore.set("", account: "gemini"); geminiKeyText = ""; aiSavedNote = "Gemini key removed." }
                            .font(.subheadline.weight(.bold)).frame(minHeight: 52)
                    }
                }
                Text("GROQ API KEY — OPTIONAL, FREE AT CONSOLE.GROQ.COM").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                SecureField("Paste your Groq key", text: $aiKeyText)
                    .font(.body).frame(minHeight: 48).textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                HStack(spacing: 10) {
                    WCGradientButton(title: "SAVE KEY") {
                        KeychainStore.set(aiKeyText.trimmingCharacters(in: .whitespacesAndNewlines), account: aiProviderRaw)
                        aiSavedNote = aiKeyText.isEmpty ? "" : "Saved. Groq key stored — used when no Gemini key is saved."
                    }
                    if !aiKeyText.isEmpty {
                        Button("Remove") { KeychainStore.set("", account: aiProviderRaw); aiKeyText = ""; aiSavedNote = "Key removed — back to the free scanner." }
                            .font(.subheadline.weight(.bold)).frame(minHeight: 52)
                    }
                }
                if !aiSavedNote.isEmpty { Text(aiSavedNote).font(.caption.weight(.semibold)).foregroundStyle(WCTheme.gold) }
                Text((KeychainStore.get("gemini").isEmpty && KeychainStore.get("groq").isEmpty) ? "Key status: NOT SAVED" : "Key status: SAVED ✓")
                    .font(.caption.weight(.bold)).foregroundStyle((KeychainStore.get("gemini").isEmpty && KeychainStore.get("groq").isEmpty) ? WCTheme.warning : WCTheme.success)
                Text("Gemini: \(KeychainStore.get("gemini").isEmpty ? "not saved" : "SAVED ✓") • Groq: \(KeychainStore.get("groq").isEmpty ? "not saved" : "SAVED ✓")")
                    .font(.caption2).foregroundStyle(WCTheme.textTertiary)
                Text((KeychainStore.get("gemini").isEmpty && KeychainStore.get("groq").isEmpty) ? "Keyless mode is ON: on-device reading + web database search + reference foods." : "Full AI identification is ON — \(VisionAIService.provider.displayName) reads your photos.")
                    .font(.caption2).foregroundStyle(WCTheme.textTertiary)
                Text("Gemini key: aistudio.google.com → Get API key → Create API key (new keys start with AQ. — older ones with AIza; both work here). Groq key: console.groq.com → API Keys. No credit card for either. Never share a key in a chat or message — only paste it here, in the app.").font(.caption2).foregroundStyle(WCTheme.textTertiary)
.font(.caption2).foregroundStyle(WCTheme.textTertiary)
            }.wcCard()
        }
        .onAppear { aiKeyText = KeychainStore.get("groq"); geminiKeyText = KeychainStore.get("gemini") }
    }

    private var weightsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Weights & Class", subtitle: "Your cut, your numbers")
            HStack(spacing: 12) { targetField("CURRENT (LB)", auto: String(format: "%.1f", profile.currentWeightLbs), text: $currentWeight, unit: "lb"); targetField("START (LB)", auto: String(format: "%.1f", profile.startWeightLbs), text: $startWeight, unit: "lb") }
            targetField("TARGET WEIGHT (LB)", auto: String(format: "%.1f", profile.goalWeightLbs), text: $goalWeight, unit: "lb")
            VStack(alignment: .leading, spacing: 8) {
                Text("WEIGHT CLASS GOAL").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        classChip("None", value: "")
                        ForEach(classes, id: \.self) { c in classChip("\(c) lb", value: c) }
                    }
                }
                if !weightClass.isEmpty { Text("Class goal: \(weightClass) lb — set your target weight above to the top of your class if that's the plan.").font(.caption2).foregroundStyle(WCTheme.textTertiary) }
            }.wcCard()
        }
    }

    private func classChip(_ label: String, value: String) -> some View {
        Button(label) { weightClass = value }
            .font(.subheadline.weight(.black))
            .padding(.horizontal, 14).frame(minHeight: 48)
            .background(weightClass == value ? WCTheme.red : WCTheme.surface2)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(weightClass == value ? WCTheme.gold : Color.white.opacity(0.08), lineWidth: weightClass == value ? 2 : 1))
    }

    private var profileSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Profile", subtitle: "Same info as setup — change it any time")
            BigStepperRow(title: "Age", valueText: "\(age) years", decrease: { age = max(8, age - 1) }, increase: { age = min(80, age + 1) })
            VStack(alignment: .leading, spacing: 10) {
                Text("BIOLOGICAL SEX — FOR CALORIE MATH").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                HStack(spacing: 12) { BigChoiceChip(title: "Male", selected: sex == "Male") { sex = "Male" }; BigChoiceChip(title: "Female", selected: sex == "Female") { sex = "Female" } }
            }.wcCard()
            VStack(alignment: .leading, spacing: 10) {
                Text("TRAINING LEVEL").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                ForEach(ActivityLevel.allCases) { level in BigChoiceRow(title: level.label, selected: activity == level) { activity = level } }
            }.wcCard()
            VStack(spacing: 0) {
                BigStepperRowContent(title: "Height — Feet", valueText: "\(feet) ft", decrease: { feet = max(4, feet - 1) }, increase: { feet = min(7, feet + 1) })
                Divider().background(Color.white.opacity(0.08))
                BigStepperRowContent(title: "Height — Inches", valueText: "\(inches) in", decrease: { inches = max(0, inches - 1) }, increase: { inches = min(11, inches + 1) })
            }.wcCard()
            VStack(alignment: .leading, spacing: 12) {
                Text("DATES").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                DatePicker("Cut starts", selection: $startDate, displayedComponents: .date).font(.title3.weight(.semibold)).frame(minHeight: 52)
                Divider().background(Color.white.opacity(0.08))
                DatePicker("Weigh-in day", selection: $weighInDate, displayedComponents: .date).font(.title3.weight(.semibold)).frame(minHeight: 52)
            }.wcCard()
            BigTextField(title: "ZIP CODE (FOR NEARBY STORES)", placeholder: "e.g. 53202", text: $zip, keyboard: .numberPad)
            VStack(alignment: .leading, spacing: 10) {
                Text("FOODS TO AVOID (DISLIKES & ALLERGIES)").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                ForEach(FoodDatabase.dislikeOptions) { opt in
                    BigChoiceRow(title: opt.name, selected: disliked.contains(opt.id), selectedIcon: "xmark.circle.fill") {
                        if disliked.contains(opt.id) { disliked.remove(opt.id) } else { disliked.insert(opt.id) }
                    }
                }
            }.wcCard()
        }
    }

    private var planLinksSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Plan & Progress", subtitle: "Everything else lives here")
            linkRow("Workout Status — Steps, Practice, Calories Burned", icon: "flame.fill", color: WCTheme.red) { WorkoutView(profile: profile) }
            linkRow("Cutting Plan", icon: "calendar.badge.clock", color: WCTheme.red) { CuttingPlanView(profile: profile) }
            linkRow("Recovery Protocol", icon: "arrow.clockwise.heart.fill", color: WCTheme.gold) { RecoveryView(profile: profile) }
            linkRow("Progress & Analytics", icon: "chart.line.uptrend.xyaxis", color: .cyan) { ProgressAnalyticsView(profile: profile) }
        }
    }

    private func linkRow<Dest: View>(_ title: String, icon: String, color: Color, @ViewBuilder dest: () -> Dest) -> some View {
        NavigationLink { dest() } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title3).foregroundStyle(color)
                Text(title).font(.headline.weight(.bold)).foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(WCTheme.textTertiary)
            }.frame(minHeight: 60).wcCard()
        }
    }

    private func targetField(_ title: String, auto: String, text: Binding<String>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField(auto, text: text).keyboardType(.numberPad).font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(WCTheme.gold)
                Text(unit).font(.caption.weight(.bold)).foregroundStyle(WCTheme.textTertiary)
            }
            Text(text.wrappedValue.isEmpty ? "Automatic: \(auto) \(unit)" : "Custom — automatic would be \(auto) \(unit)").font(.caption2).foregroundStyle(WCTheme.textTertiary)
        }.frame(maxWidth: .infinity, alignment: .leading).wcCard()
    }

    private func load() {
        calorieGoal = profile.calorieGoalOverride > 0 ? String(profile.calorieGoalOverride) : ""
        proteinG = profile.proteinTargetOverride > 0 ? String(Int(profile.proteinTargetOverride)) : ""
        carbsG = profile.carbsTargetOverride > 0 ? String(Int(profile.carbsTargetOverride)) : ""
        fatG = profile.fatTargetOverride > 0 ? String(Int(profile.fatTargetOverride)) : ""
        waterML = profile.waterGoalOverrideML > 0 ? String(profile.waterGoalOverrideML) : ""
        sodiumMg = profile.sodiumLimitOverrideMg > 0 ? String(profile.sodiumLimitOverrideMg) : ""
        currentWeight = String(format: "%.1f", profile.currentWeightLbs)
        startWeight = String(format: "%.1f", profile.startWeightLbs)
        goalWeight = String(format: "%.1f", profile.goalWeightLbs)
        weightClass = profile.weightClassGoal
        age = profile.age; sex = profile.biologicalSex
        activity = ActivityLevel(rawValue: profile.activityLevelRaw) ?? .high
        feet = profile.heightFeet; inches = profile.heightInches
        startDate = profile.startDate; weighInDate = profile.weighInDate
        zip = profile.zipCode; disliked = Set(profile.dislikedFoodIDs)
    }

    private func saveAll() {
        profile.calorieGoalOverride = Int(calorieGoal) ?? 0
        profile.proteinTargetOverride = Double(proteinG) ?? 0
        profile.carbsTargetOverride = Double(carbsG) ?? 0
        profile.fatTargetOverride = Double(fatG) ?? 0
        profile.waterGoalOverrideML = Int(waterML) ?? 0
        profile.sodiumLimitOverrideMg = Int(sodiumMg) ?? 0
        if let v = Double(currentWeight), v > 0 { profile.currentWeightLbs = v }
        if let v = Double(startWeight), v > 0 { profile.startWeightLbs = v }
        if let v = Double(goalWeight), v > 0 { profile.goalWeightLbs = v }
        profile.weightClassGoal = weightClass
        profile.age = age; profile.biologicalSex = sex; profile.activityLevelRaw = activity.rawValue
        profile.heightFeet = feet; profile.heightInches = inches
        profile.heightCm = Double(feet * 12 + inches) * 2.54
        profile.startDate = startDate; profile.weighInDate = weighInDate
        profile.zipCode = zip; profile.dislikedFoodIDs = Array(disliked)
        try? context.save()
        NotificationService.sync(profile: profile)
        KeyboardDismiss.now()
        saved = true
    }

    private func resetTargets() {
        calorieGoal = ""; proteinG = ""; carbsG = ""; fatG = ""; waterML = ""; sodiumMg = ""
        profile.calorieGoalOverride = 0; profile.proteinTargetOverride = 0; profile.carbsTargetOverride = 0
        profile.fatTargetOverride = 0; profile.waterGoalOverrideML = 0; profile.sodiumLimitOverrideMg = 0
        try? context.save()
        saved = false
    }
}
