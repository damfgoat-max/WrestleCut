import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct TrackerView: View {
    var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\FoodLogEntry.date, order: .reverse)]) private var logs: [FoodLogEntry]
    @Query(sort: [SortDescriptor(\WorkoutEntry.date, order: .reverse)]) private var workouts: [WorkoutEntry]
    @State private var query = ""
    @State private var showScanner = false
    @State private var scannedCode: String?
    @State private var mealForLogging = "Snack"
    @State private var showManual = false
    // Photo food detection
    @State private var photoItem: PhotosPickerItem?
    @State private var detectedFoods: [FoodItem] = []
    @State private var detectedLabels: [String] = []
    @State private var photoStatus: String?

    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    private var todayLogs: [FoodLogEntry] { logs.filter { Calendar.current.isDateInToday($0.date) } }
    private var totals: (cal: Int, p: Double, c: Double, f: Double, sodium: Double) {
        todayLogs.reduce((0, 0, 0, 0, 0)) { ($0.0 + $1.calories, $0.1 + $1.proteinG, $0.2 + $1.carbsG, $0.3 + $1.fatG, $0.4 + $1.sodiumMg) }
    }
    private var burned: Int { workouts.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.caloriesBurned } }
    private var targetCal: Int { CutCalculator.calorieTarget(profile: profile) + burned }
    private var sodiumGuide: Int { SodiumGuide.dailyGuideMg(daysUntilWeighIn: profile.daysUntilWeighIn) }
    private var results: [FoodItem] {
        FoodDatabase.foods(avoiding: profile.dislikedFoodIDs).filter { query.isEmpty || $0.displayName.localizedCaseInsensitiveContains(query) || $0.barcode == query }
    }

    var body: some View {
        NavigationStack {
            ScrollView { VStack(spacing: 16) {
                totalsCard
                mealPicker
                scanButtons
                if let scannedCode { Text("Barcode: \(scannedCode) — matches are shown first below.").font(.caption).foregroundStyle(WCTheme.gold) }
                if let photoStatus { Text(photoStatus).font(.caption).foregroundStyle(WCTheme.textSecondary) }
                if !detectedFoods.isEmpty {
                    SectionHeader(title: "Photo Detected", subtitle: "We think this is: \(detectedLabels.prefix(3).joined(separator: ", ")). Tap to log it — you confirm, nothing logs itself.")
                    ForEach(detectedFoods) { food in foodRow(food, badge: "PHOTO") }
                }
                TextField("Search foods wrestlers actually eat…", text: $query).textFieldStyle(.roundedBorder).font(.body).frame(minHeight: 44)
                SectionHeader(title: "Quick Add", subtitle: "Tap to log instantly into \(mealForLogging)")
                ForEach(results) { food in foodRow(food, badge: nil) }
                Button { showManual = true } label: {
                    Label("Manual Entry — Fast Add Your Own Food", systemImage: "square.and.pencil")
                        .font(.headline).frame(maxWidth: .infinity, minHeight: 56)
                }.buttonStyle(.bordered).tint(WCTheme.gold)
                if !todayLogs.isEmpty {
                    SectionHeader(title: "Today's Log")
                    ForEach(todayLogs) { log in
                        HStack { VStack(alignment: .leading) { Text(log.foodName).fontWeight(.semibold); Text("\(log.mealType) • Na \(Int(log.sodiumMg)) mg").font(.caption).foregroundStyle(WCTheme.textSecondary) }; Spacer(); Text("\(log.calories) cal").fontWeight(.bold) }.wcCard()
                    }
                }
                if todayLogs.isEmpty && query.isEmpty { EmptyState(icon: "fork.knife.circle", title: "Nothing logged yet", message: "Scan a barcode, snap a photo of your food, search, or add it manually. Fast logging = consistent cutting.") }
            }.padding() }
            .wcBackground().navigationTitle("Food Tracker")
            .sheet(isPresented: $showScanner) { BarcodeScannerView { code in scannedCode = code; query = code; showScanner = false } }
            .sheet(isPresented: $showManual) { ManualEntryView(mealType: mealForLogging) { entry in addManual(entry) } }
            .onChange(of: photoItem) { _, newItem in if let newItem { Task { await analyzePhoto(newItem) } } }
        }
    }

    private var totalsCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) { Text("\(totals.cal)").font(.system(size: 40, weight: .black, design: .rounded)); Text("/ \(targetCal) cal today").foregroundStyle(WCTheme.textSecondary); Spacer(); if burned > 0 { Text("+\(burned) training").font(.caption.weight(.bold)).foregroundStyle(WCTheme.success) } }
            ProgressView(value: min(1, Double(totals.cal) / Double(max(1, targetCal)))).tint(WCTheme.red).scaleEffect(y: 2.2)
            HStack(spacing: 14) {
                Text("P \(Int(totals.p))g").foregroundStyle(WCTheme.red)
                Text("C \(Int(totals.c))g").foregroundStyle(WCTheme.gold)
                Text("F \(Int(totals.f))g").foregroundStyle(.cyan)
            }.font(.headline.weight(.black)).frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                HStack { Text("SODIUM").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary); Spacer(); Text("\(Int(totals.sodium)) / \(sodiumGuide) mg").font(.subheadline.weight(.bold)).foregroundStyle(totals.sodium > Double(sodiumGuide) ? WCTheme.warning : .white) }
                ProgressView(value: min(1, totals.sodium / Double(max(1, sodiumGuide)))).tint(.orange)
                Text(SodiumGuide.note(daysUntilWeighIn: profile.daysUntilWeighIn)).font(.caption2).foregroundStyle(WCTheme.textTertiary)
            }
        }.wcCard()
    }

    private var mealPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LOGGING INTO").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
            HStack(spacing: 8) {
                ForEach(mealTypes, id: \.self) { meal in
                    Button(meal) { mealForLogging = meal }
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(mealForLogging == meal ? WCTheme.red : WCTheme.surface2)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            HStack(spacing: 10) {
                Menu {
                    Button("Wrestling Practice — 60 min") { logWorkout("Wrestling Practice", 60, 600) }
                    Button("Lifting — 45 min") { logWorkout("Weight Training", 45, 250) }
                    Button("Cardio — 30 min") { logWorkout("Cardio", 30, 300) }
                } label: { Label("Log Training", systemImage: "figure.wrestling").font(.subheadline.weight(.bold)) }
                .buttonStyle(.bordered).tint(WCTheme.gold)
                Spacer()
            }
        }.wcCard()
    }

    private var scanButtons: some View {
        HStack(spacing: 12) {
            Button { showScanner = true } label: {
                VStack(spacing: 6) { Image(systemName: "barcode.viewfinder").font(.title); Text("Scan Barcode").font(.subheadline.weight(.black)) }
                    .frame(maxWidth: .infinity, minHeight: 84)
                    .background(LinearGradient(colors: [WCTheme.redBright, WCTheme.red], startPoint: .top, endPoint: .bottom))
                    .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            PhotosPicker(selection: $photoItem, matching: .images) {
                VStack(spacing: 6) { Image(systemName: "camera.viewfinder").font(.title); Text("Photo of Food").font(.subheadline.weight(.black)) }
                    .frame(maxWidth: .infinity, minHeight: 84)
                    .background(WCTheme.surface2).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(WCTheme.gold.opacity(0.5), lineWidth: 1.5))
            }
        }
    }

    private func foodRow(_ food: FoodItem, badge: String?) -> some View {
        Button { add(food) } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) { Text(food.displayName).fontWeight(.semibold).foregroundStyle(.white); if let badge { Text(badge).font(.caption2.weight(.black)).padding(.horizontal, 6).padding(.vertical, 2).background(WCTheme.gold).foregroundStyle(.black).clipShape(Capsule()) } }
                    Text("\(food.serving) • P\(Int(food.proteinG)) C\(Int(food.carbsG)) F\(Int(food.fatG)) • Na \(Int(food.sodiumMg)) mg").font(.caption).foregroundStyle(WCTheme.textSecondary)
                }
                Spacer()
                Text("\(food.calories)").font(.title3.weight(.black)).foregroundStyle(WCTheme.gold)
                Text("cal").font(.caption).foregroundStyle(WCTheme.textSecondary)
                Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(WCTheme.red)
            }.frame(minHeight: 56).wcCard()
        }
    }

    private func add(_ food: FoodItem) {
        context.insert(FoodLogEntry(foodName: food.displayName, brand: food.brand, calories: food.calories, proteinG: food.proteinG, carbsG: food.carbsG, fatG: food.fatG, sodiumMg: food.sodiumMg, mealType: mealForLogging))
        try? context.save()
    }
    private func addManual(_ e: ManualEntry) {
        context.insert(FoodLogEntry(foodName: e.name, calories: e.calories, proteinG: e.protein, carbsG: e.carbs, fatG: e.fat, sodiumMg: e.sodium, mealType: e.mealType))
        try? context.save()
    }
    private func logWorkout(_ kind: String, _ min: Int, _ cal: Int) { context.insert(WorkoutEntry(kind: kind, minutes: min, caloriesBurned: cal)); try? context.save() }

    private func analyzePhoto(_ item: PhotosPickerItem) async {
        photoStatus = "Looking at your photo on-device…"
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { photoStatus = "Couldn't read that photo — try search or manual entry."; return }
        #if canImport(Vision)
        FoodPhotoService.detect(in: image) { detections in
            detectedLabels = detections.map(\.label)
            detectedFoods = FoodPhotoService.matchedFoods(for: detections, avoiding: profile.dislikedFoodIDs)
            photoStatus = detectedFoods.isEmpty
                ? "Photo read (\(detectedLabels.prefix(2).joined(separator: ", "))) — no exact match in the wrestler database. Search or add it manually below, it takes 10 seconds."
                : "Photo analyzed on your phone — nothing was uploaded. Confirm the right food below."
        }
        #else
        photoStatus = "Photo detection isn't available on this device — use search or manual entry."
        #endif
    }
}

struct ManualEntry: Equatable { var name: String; var calories: Int; var protein: Double; var carbs: Double; var fat: Double; var sodium: Double; var mealType: String }

struct ManualEntryView: View {
    var mealType: String
    var onSave: (ManualEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""; @State private var calories = ""; @State private var protein = ""; @State private var carbs = ""; @State private var fat = ""; @State private var sodium = ""
    var body: some View {
        NavigationStack {
            ScrollView { VStack(spacing: 14) {
                Text("Type what's on the label — or your best estimate. Estimates beat skipping a log, every time.")
                    .font(.subheadline).foregroundStyle(WCTheme.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
                field("FOOD NAME", placeholder: "e.g. 4oz chicken breast", text: $name, keyboard: .default)
                field("CALORIES", placeholder: "e.g. 165", text: $calories)
                HStack(spacing: 12) { field("PROTEIN (G)", placeholder: "31", text: $protein); field("CARBS (G)", placeholder: "0", text: $carbs) }
                HStack(spacing: 12) { field("FAT (G)", placeholder: "4", text: $fat); field("SODIUM (MG)", placeholder: "75", text: $sodium) }
                WCGradientButton(title: "Add to \(mealType)") {
                    guard !name.isEmpty, let cal = Int(calories) else { return }
                    onSave(ManualEntry(name: name, calories: cal, protein: Double(protein) ?? 0, carbs: Double(carbs) ?? 0, fat: Double(fat) ?? 0, sodium: Double(sodium) ?? 0, mealType: mealType))
                    dismiss()
                }
            }.padding() }
            .wcBackground().navigationTitle("Manual Entry").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
    private func field(_ title: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .decimalPad) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
            TextField(placeholder, text: text).keyboardType(keyboard).font(.title3.weight(.bold)).frame(minHeight: 44)
        }.frame(maxWidth: .infinity, alignment: .leading).wcCard()
    }
}

#if canImport(VisionKit)
import VisionKit
struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(recognizedDataTypes: [.barcode()], qualityLevel: .balanced, recognizesMultipleItems: false, isHighFrameRateTrackingEnabled: false, isPinchToZoomEnabled: true, isGuidanceEnabled: true, isHighlightingEnabled: true)
        vc.delegate = context.coordinator; try? vc.startScanning(); return vc
    }
    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onScan: (String) -> Void; init(onScan: @escaping (String) -> Void) { self.onScan = onScan }
        func dataScanner(_ scanner: DataScannerViewController, didTapOn item: RecognizedItem) { if case .barcode(let b) = item { onScan(b.payloadStringValue ?? "") } }
        func dataScanner(_ scanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) { if let first = addedItems.first, case .barcode(let b) = first { onScan(b.payloadStringValue ?? "") } }
    }
}
#else
struct BarcodeScannerView: View { var onScan: (String) -> Void; var body: some View { VStack(spacing: 12) { Text("Barcode scanning needs a real device with VisionKit."); Button("Close") { onScan("") } }.padding() } }
#endif
