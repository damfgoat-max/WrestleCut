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
        completion(Timeline(entries: [entry], policy: .after(midnight)))
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
    @Environment(\.widgetFamily) var family
    var entry: CutEntry
    var body: some View {
        switch family {
        case .systemMedium: MediumView(e: entry)
        default: SmallView(e: entry)
        }
    }
}

struct WrestleCutWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WrestleCutWidget", provider: Provider()) { entry in WidgetEntryView(entry: entry) }
            .configurationDisplayName("Wrestle Cut")
            .description("Your cut at a glance: weight progress, calories, water and sodium.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct WrestleCutWidgets: WidgetBundle {
    var body: some Widget { WrestleCutWidget() }
}
