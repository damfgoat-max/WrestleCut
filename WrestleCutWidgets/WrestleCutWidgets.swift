import WidgetKit
import SwiftUI

// MARK: - Data (snapshot published by the app into the shared App Group)

struct CutEntry: TimelineEntry {
    var date: Date
    var hasData: Bool = false
    var currentWeight: Double = 160
    var startWeight: Double = 168
    var goalWeight: Double = 152
    var daysLeft: Int = 21
    var calories: Int = 0
    var calorieGoal: Int = 2100
    var waterML: Int = 0
    var waterGoal: Int = 3000
    var sodiumMg: Double = 0
    var sodiumLimit: Int = 2600
    var progress: Double {
        let total = startWeight - goalWeight
        guard total > 0 else { return 1 }
        return min(1, max(0, (startWeight - currentWeight) / total))
    }
}

struct Provider: TimelineProvider {
    private func read() -> CutEntry {
        var e = CutEntry(date: .now)
        guard let d = UserDefaults(suiteName: "group.com.wrestlecut.app"), d.object(forKey: "snap_updatedAt") != nil else { return e }
        e.hasData = true
        e.currentWeight = d.double(forKey: "snap_currentWeight")
        e.startWeight = d.double(forKey: "snap_startWeight")
        e.goalWeight = d.double(forKey: "snap_goalWeight")
        e.daysLeft = d.integer(forKey: "snap_daysLeft")
        e.calories = d.integer(forKey: "snap_calories")
        e.calorieGoal = d.integer(forKey: "snap_calorieGoal")
        e.waterML = d.integer(forKey: "snap_waterML")
        e.waterGoal = d.integer(forKey: "snap_waterGoal")
        e.sodiumMg = d.double(forKey: "snap_sodiumMg")
        e.sodiumLimit = d.integer(forKey: "snap_sodiumLimit")
        return e
    }
    func placeholder(in context: Context) -> CutEntry { CutEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (CutEntry) -> Void) { completion(read()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CutEntry>) -> Void) {
        let entry = read()
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(24 * 3600 + 60)
        var nextDay = entry
        nextDay.date = midnight
        // Background refresh: iOS re-asks for a timeline ~30 min later even without the app,
        // and every in-app change also calls reloadTimelines(ofKind:) for an instant update.
        let refresh = Date.now.addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry, nextDay], policy: .after(refresh)))
    }
}

// MARK: - Design

private let wcRed = Color(red: 0.87, green: 0.10, blue: 0.17)
private let wcGold = Color(red: 1.0, green: 0.78, blue: 0.17)
private let wcBG = Color(red: 0.05, green: 0.04, blue: 0.06)
private let wcDim = Color(white: 0.65)

private func bar(_ fraction: Double, _ color: Color) -> some View {
    GeometryReader { geo in
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.14))
            Capsule().fill(color).frame(width: max(4, geo.size.width * min(1, max(0, fraction))))
        }
    }.frame(height: 7)
}

private func brandRow(_ e: CutEntry) -> some View {
    HStack(spacing: 6) {
        ZStack { Circle().stroke(wcRed, lineWidth: 2.5); Text("W").font(.system(size: 9, weight: .black)).foregroundStyle(wcGold) }.frame(width: 18, height: 18)
        Text("WRESTLE CUT").font(.system(size: 11, weight: .black)).foregroundStyle(.white)
        Spacer()
        if e.hasData { Text("\(e.daysLeft)d left").font(.system(size: 11, weight: .bold)).foregroundStyle(wcGold) }
    }
}

struct SmallView: View {
    var e: CutEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            brandRow(e)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", e.currentWeight)).font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(.white)
                Text("lb").foregroundStyle(wcDim).font(.caption.weight(.bold))
            }
            Text("Goal \(String(format: "%.0f", e.goalWeight)) lb • \(String(format: "%.1f", max(0, e.currentWeight - e.goalWeight))) to go").font(.caption.weight(.semibold)).foregroundStyle(wcDim)
            bar(e.progress, wcRed)
            Text("\(Int(e.progress * 100))% of the cut done").font(.caption2.weight(.bold)).foregroundStyle(wcGold)
            if !e.hasData { Text("Open the app once to sync").font(.caption2).foregroundStyle(wcDim) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(4)
        .containerBackground(wcBG, for: .widget)
    }
}

struct MediumView: View {
    var e: CutEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            brandRow(e)
            HStack(spacing: 6) {
                Text("\(max(0, e.calorieGoal - e.calories))").font(.system(size: 20, weight: .black, design: .rounded)).foregroundStyle(wcGold)
                Text("cal left today").font(.caption.weight(.bold)).foregroundStyle(wcDim)
                Spacer()
                Text("💧 \(e.waterML) ml").font(.caption.weight(.black)).foregroundStyle(.cyan)
            }
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(String(format: "%.1f", e.currentWeight)).font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(.white)
                        Text("lb").foregroundStyle(wcDim).font(.caption.weight(.bold))
                    }
                    Text("Goal \(String(format: "%.0f", e.goalWeight)) • \(Int(e.progress * 100))% there").font(.caption.weight(.semibold)).foregroundStyle(wcDim)
                    bar(e.progress, wcRed).frame(width: 120)
                }
                VStack(alignment: .leading, spacing: 7) {
                    statRow("Calories", "\(e.calories)/\(e.calorieGoal)", Double(e.calories) / Double(max(1, e.calorieGoal)), wcRed)
                    statRow("Water", "\(e.waterML)/\(e.waterGoal) ml", Double(e.waterML) / Double(max(1, e.waterGoal)), .cyan)
                    statRow("Sodium", "\(Int(e.sodiumMg))/\(e.sodiumLimit) mg", e.sodiumMg / Double(max(1, e.sodiumLimit)), .orange)
                }.frame(maxWidth: .infinity)
            }
            if !e.hasData { Text("Open Wrestle Cut once and your live numbers appear here.").font(.caption2).foregroundStyle(wcDim) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(4)
        .containerBackground(wcBG, for: .widget)
    }
    private func statRow(_ label: String, _ value: String, _ fraction: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack { Text(label.uppercased()).font(.system(size: 9, weight: .black)).foregroundStyle(wcDim); Spacer(); Text(value).font(.system(size: 10, weight: .bold)).foregroundStyle(.white) }
            bar(fraction, color)
        }
    }
}

struct WidgetEntryView: View {
    var entry: CutEntry
    var body: some View { LiveEntryView(entry: entry) }
}

/// Live view: binds straight to the App Group store with @AppStorage, so whenever the app
/// writes new numbers (and WidgetKit reloads), the freshest values render — no stale entry data.
struct LiveEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: CutEntry
    private static let suite = UserDefaults(suiteName: "group.com.wrestlecut.app")
    @AppStorage("snap_currentWeight", store: suite) private var w: Double = -1
    @AppStorage("snap_startWeight", store: suite) private var sw: Double = -1
    @AppStorage("snap_goalWeight", store: suite) private var gw: Double = -1
    @AppStorage("snap_daysLeft", store: suite) private var dl: Int = -1
    @AppStorage("snap_calories", store: suite) private var cal: Int = -1
    @AppStorage("snap_calorieGoal", store: suite) private var calG: Int = -1
    @AppStorage("snap_waterML", store: suite) private var wat: Int = -1
    @AppStorage("snap_waterGoal", store: suite) private var watG: Int = -1
    @AppStorage("snap_sodiumMg", store: suite) private var sod: Double = -1
    @AppStorage("snap_sodiumLimit", store: suite) private var sodL: Int = -1
    @AppStorage("snap_updatedAt", store: suite) private var upd: Double = 0
    private var live: CutEntry {
        var e = entry
        guard upd > 0 else { return e }
        e.hasData = true
        if w >= 0 { e.currentWeight = w }
        if sw >= 0 { e.startWeight = sw }
        if gw >= 0 { e.goalWeight = gw }
        if dl >= 0 { e.daysLeft = dl }
        if cal >= 0 { e.calories = cal }
        if calG >= 0 { e.calorieGoal = calG }
        if wat >= 0 { e.waterML = wat }
        if watG >= 0 { e.waterGoal = watG }
        if sod >= 0 { e.sodiumMg = sod }
        if sodL >= 0 { e.sodiumLimit = sodL }
        return e
    }
    var body: some View {
        switch family {
        case .systemLarge: LargeView(e: live)
        case .systemMedium: MediumView(e: live)
        default: SmallView(e: live)
        }
    }
}

struct LargeView: View {
    var e: CutEntry
    private var nextMeal: (name: String, hint: String) {
        let h = Calendar.current.component(.hour, from: e.date)
        switch h {
        case ..<10: return ("Breakfast", "Log it right after you eat — eggs, oats, Greek yogurt.")
        case 10..<15: return ("Lunch", "Chicken and rice territory — keep the protein high.")
        case 15..<21: return ("Dinner", "Lean protein, smart carbs, watch the sodium.")
        default: return ("Breakfast tomorrow", "Prep tonight so the morning runs itself.")
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            brandRow(e)
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(String(format: "%.1f", e.currentWeight)).font(.system(size: 38, weight: .black, design: .rounded)).foregroundStyle(.white)
                        Text("lb").foregroundStyle(wcDim).font(.caption.weight(.bold))
                    }
                    Text("Goal \(String(format: "%.0f", e.goalWeight)) lb • \(String(format: "%.1f", max(0, e.currentWeight - e.goalWeight))) to go").font(.subheadline.weight(.semibold)).foregroundStyle(wcDim)
                    bar(e.progress, wcRed)
                    Text("\(Int(e.progress * 100))% of the cut done • \(e.daysLeft) days to weigh-ins").font(.caption.weight(.bold)).foregroundStyle(wcGold)
                }.frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 9) {
                    bigStat("CALORIES LEFT", "\(max(0, e.calorieGoal - e.calories))", "of \(e.calorieGoal) goal • ate \(e.calories)", wcGold, Double(e.calories) / Double(max(1, e.calorieGoal)), wcRed)
                    bigStat("WATER TODAY", "\(e.waterML) ml", "goal \(e.waterGoal) ml", .cyan, Double(e.waterML) / Double(max(1, e.waterGoal)), .cyan)
                    bigStat("SODIUM", "\(Int(e.sodiumMg)) mg", "limit \(e.sodiumLimit) mg", .orange, e.sodiumMg / Double(max(1, e.sodiumLimit)), .orange)
                }.frame(maxWidth: .infinity)
            }
            HStack(spacing: 10) {
                Image(systemName: "fork.knife.circle.fill").font(.title2).foregroundStyle(wcRed)
                VStack(alignment: .leading, spacing: 1) {
                    Text("NEXT MEAL: \(nextMeal.name.uppercased())").font(.caption.weight(.black)).foregroundStyle(.white)
                    Text(nextMeal.hint).font(.caption).foregroundStyle(wcDim)
                }
                Spacer()
            }
            .padding(10)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            if !e.hasData { Text("Open Wrestle Cut once and your live numbers appear here.").font(.caption2).foregroundStyle(wcDim) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(4)
        .containerBackground(wcBG, for: .widget)
    }
    private func bigStat(_ label: String, _ value: String, _ sub: String, _ valueColor: Color, _ fraction: Double, _ barColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 9, weight: .black)).foregroundStyle(wcDim)
            HStack(alignment: .firstTextBaseline, spacing: 6) { Text(value).font(.system(size: 19, weight: .black, design: .rounded)).foregroundStyle(valueColor); Text(sub).font(.system(size: 10)).foregroundStyle(wcDim) }
            bar(fraction, barColor)
        }
    }
}

struct WrestleCutWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WrestleCutWidget", provider: Provider()) { entry in WidgetEntryView(entry: entry) }
            .configurationDisplayName("Wrestle Cut")
            .description("Your cut at a glance: weight progress, calories, water and sodium.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct WrestleCutWidgets: WidgetBundle {
    var body: some Widget { WrestleCutWidget() }
}
