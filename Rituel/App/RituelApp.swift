import SwiftData
import SwiftUI
import UIKit
import UserNotifications

@main
struct RituelApp: App {
    private let container: ModelContainer

    init() {
        // Tôt, pour recevoir les actions des notifications même quand l'app est lancée par l'une d'elles.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        Self.styleNavigationTitles()
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

    /// Grands titres en Outfit, comme le logotype ; ils suivent le Dynamic Type.
    private static func styleNavigationTitles() {
        let appearance = UINavigationBar.appearance()
        if let large = UIFont(name: RituelFontFace.title.rawValue, size: 34) {
            appearance.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large)]
        }
        if let inline = UIFont(name: RituelFontFace.titleMedium.rawValue, size: 17) {
            appearance.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: inline)]
        }
    }
}
