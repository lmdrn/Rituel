import Foundation
import UserNotifications

/// Programme les rappels locaux à partir des habitudes et de ce qui a déjà été noté.
enum ReminderScheduler {
    static var isEnabled: Bool {
        // Activés par défaut : l'interrupteur des réglages n'a encore jamais été touché.
        SharedDefaults.store.object(forKey: SharedDefaults.remindersEnabledKey) as? Bool ?? true
    }

    /// Demande la permission la première fois qu'un rappel est activé. Renvoie `true` si les notifications sont permises.
    @discardableResult
    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    /// Remplace tous les rappels en attente par ceux des 7 prochains jours.
    @MainActor
    static func sync(now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(ReminderPlanner.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        guard isEnabled else { return }
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: break
        default: return
        }

        let (specs, log) = WidgetDataLoader.specsAndLog(at: now)
        let data = WidgetData.build(specs: specs, log: log, today: now)
        let withReminder = data.habits.filter { $0.spec.reminderMinutes != nil }

        // Une catégorie par habitude, pour un bouton d'action à son nom (« Fait », « +250 ml »).
        center.setNotificationCategories(Set(withReminder.map { habit in
            UNNotificationCategory(
                identifier: ReminderPlanner.categoryID(for: habit.id),
                actions: [UNNotificationAction(identifier: ReminderPlanner.logActionID,
                                               title: ReminderPlanner.actionTitle(for: habit.spec, quick: habit.quick))],
                intentIdentifiers: []
            )
        }))

        let quick = Dictionary(uniqueKeysWithValues: withReminder.map { ($0.id, $0.quick.action) })
        for reminder in ReminderPlanner.plan(specs, log: log, now: now) {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            content.categoryIdentifier = reminder.categoryID
            content.threadIdentifier = reminder.habitID.uuidString
            content.userInfo = LogHabitIntent(habitID: reminder.habitID, action: quick[reminder.habitID] ?? .increment).userInfo
            let components = log.calendar.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
            let request = UNNotificationRequest(identifier: reminder.id, content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
            try? await center.add(request)
        }
    }
}

extension LogHabitIntent {
    /// Ce qu'emporte une notification pour noter depuis son bouton d'action.
    var userInfo: [String: Any] {
        ["habitID": habitID, "kind": kind, "value": value]
    }

    init?(userInfo: [AnyHashable: Any]) {
        guard let id = userInfo["habitID"] as? String, let uuid = UUID(uuidString: id) else { return nil }
        self.init()
        habitID = uuid.uuidString
        kind = userInfo["kind"] as? String ?? "increment"
        value = userInfo["value"] as? Double ?? 1
    }
}
