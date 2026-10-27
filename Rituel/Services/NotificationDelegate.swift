import UserNotifications

/// Reçoit les actions des notifications de rappel (« Fait », « +250 ml ») et note sans ouvrir l'app.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, Sendable {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == ReminderPlanner.logActionID,
              let intent = LogHabitIntent(userInfo: response.notification.request.content.userInfo) else { return }
        _ = try? await intent.perform()
    }
}
