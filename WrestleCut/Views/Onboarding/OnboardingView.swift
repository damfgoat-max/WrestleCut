import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var age = 18
    @State private var feet = 5; @State private var inches = 9
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
            .keyboardDoneBar().scrollDismissesKeyboard(.interactively)
            .onChange(of: step) { _, _ in KeyboardDismiss.now() }
        }
    }
    private var header: some View {
        VStack(spacing: 7) {
            WCBadge(size: 58)
            Text("WRESTLE CUT").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(WCTheme.textPrimary)
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
                KeyboardDismiss.now()
                if step < 5 { withAnimation { step += 1 } } else { save() }
            }
            if step > 0 { Button("Back") { KeyboardDismiss.now(); withAnimation { step -= 1 } }.foregroundStyle(WCTheme.textSecondary) }
            Text("Guidance only — not medical advice. Talk to your coach, athletic trainer, or doctor before cutting weight, especially if you are under 18.")
                .font(.caption2).foregroundStyle(WCTheme.textTertiary).multilineTextAlignment(.center).padding(.horizontal)
        }.padding()
    }
    private var welcome: some View {
        ScrollView { VStack(alignment: .leading, spacing: 18) {
            Text("Make the weight.\nStay strong.\nDominate.").font(.system(size: 33, weight: .black, design: .rounded)).foregroundStyle(WCTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(WCTheme.red)
                .frame(width: 64, height: 4).clipShape(Capsule()).accessibilityHidden(true)
            Text("WrestleCut builds a safe, progressive plan — never a crash cut. Fat loss early, smart water timing late, and a full rehydration plan after you step off the scale.")
                .foregroundStyle(WCTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
            Label("No ads. No subscriptions. 100% free, forever.", systemImage: "heart.fill").foregroundStyle(WCTheme.gold).fontWeight(.bold)
            Label("Safety first: max 1.5–2% body weight per week", systemImage: "shield.fill").foregroundStyle(WCTheme.textPrimary)
            Label("Works fully offline. Your data stays on your phone.", systemImage: "lock.fill").foregroundStyle(WCTheme.textPrimary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.vertical, 12) }
    }
    private var basics: some View {
        ScrollView { VStack(spacing: 16) {
            BigStepperRow(title: "Age", valueText: "\(age) years", decrease: { age = max(8, age-1) }, increase: { age = min(80, age+1) })
            VStack(alignment: .leading, spacing: 10) {
                Text("BIOLOGICAL SEX — FOR CALORIE MATH").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                HStack(spacing: 12) {
                    BigChoiceChip(title: "Male", selected: sex == "Male") { sex = "Male" }
                    BigChoiceChip(title: "Female", selected: sex == "Female") { sex = "Female" }
                }
            }.wcCard()
            VStack(alignment: .leading, spacing: 10) {
                Text("TRAINING LEVEL").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                ForEach(ActivityLevel.allCases) { level in
                    BigChoiceRow(title: level.label, selected: activity == level) { activity = level }
                }
            }.wcCard()
            VStack(spacing: 0) {
                BigStepperRowContent(title: "Height — Feet", valueText: "\(feet) ft", decrease: { feet = max(4, feet-1) }, increase: { feet = min(7, feet+1) })
                Divider().background(Color.white.opacity(0.08))
                BigStepperRowContent(title: "Height — Inches", valueText: "\(inches) in", decrease: { inches = max(0, inches-1) }, increase: { inches = min(11, inches+1) })
            }.wcCard()
            Text("\(feet)'\(inches)\" = \(Int((Double(feet*12+inches)*2.54).rounded())) cm — both are kept in sync for the formulas.")
                .font(.subheadline).foregroundStyle(WCTheme.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(16) }
    }
    private var weights: some View {
        ScrollView { VStack(spacing: 16) {
            BigNumberField(title: "STARTING WEIGHT (LB)", value: $startWeight)
            BigNumberField(title: "GOAL WEIGHT — WEIGH-IN DAY (LB)", value: $goalWeight)
            HStack {
                Text("Total to lose").font(.title3.weight(.bold))
                Spacer()
                Text("\(String(format:"%.1f", max(0,startWeight-goalWeight))) lb").font(.title3.weight(.black)).foregroundStyle(WCTheme.gold)
            }.wcCard()
            VStack(alignment: .leading, spacing: 12) {
                Text("DATES").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                DatePicker("Cut starts", selection: $startDate, displayedComponents: .date).font(.title3.weight(.semibold)).frame(minHeight: 52)
                Divider().background(Color.white.opacity(0.08))
                DatePicker("Weigh-in day", selection: $weighInDate, displayedComponents: .date).font(.title3.weight(.semibold)).frame(minHeight: 52)
            }.wcCard()
            safetyPreviewCard
        }.padding(16) }
    }
    private var safetyPreviewCard: some View {
        let days = max(1, Calendar.current.dateComponents([.day], from: startDate, to: weighInDate).day ?? 1)
        let weeks = Double(days)/7; let pct = startWeight>0 ? ((max(0,startWeight-goalWeight)/max(1,weeks))/startWeight)*100 : 0
        return VStack(alignment:.leading, spacing:8){
            Text(String(format:"Pace: %.1f%% per week over %d days", pct, days)).font(.title3.weight(.black))
            if pct <= 2 { Text("Safe pace. This protects muscle, strength, and focus.").foregroundStyle(WCTheme.success).font(.body) }
            else { Text("Above the 1.5–2% safe guideline. Wrestle Cut will warn you and suggest a longer timeline or higher class. We don't build crash cuts.").foregroundStyle(WCTheme.warning).font(.body) }
        }.frame(maxWidth:.infinity, alignment:.leading).wcCard()
    }
    private var foods: some View {
        ScrollView { VStack(spacing: 16) {
            Text("Tap everything you strongly dislike or are allergic to. Wrestle Cut will avoid it in every meal plan. Allergies: always double-check labels yourself.")
                .font(.body).foregroundStyle(WCTheme.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(Set(FoodDatabase.dislikeOptions.map(\.category))).sorted(), id:\.self) { cat in
                VStack(alignment: .leading, spacing: 10) {
                    Text(cat.uppercased()).font(.caption.weight(.black)).foregroundStyle(WCTheme.gold)
                    ForEach(FoodDatabase.dislikeOptions.filter{$0.category==cat}) { opt in
                        BigChoiceRow(title: opt.name, selected: disliked.contains(opt.id), selectedIcon: "xmark.circle.fill") {
                            if disliked.contains(opt.id) { disliked.remove(opt.id) } else { disliked.insert(opt.id) }
                        }
                    }
                }.wcCard()
            }
        }.padding(16) }
    }
    private var locationStep: some View {
        ScrollView { VStack(spacing: 16) {
            BigTextField(title: "ZIP CODE", placeholder: "e.g. 53202", text: $zip, keyboard: .numberPad)
            BigTextField(title: "FULL ADDRESS (OPTIONAL)", placeholder: "Street, City, State", text: $address, keyboard: .default)
            Text("Used only to show nearby stores that carry your meal-plan products — Walmart, Kroger, Publix, Whole Foods, Aldi, Target, Costco. Nothing is sent to a server in offline mode.")
                .font(.body).foregroundStyle(WCTheme.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
            Text("You can skip this and add it later.").font(.subheadline.weight(.bold)).foregroundStyle(WCTheme.gold).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(16) }
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

// MARK: - Big, wrestler-friendly setup controls (large tap targets, Dynamic Type friendly)

struct BigStepperRowContent: View {
    var title: String; var valueText: String; var decrease: () -> Void; var increase: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(valueText).font(.title3.weight(.black)).foregroundStyle(WCTheme.gold)
            }
            Spacer()
            BigRoundButton(systemImage: "minus") { decrease() }
            BigRoundButton(systemImage: "plus") { increase() }
        }.frame(minHeight: 64)
    }
}

struct BigStepperRow: View {
    var title: String; var valueText: String; var decrease: () -> Void; var increase: () -> Void
    var body: some View { BigStepperRowContent(title: title, valueText: valueText, decrease: decrease, increase: increase).wcCard() }
}

struct BigRoundButton: View {
    var systemImage: String; var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage).font(.title3.weight(.black))
                .frame(width: 52, height: 52)
                .background(WCTheme.surface2).foregroundStyle(WCTheme.textPrimary)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
        }.accessibilityLabel(systemImage == "plus" ? "Increase" : "Decrease")
    }
}

struct BigChoiceChip: View {
    var title: String; var selected: Bool; var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.title3.weight(.black))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(selected ? WCTheme.red : WCTheme.surface2)
                .foregroundStyle(selected ? .white : WCTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(selected ? WCTheme.gold : Color.white.opacity(0.10), lineWidth: selected ? 2 : 1))
        }
    }
}

struct BigChoiceRow: View {
    var title: String; var selected: Bool; var selectedIcon: String = "checkmark.circle.fill"; var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(WCTheme.textPrimary).multilineTextAlignment(.leading)
                Spacer()
                if selected { Image(systemName: selectedIcon).font(.title3).foregroundStyle(WCTheme.gold) }
            }.frame(maxWidth: .infinity, minHeight: 56).padding(.horizontal, 14)
            .background(selected ? WCTheme.red.opacity(0.22) : WCTheme.surface2.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct BigNumberField: View {
    var title: String; @Binding var value: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
            TextField("0", value: $value, format: .number).keyboardType(.decimalPad)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(WCTheme.gold)
        }.frame(maxWidth: .infinity, alignment: .leading).wcCard()
    }
}

struct BigTextField: View {
    var title: String; var placeholder: String; @Binding var text: String; var keyboard: UIKeyboardType = .default
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
            TextField(placeholder, text: $text).keyboardType(keyboard)
                .font(.title3.weight(.bold)).frame(minHeight: 40)
                .autocorrectionDisabled()
        }.frame(maxWidth: .infinity, alignment: .leading).wcCard()
    }
}
