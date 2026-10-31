import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var age = 18
    @State private var feet = 5; @State private var inches = 9; @State private var heightCm = 175.0
    @State private var sex = "Male"; @State private var activity = ActivityLevel.high
    @State private var startWeight = 160.0; @State private var goalWeight = 152.0
    @State private var startDate = Date.now; @State private var weighInDate = Calendar.current.date(byAdding: .day, value: 28, to: .now) ?? .now
    @State private var zip = ""; @State private var address = ""
    @State private var disliked: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                TabView(selection: $step) {
                    welcome.tag(0); basics.tag(1); weights.tag(2); foods.tag(3); locationStep.tag(4); review.tag(5)
                }.tabViewStyle(.page(indexDisplayMode: .never)).animation(.easeInOut, value: step)
                footer
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WCBackdrop())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    private var header: some View {
        VStack(spacing: 7) {
            WCBadge(size: 58)
            Text("WRESTLECUT").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
            Text("Cut Weight Safely • Made for Wrestlers").font(.subheadline.weight(.semibold)).foregroundStyle(WCTheme.gold)
                .lineLimit(1).minimumScaleFactor(0.75)
            ProgressView(value: Double(step+1), total: 6).tint(WCTheme.red).padding(.horizontal, 40).padding(.top, 6)
        }.padding(.top, 14).padding(.horizontal, 16).frame(maxWidth: .infinity)
    }
    private var footer: some View {
        VStack(spacing: 10) {
            WCGradientButton(title: step == 5 ? "MAKE THE WEIGHT — START MY CUT" : "Continue") {
                if step < 5 { withAnimation { step += 1 } } else { save() }
            }
            if step > 0 { Button("Back") { withAnimation { step -= 1 } }.foregroundStyle(WCTheme.textSecondary) }
            Text("Guidance only — not medical advice. Talk to your coach, athletic trainer, or doctor before cutting weight, especially if you are under 18.")
                .font(.caption2).foregroundStyle(WCTheme.textTertiary).multilineTextAlignment(.center).padding(.horizontal)
        }.padding()
    }
    private var welcome: some View {
        ScrollView { VStack(alignment: .leading, spacing: 18) {
            Text("Make the weight.\nStay strong.\nDominate.").font(.system(size: 33, weight: .black, design: .rounded)).foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(LinearGradient(colors: [WCTheme.redBright, WCTheme.gold], startPoint: .leading, endPoint: .trailing))
                .frame(width: 64, height: 4).clipShape(Capsule()).accessibilityHidden(true)
            Text("WrestleCut builds a safe, progressive plan — never a crash cut. Fat loss early, smart water timing late, and a full rehydration plan after you step off the scale.")
                .foregroundStyle(WCTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
            Label("No ads. No subscriptions. 100% free, forever.", systemImage: "heart.fill").foregroundStyle(WCTheme.gold).fontWeight(.bold)
            Label("Safety first: max 1.5–2% body weight per week", systemImage: "shield.fill").foregroundStyle(.white)
            Label("Works fully offline. Your data stays on your phone.", systemImage: "lock.fill").foregroundStyle(.white)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.vertical, 12) }
    }
    private var basics: some View {
        Form {
            Section("About You") {
                Stepper("Age: \(age)", value: $age, in: 8...80)
                Picker("Biological sex (for calorie math)", selection: $sex) { Text("Male").tag("Male"); Text("Female").tag("Female") }
                Picker("Activity", selection: $activity) { ForEach(ActivityLevel.allCases){ Text($0.label).tag($0) } }
            }
            Section("Height") {
                Stepper("Feet: \(feet)", value: $feet, in: 4...7)
                Stepper("Inches: \(inches)", value: $inches, in: 0...11)
                HStack { Text("Centimeters"); Spacer(); TextField("cm", value: $heightCm, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                Text("We keep ft/in and cm in sync for the formulas. \(feet)'\(inches)\" ≈ \(Int((Double(feet*12+inches)*2.54).rounded())) cm").font(.caption).foregroundStyle(.secondary)
            }
        }.scrollContentBackground(.hidden)
    }
    private var weights: some View {
        Form {
            Section("Weights (lb)") {
                HStack{ Text("Starting weight"); Spacer(); TextField("lb", value: $startWeight, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                HStack{ Text("Goal / weigh-in weight"); Spacer(); TextField("lb", value: $goalWeight, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                Text("Total to lose: \(String(format:"%.1f", max(0,startWeight-goalWeight))) lb").fontWeight(.bold)
            }
            Section("Dates") {
                DatePicker("Cut starts", selection: $startDate, displayedComponents: .date)
                DatePicker("Weigh-in day", selection: $weighInDate, displayedComponents: .date)
            }
            Section { safetyPreview }
        }.scrollContentBackground(.hidden)
    }
    @ViewBuilder private var safetyPreview: some View {
        let days = max(1, Calendar.current.dateComponents([.day], from: startDate, to: weighInDate).day ?? 1)
        let weeks = Double(days)/7; let pct = startWeight>0 ? ((max(0,startWeight-goalWeight)/max(1,weeks))/startWeight)*100 : 0
        VStack(alignment:.leading, spacing:6){
            Text(String(format:"Pace: %.1f%% per week over %d days", pct, days)).fontWeight(.bold)
            if pct <= 2 { Text("✅ Safe pace. This protects muscle, strength, and focus.").foregroundStyle(WCTheme.success) }
            else { Text("⚠️ Above the 1.5–2% safe guideline. WrestleCut will warn you and suggest a longer timeline or higher class. We don't build crash cuts.").foregroundStyle(WCTheme.warning) }
        }
    }
    private var foods: some View {
        List {
            Section { Text("Tap everything you strongly dislike or are allergic to. WrestleCut will avoid it in every meal plan. Allergies: always double-check labels yourself.").font(.caption).foregroundStyle(.secondary) }
            ForEach(Array(Set(FoodDatabase.dislikeOptions.map(\.category))).sorted(), id:\.self) { cat in
                Section(cat) {
                    ForEach(FoodDatabase.dislikeOptions.filter{$0.category==cat}) { opt in
                        Button { if disliked.contains(opt.id){disliked.remove(opt.id)} else {disliked.insert(opt.id)} } label: {
                            HStack{ Text(opt.name).foregroundStyle(.white); Spacer(); if disliked.contains(opt.id){ Image(systemName:"checkmark.circle.fill").foregroundStyle(WCTheme.red) } }
                        }
                    }
                }
            }
        }.scrollContentBackground(.hidden)
    }
    private var locationStep: some View {
        Form {
            Section("Nearby Stores (Optional)") {
                TextField("ZIP code", text: $zip).keyboardType(.numberPad)
                TextField("Full address (optional)", text: $address)
                Text("Used only to show nearby stores that carry your meal-plan products — Walmart, Kroger, Publix, Whole Foods, Aldi, Target. Nothing is sent to a server in offline mode.").font(.caption).foregroundStyle(.secondary)
            }
        }.scrollContentBackground(.hidden)
    }
    private var review: some View {
        ScrollView { VStack(spacing:14){
            SectionHeader(title:"Your Cut at a Glance", subtitle:"Check it. Own it.")
            VStack(alignment:.leading, spacing:8){
                Text("\(Int(startWeight)) lb  →  \(Int(goalWeight)) lb").font(.title.weight(.black))
                Text("Age \(age) • \(feet)'\(inches)\" • \(zip.isEmpty ? "No ZIP" : "ZIP \(zip)")")
                Text("Avoiding \(disliked.count) foods").foregroundStyle(WCTheme.gold)
            }.wcCard().frame(maxWidth:.infinity, alignment:.leading)
            Text("How your calories are calculated: Mifflin-St Jeor BMR × activity, minus a modest deficit (400–550 cal). Protein is set at 2.2 g per kg of goal weight to protect muscle. Every number in WrestleCut shows its formula — no black box.")
                .font(.subheadline).foregroundStyle(WCTheme.textSecondary)
        }.padding() }
    }
    private func save() {
        let cm = Double(feet*12+inches)*2.54
        let p = UserProfile(age: age, heightCm: cm, heightFeet: feet, heightInches: inches, biologicalSex: sex, activityLevelRaw: activity.rawValue, startWeightLbs: startWeight, currentWeightLbs: startWeight, goalWeightLbs: goalWeight, startDate: startDate, weighInDate: weighInDate, zipCode: zip, address: address, dislikedFoodIDs: Array(disliked))
        context.insert(p)
        context.insert(WeightEntry(weightLbs: startWeight, note: "Start"))
        try? context.save()
    }
}
