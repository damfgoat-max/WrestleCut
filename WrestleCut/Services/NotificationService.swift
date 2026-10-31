import Foundation
import UserNotifications

/// Smart local reminders for the cut. Everything is scheduled on-device with UserNotifications —
/// meal logging nudges, water reminders, the morning weigh-in, and weigh-in day alerts.
/// All times and toggles live in the More tab; UserDefaults keys are prefixed "wcNotif".
enum NotificationService {
    private static let idPrefix = "wc."

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    private static func minutes(_ d: UserDefaults, _ key: String, _ fallback: Int) -> Int {
        d.object(forKey: key) == nil ? fallback : d.integer(forKey: key)
    }

    /// Rebuilds the whole reminder schedule from the saved preferences. Safe to call often.
    static func sync(profile: UserProfile?) {
        let d = UserDefaults.standard
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            center.removePendingNotificationRequests(withIdentifiers: requests.map(\.identifier).filter { $0.hasPrefix(idPrefix) })
        }
        guard d.bool(forKey: "wcNotifEnabled") else { return }

        if d.bool(forKey: "wcNotifBreakfast") {
            addDaily(id: "breakfast", title: "Time to log breakfast 🍳", body: "Fuel the cut and hit your protein early. Snap it, scan it, log it.", minutes: minutes(d, "wcNotifBreakfastMin", 450))
        }
        if d.bool(forKey: "wcNotifLunch") {
            addDaily(id: "lunch", title: "Log your lunch 🥗", body: "Two minutes now keeps the whole day honest. Chicken and rice never misses.", minutes: minutes(d, "wcNotifLunchMin", 750))
        }
        if d.bool(forKey: "wcNotifDinner") {
            addDaily(id: "dinner", title: "Log dinner 🌙", body: "Close the day strong: log dinner and check your sodium before bed.", minutes: minutes(d, "wcNotifDinnerMin", 1110))
        }
        if d.bool(forKey: "wcNotifMorning") {
            addDaily(id: "morning", title: "Morning weigh-in ⚖️", body: "Same time every day: after the bathroom, before food. Log it and watch the trend.", minutes: minutes(d, "wcNotifMorningMin", 420))
        }
        if d.bool(forKey: "wcNotifWater") {
            for (i, m) in [600, 840, 1020, 1200].enumerated() {
                addDaily(id: "water\(i)", title: "Drink water 💧", body: "Sip, don't chug. Steady water all day beats a flood at night.", minutes: m)
            }
        }
        if d.bool(forKey: "wcNotifWeighIn"), let profile {
            let cal = Calendar.current
            let weighDay = cal.startOfDay(for: profile.weighInDate)
            if let dayBefore = cal.date(byAdding: .day, value: -1, to: weighDay) {
                addOnce(id: "weighin-eve", title: "Weigh-ins tomorrow ⚖️", body: "Light dinner, water taper as planned, scale and singlet ready. You've done the work.", date: dayBefore, hour: 20, minute: 0)
            }
            addOnce(id: "weighin-day", title: "WEIGH-IN DAY 🏆", body: "Step on, make weight, then run the Recovery protocol in the app. Let's go.", date: weighDay, hour: 7, minute: 0)
        }
    }

    private static func addDaily(id: String, title: String, body: String, minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.sound = .default
        var comps = DateComponents()
        comps.hour = minutes / 60; comps.minute = minutes % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: idPrefix + id, content: content, trigger: trigger))
    }

    private static func addOnce(id: String, title: String, body: String, date: Date, hour: Int, minute: Int) {
        guard date > Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now else { return }
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.sound = .default
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour; comps.minute = minute
        guard let fire = Calendar.current.date(from: comps), fire > .now else { return }
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: idPrefix + id, content: content, trigger: trigger))
    }
}
