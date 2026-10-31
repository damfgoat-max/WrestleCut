import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
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
    @State private var showCamera = false
    @State private var showFilePicker = false
    @State private var pickedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var showScanReview = false
    @State private var barcodeStatus: String?
    @State private var barcodeSeed: FoodItem?
    @State private var barcodeIngredients = ""
    @State private var showBarcodeReview = false
    @State private var editingLog: FoodLogEntry?
    @State private var onlineResults: [OFFProduct] = []
    @State private var onlineStatus: String?

    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    private var todayLogs: [FoodLogEntry] { logs.filter { Calendar.current.isDateInToday($0.date) } }
    private var totals: (cal: Int, p: Double, c: Double, f: Double, sodium: Double) {
        todayLogs.reduce((0, 0, 0, 0, 0)) { ($0.0 + $1.calories, $0.1 + $1.proteinG, $0.2 + $1.carbsG, $0.3 + $1.fatG, $0.4 + $1.sodiumMg) }
    }
    private var burned: Int { workouts.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.caloriesBurned } }
    private var targetCal: Int { CutCalculator.calorieTarget(profile: profile) + burned }
    private var sodiumGuide: Int { SodiumGuide.effectiveLimitMg(profile: profile) }
    private var results: [FoodItem] {
        FoodDatabase.foods(avoiding: profile.dislikedFoodIDs).filter { query.isEmpty || $0.displayName.localizedCaseInsensitiveContains(query) || $0.barcode == query }
    }

    var body: some View {
        NavigationStack {
            ScrollView { VStack(spacing: 16) {
                totalsCard
                mealPicker
                scanButtons
                if let barcodeStatus { Text(barcodeStatus).font(.subheadline.weight(.semibold)).foregroundStyle(WCTheme.gold) }
                else if let scannedCode { Text("Barcode: \(scannedCode)").font(.caption).foregroundStyle(WCTheme.gold) }
                if let photoStatus { Text(photoStatus).font(.subheadline.weight(.semibold)).foregroundStyle(WCTheme.gold) }
                if let pickedImage {
                    ZStack {
                        Image(uiImage: pickedImage).resizable().scaledToFill().frame(maxWidth: .infinity).frame(height: 190).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        if isAnalyzing { Color.black.opacity(0.45); VStack(spacing: 8) { ProgressView().tint(.white).scaleEffect(1.4); Text("ANALYZING ON YOUR PHONE…").font(.caption.weight(.black)).foregroundStyle(.white) } }
                    }.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                if !detectedFoods.isEmpty {
                    SectionHeader(title: "Photo Detected", subtitle: "We think this is: \(detectedLabels.prefix(3).joined(separator: ", ")). Tap to log it — you confirm, nothing logs itself.")
                    ForEach(detectedFoods) { food in foodRow(food, badge: "PHOTO") }
                }
                TextField("Search foods wrestlers actually eat…", text: $query).textFieldStyle(.roundedBorder).font(.body).frame(minHeight: 44)
                if query.trimmingCharacters(in: .whitespaces).count >= 3 {
                    Button { searchOnline() } label: {
                        Label("Search Online Database for “\(query)”", systemImage: "globe")
                            .font(.subheadline.weight(.black)).frame(maxWidth: .infinity, minHeight: 50)
                    }.buttonStyle(.bordered).tint(WCTheme.gold)
                    if let onlineStatus { Text(onlineStatus).font(.caption).foregroundStyle(WCTheme.textSecondary) }
                    ForEach(onlineResults, id: \.name) { product in
                        Button {
                            barcodeSeed = makeSeed(product, barcode: "")
                            barcodeIngredients = product.ingredients
                            showBarcodeReview = true
                        } label: {
                            HStack { VStack(alignment: .leading, spacing: 2) { Text(product.displayName).fontWeight(.semibold).foregroundStyle(.white); Text("\(product.serving) • P \(Int(product.proteinG))g • Na \(Int(product.sodiumMg)) mg").font(.caption).foregroundStyle(WCTheme.textSecondary) }; Spacer(); Text("\(product.calories) cal").fontWeight(.black).foregroundStyle(WCTheme.gold); Image(systemName: "plus.circle.fill").foregroundStyle(WCTheme.red) }.frame(minHeight: 52).wcCard()
                        }
                    }
                }
                SectionHeader(title: "Quick Add", subtitle: "Tap to log instantly into \(mealForLogging)")
                ForEach(results) { food in foodRow(food, badge: nil) }
                Button { showManual = true } label: {
                    Label("Manual Entry — Fast Add Your Own Food", systemImage: "square.and.pencil")
                        .font(.headline).frame(maxWidth: .infinity, minHeight: 56)
                }.buttonStyle(.bordered).tint(WCTheme.gold)
                if !todayLogs.isEmpty {
                    SectionHeader(title: "Today's Log")
                    Text("Tap any food to edit it or delete it.").font(.caption2).foregroundStyle(WCTheme.textTertiary).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(todayLogs) { log in
                        Button { editingLog = log } label: {
                            HStack { VStack(alignment: .leading) { Text(log.foodName).fontWeight(.semibold).foregroundStyle(.white); Text("\(log.mealType) • P \(Int(log.proteinG))g • C \(Int(log.carbsG))g • F \(Int(log.fatG))g • Na \(Int(log.sodiumMg)) mg").font(.caption).foregroundStyle(WCTheme.textSecondary) }; Spacer(); Text("\(log.calories) cal").fontWeight(.bold).foregroundStyle(.white); Image(systemName: "pencil.circle.fill").foregroundStyle(WCTheme.gold) }
                                .frame(minHeight: 52).wcCard()
                        }
                    }
                }
                if todayLogs.isEmpty && query.isEmpty { EmptyState(icon: "fork.knife.circle", title: "Nothing logged yet", message: "Scan a barcode, snap a photo of your food, search, or add it manually. Fast logging = consistent cutting.") }
            }.padding() }
            .wcBackground().keyboardDoneBar().scrollDismissesKeyboard(.interactively).navigationTitle("Food Tracker")
            .sheet(isPresented: $showScanner) { BarcodeScannerView { code in showScanner = false; handleBarcode(code) } }
            .sheet(item: $editingLog) { entry in EditLogView(entry: entry) }
            .sheet(isPresented: $showBarcodeReview) {
                ScanReviewView(image: nil, labels: barcodeSeed.map { [$0.displayName] } ?? [], matches: [], initialMeal: mealForLogging, prefillFood: barcodeSeed, ingredients: barcodeIngredients) { name, serving, cal, pro, carb, fat, sodium, meal in
                    context.insert(FoodLogEntry(foodName: serving.isEmpty ? name : "\(name) (\(serving))", calories: cal, proteinG: pro, carbsG: carb, fatG: fat, sodiumMg: sodium, mealType: meal))
                    try? context.save()
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(
                    onPick: { image in showCamera = false; analyze(image: image) },
                    onCancel: { showCamera = false },
                    onUnavailable: { photoStatus = "Camera isn't available on this device — use Upload a Photo instead." }
                ).ignoresSafeArea()
            }
            .sheet(isPresented: $showManual) { ManualEntryView(mealType: mealForLogging) { entry in addManual(entry) } }
            .sheet(isPresented: $showScanReview) {
                ScanReviewView(image: pickedImage, labels: detectedLabels, matches: detectedFoods, initialMeal: mealForLogging) { name, serving, cal, pro, carb, fat, sodium, meal in
                    context.insert(FoodLogEntry(foodName: serving.isEmpty ? name : "\(name) (\(serving))", calories: cal, proteinG: pro, carbsG: carb, fatG: fat, sodiumMg: sodium, mealType: meal))
                    try? context.save()
                }
            }
            .onChange(of: photoItem) { _, newItem in
                if let newItem {
                    Task { await analyzePhoto(newItem); photoItem = nil }
                }
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.image]) { result in
                switch result {
                case .success(let url):
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        analyze(image: image)
                    } else {
                        photoStatus = "Couldn't read that file — pick a JPG or PNG photo."
                    }
                case .failure:
                    photoStatus = "File picker was cancelled or failed — try Upload a Photo instead."
                }
            }
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
        VStack(spacing: 12) {
        HStack(spacing: 12) {
            Button { showScanner = true } label: {
                VStack(spacing: 6) { Image(systemName: "barcode.viewfinder").font(.title); Text("Scan Barcode").font(.subheadline.weight(.black)) }
                    .frame(maxWidth: .infinity, minHeight: 84)
                    .background(LinearGradient(colors: [WCTheme.redBright, WCTheme.red], startPoint: .top, endPoint: .bottom))
                    .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            Button { showCamera = true } label: {
                VStack(spacing: 6) { Image(systemName: "camera.fill").font(.title); Text("Take Photo").font(.subheadline.weight(.black)) }
                    .frame(maxWidth: .infinity, minHeight: 84)
                    .background(WCTheme.surface2).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(WCTheme.gold.opacity(0.6), lineWidth: 1.5))
            }
        }
        Button { showFilePicker = true } label: {
            VStack(spacing: 6) { Image(systemName: "folder.fill").font(.title3); Text("From Files").font(.caption.weight(.bold)) }
                .frame(maxWidth: .infinity).padding(.vertical, 10)
        }.buttonStyle(.bordered)
        PhotosPicker(selection: $photoItem, matching: .images) {
            Label("Upload from Gallery", systemImage: "photo.on.rectangle.angled")
                .font(.headline.weight(.bold)).frame(maxWidth: .infinity, minHeight: 56)
                .background(WCTheme.surface2.opacity(0.7)).foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    private func makeSeed(_ product: OFFProduct, barcode: String) -> FoodItem {
        FoodItem(id: "off-\(barcode)", name: product.name, brand: product.brand, category: "Scanned", calories: product.calories, proteinG: product.proteinG, carbsG: product.carbsG, fatG: product.fatG, sodiumMg: product.sodiumMg, serving: product.serving, barcode: barcode, priceEstimate: 0)
    }

    private func handleBarcode(_ code: String) {
        scannedCode = code
        guard !code.isEmpty else { return }
        if let local = FoodDatabase.allFoods.first(where: { $0.barcode == code }) {
            barcodeSeed = local
            barcodeIngredients = ""
            barcodeStatus = "Found in the Wrestle Cut database: \(local.displayName). Review and log it."
            showBarcodeReview = true
            return
        }
        barcodeStatus = "Looking up \(code) in Open Food Facts…"
        Task {
            if let product = await OpenFoodFactsService.lookup(barcode: code) {
                barcodeSeed = makeSeed(product, barcode: code)
                barcodeIngredients = product.ingredients
                barcodeStatus = "Found: \(product.displayName) — nutrition auto-filled from Open Food Facts. Check it, then log."
                showBarcodeReview = true
            } else {
                barcodeStatus = "That barcode isn't in Open Food Facts (or you're offline). No problem — tap Manual Entry below and copy the numbers off the label."
            }
        }
    }

    private func searchOnline() {
        let q = query.trimmingCharacters(in: .whitespaces)
        onlineStatus = "Searching Open Food Facts for “\(q)”…"
        Task {
            let results = await OpenFoodFactsService.search(query: q)
            onlineResults = results
            onlineStatus = results.isEmpty ? "No online matches for “\(q)” — try the product's exact name, or use Manual Entry." : "\(results.count) online match\(results.count == 1 ? "" : "es") — tap one to review and log it."
        }
    }

    /// Web identification for ANY food: take what the photo looks like and search the online
    /// food database for that food's real nutrition — works for foods never logged or in the app before.
    private func identifyFromLabels(_ detections: [FoodPhotoService.Detection]) {
        let skip: Set<String> = ["food", "dish", "cuisine", "plate", "meal", "snack", "fast food", "fruit", "vegetable", "meat"]
        let candidates = detections
            .filter { !$0.label.hasPrefix("label text:") && $0.confidence <= 0.98 }
            .map { $0.label.lowercased() }
            .filter { !skip.contains($0) && $0.count > 2 }
        guard !candidates.isEmpty else {
            isAnalyzing = false
            photoStatus = detectedFoods.isEmpty
                ? "Photo read — I see: \(detectedLabels.prefix(3).joined(separator: ", ")). Review and log it below — the name is auto-filled, add the numbers in seconds."
                : "Match found — review the auto-filled numbers, edit anything, then log it."
            if !detectedLabels.isEmpty { showScanReview = true }
            return
        }
        photoStatus = "That looks like \(candidates.first!). Searching the online food database for its real nutrition…"
        Task {
            var found: OFFProduct?
            for q in candidates.prefix(3) where found == nil {
                let results = await OpenFoodFactsService.search(query: q)
                found = results.first
            }
            isAnalyzing = false
            if let product = found {
                barcodeSeed = makeSeed(product, barcode: "")
                barcodeIngredients = product.ingredients
                photoStatus = "Identified online: \(product.displayName) — real nutrition from Open Food Facts. Check the serving, then log it."
                showBarcodeReview = true
            } else {
                photoStatus = detectedFoods.isEmpty
                    ? "Photo read — I see: \(detectedLabels.prefix(3).joined(separator: ", ")). No online match, so review and log below."
                    : "Match found — review the auto-filled numbers, edit anything, then log it."
                if !detectedLabels.isEmpty { showScanReview = true }
            }
        }
    }

    private func analyzePhoto(_ item: PhotosPickerItem) async {
        isAnalyzing = true
        photoStatus = "Loading your photo…"
        do {
            guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                isAnalyzing = false
                photoStatus = "Couldn't read that photo. If it's still in iCloud, open it in Photos once to download it, then try again — or use From Files."
                return
            }
            analyze(image: image)
        } catch {
            isAnalyzing = false
            photoStatus = "Photo download failed (\(error.localizedDescription)). Open it in Photos once, then try again — or use From Files."
        }
    }

    private func analyze(image: UIImage) {
        pickedImage = image
        isAnalyzing = true
        if VisionAIService.isConfigured {
            photoStatus = "Asking \(VisionAIService.provider.displayName) to identify this food…"
            Task {
                if let result = await VisionAIService.analyze(image: image) {
                    var ingredients = result.ingredients
                    if ingredients.isEmpty {
                        // Cross-check the AI's identification against the product database for ingredients.
                        if let match = (await OpenFoodFactsService.search(query: result.name)).first { ingredients = match.ingredients }
                    }
                    barcodeSeed = FoodItem(id: "ai-\(result.name)", name: result.name, brand: result.brand, category: "AI Scan", calories: result.calories, proteinG: result.proteinG, carbsG: result.carbsG, fatG: result.fatG, sodiumMg: result.sodiumMg, serving: result.serving, barcode: "", priceEstimate: 0)
                    barcodeIngredients = ingredients
                    isAnalyzing = false
                    photoStatus = "\(VisionAIService.provider.displayName) identified: \(result.name). Review the numbers, edit anything, then log it."
                    showBarcodeReview = true
                } else {
                    photoStatus = "The AI vision service didn't answer (check your key or connection) — using the free on-device scanner instead."
                    runFreePipeline(image)
                }
            }
            return
        }
        runFreePipeline(image)
    }

    private func runFreePipeline(_ image: UIImage) {
        isAnalyzing = true
        photoStatus = "Got it — analyzing on your phone (nothing is uploaded)…"
        #if canImport(Vision)
        FoodPhotoService.detect(in: image) { detections in
            detectedLabels = detections.map(\.label)
            detectedFoods = FoodPhotoService.matchedFoods(for: detections, avoiding: profile.dislikedFoodIDs)
            // If the photo shows a label, read its text and find the EXACT product in Open Food Facts —
            // that returns the real brand, ingredients and nutrition instead of a shape guess.
            let rawText = detections.first(where: { $0.label.hasPrefix("label text: ") })?.label.replacingOccurrences(of: "label text: ", with: "") ?? ""
            let brandHit = detections.first(where: { $0.confidence > 0.98 })?.label ?? ""
            if !rawText.isEmpty {
                photoStatus = "I can read the label — searching the product database for an exact match…"
                Task {
                    var found: OFFProduct?
                    var queries: [String] = []
                    if !brandHit.isEmpty { queries.append(brandHit) }
                    let stop: Set<String> = ["nutrition", "facts", "the", "and", "with", "per", "serving", "net", "new", "flavor", "flavored", "contains", "value", "daily"]
                    let words = rawText.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty && !stop.contains($0) && $0.count > 1 }
                    if words.count >= 2 { queries.append(words.prefix(5).joined(separator: " ")) }
                    if !brandHit.isEmpty, words.count >= 2 { queries.append("\(brandHit) \(words.prefix(3).joined(separator: " "))") }
                    for q in queries where found == nil {
                        let results = await OpenFoodFactsService.search(query: q)
                        found = results.first
                    }
                    if let product = found {
                        isAnalyzing = false
                        barcodeSeed = makeSeed(product, barcode: "")
                        barcodeIngredients = product.ingredients
                        photoStatus = "Exact product match: \(product.displayName) — full nutrition from Open Food Facts. Review and log it."
                        showBarcodeReview = true
                    } else {
                        identifyFromLabels(detections)
                    }
                }
            } else {
                identifyFromLabels(detections)
            }
        }
        #else
        isAnalyzing = false
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
    @State private var servings: Double = 1
    var body: some View {
        NavigationStack {
            ScrollView { VStack(spacing: 14) {
                Text("Type what's on the label — or your best estimate. Estimates beat skipping a log, every time.")
                    .font(.subheadline).foregroundStyle(WCTheme.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
                field("FOOD NAME", placeholder: "e.g. 4oz chicken breast", text: $name, keyboard: .default)
                field("CALORIES", placeholder: "e.g. 165", text: $calories)
                HStack(spacing: 12) { field("PROTEIN (G)", placeholder: "31", text: $protein); field("CARBS (G)", placeholder: "0", text: $carbs) }
                HStack(spacing: 12) { field("FAT (G)", placeholder: "4", text: $fat); field("SODIUM (MG)", placeholder: "75", text: $sodium) }
                HStack(spacing: 12) {
                    Text("AMOUNT (SERVINGS)").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                    Spacer()
                    BigRoundButton(systemImage: "minus") { servings = max(0.5, servings - 0.5) }
                    Text("\(String(format: servings.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", servings))×").font(.title3.weight(.black)).foregroundStyle(WCTheme.gold).frame(minWidth: 52)
                    BigRoundButton(systemImage: "plus") { servings = min(6, servings + 0.5) }
                }.wcCard()
                WCGradientButton(title: "Add to \(mealType)") {
                    guard !name.isEmpty, let cal = Int(calories) else { return }
                    onSave(ManualEntry(name: servings == 1 ? name : "\(name) ×\(String(format: "%.1f", servings))", calories: Int((Double(cal) * servings).rounded()), protein: (Double(protein) ?? 0) * servings, carbs: (Double(carbs) ?? 0) * servings, fat: (Double(fat) ?? 0) * servings, sodium: (Double(sodium) ?? 0) * servings, mealType: mealType))
                    dismiss()
                }
            }.padding() }
            .wcBackground().keyboardDoneBar().scrollDismissesKeyboard(.interactively).navigationTitle("Manual Entry").navigationBarTitleDisplayMode(.inline)
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


/// Real camera capture for food photos. Falls back to the photo library when no camera exists (e.g. Simulator).
struct CameraPicker: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void
    var onCancel: () -> Void
    var onUnavailable: () -> Void
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            picker.sourceType = .photoLibrary
            DispatchQueue.main.async { onUnavailable() }
        }
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick, onCancel: onCancel) }
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onPick: (UIImage) -> Void; var onCancel: () -> Void
        init(onPick: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) { self.onPick = onPick; self.onCancel = onCancel }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage) { onPick(image) } else { onCancel() }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onCancel() }
    }
}

/// Auto-fill review sheet shown after a photo scan (camera or gallery).
/// The AI fills name, serving, calories and macros from its best match — every value stays editable,
/// the amount (servings) scales everything live, and nothing is logged until the athlete taps Log.
struct ScanReviewView: View {
    var image: UIImage?
    var labels: [String]
    var matches: [FoodItem]
    var initialMeal: String
    var prefillFood: FoodItem? = nil
    var ingredients: String = ""
    var onLog: (_ name: String, _ serving: String, _ calories: Int, _ protein: Double, _ carbs: Double, _ fat: Double, _ sodium: Double, _ meal: String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var serving = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var sodium = ""
    @State private var servings: Double = 1
    @State private var meal = "Snack"
    @State private var selectedMatchID: String?
    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]

    private var totalCal: Int { Int(((Double(calories) ?? 0) * servings).rounded()) }

    var body: some View {
        NavigationStack {
            ScrollView { VStack(spacing: 14) {
                if let image { Image(uiImage: image).resizable().scaledToFill().frame(maxWidth: .infinity).frame(height: 170).clipped().clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) }
                if !labels.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AI SEES").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                        Text(labels.prefix(4).joined(separator: " • ")).font(.subheadline.weight(.bold)).foregroundStyle(WCTheme.gold)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                if !ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("INGREDIENTS (FROM DATABASE)").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                        Text(ingredients).font(.caption).foregroundStyle(WCTheme.textSecondary).lineLimit(6)
                    }.frame(maxWidth: .infinity, alignment: .leading).wcCard()
                }
                if !matches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BEST MATCHES — TAP TO AUTO-FILL").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                        ForEach(matches) { food in
                            Button { fill(from: food) } label: {
                                HStack { Text(food.displayName).fontWeight(.semibold).foregroundStyle(.white); Spacer(); Text("\(food.calories) cal").fontWeight(.black).foregroundStyle(WCTheme.gold) }
                                    .frame(maxWidth: .infinity, minHeight: 50).padding(.horizontal, 12)
                                    .background(selectedMatchID == food.id ? WCTheme.red.opacity(0.3) : WCTheme.surface2)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }.wcCard()
                }
                group("FOOD NAME") { TextField("e.g. Grilled Chicken Breast", text: $name).font(.title3.weight(.bold)).frame(minHeight: 44) }
                group("SERVING SIZE") { TextField("e.g. 4 oz breast, 100g rice", text: $serving).font(.title3.weight(.bold)).frame(minHeight: 44) }
                HStack(spacing: 12) { numField("CALORIES", $calories, "185"); numField("PROTEIN (G)", $protein, "31") }
                HStack(spacing: 12) { numField("CARBS (G)", $carbs, "0"); numField("FAT (G)", $fat, "4") }
                numField("SODIUM (MG)", $sodium, "75")
                HStack(spacing: 12) {
                    Text("AMOUNT").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                    Spacer()
                    BigRoundButton(systemImage: "minus") { servings = max(0.5, servings - 0.5) }
                    Text("\(String(format: servings.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", servings))×").font(.title3.weight(.black)).foregroundStyle(WCTheme.gold).frame(minWidth: 52)
                    BigRoundButton(systemImage: "plus") { servings = min(6, servings + 0.5) }
                }.wcCard()
                VStack(alignment: .leading, spacing: 8) {
                    Text("MEAL").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                    HStack(spacing: 8) {
                        ForEach(mealTypes, id: \.self) { m in
                            Button(m) { meal = m }.font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(meal == m ? WCTheme.red : WCTheme.surface2).foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }.wcCard()
                Text("Total with amount: \(totalCal) cal — check the numbers, fix anything, then log.").font(.caption).foregroundStyle(WCTheme.textTertiary)
                WCGradientButton(title: "LOG THIS FOOD") {
                    guard !name.isEmpty else { return }
                    onLog(name, serving, totalCal, (Double(protein) ?? 0) * servings, (Double(carbs) ?? 0) * servings, (Double(fat) ?? 0) * servings, (Double(sodium) ?? 0) * servings, meal)
                    dismiss()
                }
            }.padding() }
            .wcBackground().keyboardDoneBar().scrollDismissesKeyboard(.interactively)
            .navigationTitle("Review Scan").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear {
                meal = initialMeal
                if let prefillFood { fill(from: prefillFood) }
                else if let first = matches.first { fill(from: first) }
                else if let label = labels.first { name = label.capitalized }
            }
        }.preferredColorScheme(.dark)
    }

    private func fill(from food: FoodItem) {
        selectedMatchID = food.id
        name = food.displayName
        serving = food.serving
        calories = String(food.calories)
        protein = String(Int(food.proteinG))
        carbs = String(Int(food.carbsG))
        fat = String(Int(food.fatG))
        sodium = String(Int(food.sodiumMg))
    }
    private func group(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) { Text(title).font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary); content() }
            .frame(maxWidth: .infinity, alignment: .leading).wcCard()
    }
    private func numField(_ title: String, _ text: Binding<String>, _ placeholder: String) -> some View {
        group(title) { TextField(placeholder, text: text).keyboardType(.decimalPad).font(.title3.weight(.bold)).frame(minHeight: 44) }
    }
}


/// Edit or delete any logged food. Opened by tapping a log row (Food tab or Meals timeline).
struct EditLogView: View {
    var entry: FoodLogEntry
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""; @State private var calories = ""; @State private var protein = ""; @State private var carbs = ""; @State private var fat = ""; @State private var sodium = ""
    @State private var meal = "Snack"; @State private var date = Date.now
    @State private var confirmDelete = false
    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    var body: some View {
        NavigationStack {
            ScrollView { VStack(spacing: 14) {
                fieldGroup("FOOD NAME") { TextField("Food name", text: $name).font(.title3.weight(.bold)).frame(minHeight: 44) }
                HStack(spacing: 12) { numGroup("CALORIES", $calories); numGroup("PROTEIN (G)", $protein) }
                HStack(spacing: 12) { numGroup("CARBS (G)", $carbs); numGroup("FAT (G)", $fat) }
                numGroup("SODIUM (MG)", $sodium)
                VStack(alignment: .leading, spacing: 8) {
                    Text("MEAL").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                    HStack(spacing: 8) { ForEach(mealTypes, id: \.self) { m in Button(m) { meal = m }.font(.subheadline.weight(.bold)).frame(maxWidth: .infinity, minHeight: 48).background(meal == m ? WCTheme.red : WCTheme.surface2).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)) } }
                }.wcCard()
                VStack(alignment: .leading, spacing: 8) {
                    Text("DAY").font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary)
                    DatePicker("Logged on", selection: $date, displayedComponents: .date).font(.title3.weight(.semibold)).frame(minHeight: 52)
                }.wcCard()
                WCGradientButton(title: "SAVE CHANGES") { save(); dismiss() }
                Button(role: .destructive) { confirmDelete = true } label: { Label("Delete This Food", systemImage: "trash.fill").font(.headline.weight(.black)).frame(maxWidth: .infinity, minHeight: 56) }
                    .buttonStyle(.bordered).tint(.red)
            }.padding() }
            .wcBackground().keyboardDoneBar().scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Food").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .confirmationDialog("Delete this food from your log?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { context.delete(entry); try? context.save(); dismiss() }
                Button("Keep It", role: .cancel) {}
            }
            .onAppear {
                name = entry.foodName; calories = String(entry.calories); protein = String(Int(entry.proteinG)); carbs = String(Int(entry.carbsG)); fat = String(Int(entry.fatG)); sodium = String(Int(entry.sodiumMg)); meal = entry.mealType; date = entry.date
            }
        }.preferredColorScheme(.dark)
    }
    private func save() {
        entry.foodName = name
        entry.calories = Int(calories) ?? entry.calories
        entry.proteinG = Double(protein) ?? entry.proteinG
        entry.carbsG = Double(carbs) ?? entry.carbsG
        entry.fatG = Double(fat) ?? entry.fatG
        entry.sodiumMg = Double(sodium) ?? entry.sodiumMg
        entry.mealType = meal
        // Keep the time of day, move to the chosen day.
        let cal = Calendar.current
        let time = cal.dateComponents([.hour, .minute, .second], from: entry.date)
        entry.date = cal.date(bySettingHour: time.hour ?? 12, minute: time.minute ?? 0, second: 0, of: date) ?? date
        try? context.save()
    }
    private func fieldGroup(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) { Text(title).font(.caption.weight(.black)).foregroundStyle(WCTheme.textSecondary); content() }
            .frame(maxWidth: .infinity, alignment: .leading).wcCard()
    }
    private func numGroup(_ title: String, _ text: Binding<String>) -> some View {
        fieldGroup(title) { TextField("0", text: text).keyboardType(.decimalPad).font(.title3.weight(.bold)).frame(minHeight: 44) }
    }
}
