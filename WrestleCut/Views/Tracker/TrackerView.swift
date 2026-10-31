import SwiftUI
import SwiftData

struct TrackerView: View {
    var profile: UserProfile
    @Environment(\.modelContext) private var context
    @Query(sort:\FoodLogEntry.date, order:.reverse) private var logs: [FoodLogEntry]
    @Query(sort:\WorkoutEntry.date, order:.reverse) private var workouts: [WorkoutEntry]
    @State private var query = ""; @State private var showScanner = false; @State private var scannedCode: String?
    private var todayLogs: [FoodLogEntry] { logs.filter{Calendar.current.isDateInToday($0.date)} }
    private var totals: (cal:Int,p:Double,c:Double,f:Double) { todayLogs.reduce((0,0,0,0)){ ($0.0+$1.calories, $0.1+$1.proteinG, $0.2+$1.carbsG, $0.3+$1.fatG) } }
    private var burned: Int { workouts.filter{Calendar.current.isDateInToday($0.date)}.reduce(0){$0+$1.caloriesBurned} }
    private var targetCal: Int { CutCalculator.calorieTarget(profile: profile) + burned }
    private var results: [FoodItem] { FoodDatabase.foods(avoiding: profile.dislikedFoodIDs).filter{ query.isEmpty || $0.displayName.localizedCaseInsensitiveContains(query) || $0.barcode == query } }
    var body: some View {
        NavigationStack { ScrollView { VStack(spacing:16){
            VStack(spacing:10){ HStack{ Text("\(totals.cal)").font(.title.weight(.black)); Text("/ \(targetCal) cal today").foregroundStyle(WCTheme.textSecondary); Spacer(); if burned>0 { Text("+\(burned) from training").font(.caption.weight(.bold)).foregroundStyle(WCTheme.success) } }
                ProgressView(value: min(1, Double(totals.cal)/Double(max(1,targetCal)))).tint(WCTheme.red).scaleEffect(y:2)
                HStack(spacing:16){ Text("P \(Int(totals.p))g").foregroundStyle(WCTheme.red); Text("C \(Int(totals.c))g").foregroundStyle(WCTheme.gold); Text("F \(Int(totals.f))g").foregroundStyle(.cyan) }.font(.subheadline.weight(.bold))
            }.wcCard()
            HStack(spacing:10){
                Button{ showScanner = true } label:{ Label("Scan Barcode", systemImage:"barcode.viewfinder").frame(maxWidth:.infinity) }.buttonStyle(.borderedProminent).tint(WCTheme.red)
                Menu { Button("Wrestling Practice — 60 min"){ logWorkout("Wrestling Practice",60,600) }; Button("Lifting — 45 min"){ logWorkout("Weight Training",45,250) }; Button("Cardio — 30 min"){ logWorkout("Cardio",30,300) } } label:{ Label("Log Training", systemImage:"figure.wrestling") }.buttonStyle(.bordered).tint(WCTheme.gold)
            }
            if let scannedCode { Text("Scanned: \(scannedCode) — matched below if in database.").font(.caption).foregroundStyle(WCTheme.gold) }
            TextField("Search foods wrestlers actually eat…", text:$query).textFieldStyle(.roundedBorder)
            SectionHeader(title:"Quick Add", subtitle:"Tap to log instantly")
            ForEach(results){ food in Button{ add(food) } label:{ HStack{ VStack(alignment:.leading){ Text(food.displayName).fontWeight(.semibold).foregroundStyle(.white); Text("\(food.serving) • P\(Int(food.proteinG)) C\(Int(food.carbsG)) F\(Int(food.fatG))").font(.caption).foregroundStyle(WCTheme.textSecondary) }; Spacer(); Text("\(food.calories) cal").fontWeight(.black).foregroundStyle(WCTheme.gold); Image(systemName:"plus.circle.fill").foregroundStyle(WCTheme.red) }.wcCard() } }
            if !todayLogs.isEmpty { SectionHeader(title:"Today's Log"); ForEach(todayLogs){ log in HStack{ VStack(alignment:.leading){ Text(log.foodName).fontWeight(.semibold); Text(log.mealType).font(.caption).foregroundStyle(WCTheme.textSecondary) }; Spacer(); Text("\(log.calories) cal") }.wcCard() } }
            if todayLogs.isEmpty && query.isEmpty { EmptyState(icon:"fork.knife.circle", title:"Nothing logged yet", message:"Search above or scan a barcode. Fast logging = consistent cutting.") }
        }.padding() }.wcBackground().navigationTitle("Food Tracker")
        .sheet(isPresented:$showScanner){ BarcodeScannerView{ code in scannedCode = code; query = code; showScanner = false } }
        }
    }
    private func add(_ food: FoodItem){ context.insert(FoodLogEntry(foodName: food.displayName, brand: food.brand, calories: food.calories, proteinG: food.proteinG, carbsG: food.carbsG, fatG: food.fatG)); try? context.save() }
    private func logWorkout(_ kind:String,_ min:Int,_ cal:Int){ context.insert(WorkoutEntry(kind:kind, minutes:min, caloriesBurned:cal)); try? context.save() }
}

#if canImport(VisionKit)
import VisionKit
struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String)->Void
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(recognizedDataTypes: [.barcode()], qualityLevel: .balanced, recognizesMultipleItems: false, isHighFrameRateTrackingEnabled: false, isPinchToZoomEnabled: true, isGuidanceEnabled: true, isHighlightingEnabled: true)
        vc.delegate = context.coordinator; try? vc.startScanning(); return vc
    }
    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onScan:onScan) }
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onScan:(String)->Void; init(onScan:@escaping(String)->Void){self.onScan=onScan}
        func dataScanner(_ scanner: DataScannerViewController, didTapOn item: RecognizedItem) { if case .barcode(let b)=item { onScan(b.payloadStringValue ?? "") } }
        func dataScanner(_ scanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) { if let first=addedItems.first, case .barcode(let b)=first { onScan(b.payloadStringValue ?? "") } }
    }
}
#else
struct BarcodeScannerView: View { var onScan:(String)->Void; var body: some View { VStack(spacing:12){ Text("Barcode scanning needs a real device with VisionKit."); Button("Close"){ onScan("") } }.padding() } }
#endif
