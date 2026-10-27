import SwiftData
import SwiftUI
import UserNotifications

@main
struct RituelApp: App {
    private let container: ModelContainer

    init() {
        // Tôt, pour recevoir les actions des notifications même quand l'app est lancée par l'une d'elles.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        #if DEBUG
        // Pour les captures : `-RituelSampleData` lance l'app sur les données d'exemple, en mémoire.
        if ProcessInfo.processInfo.arguments.contains("-RituelSampleData") {
            container = PreviewData.container
            return
        }
        #endif
        container = RituelStore.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
