import SwiftData
import SwiftUI

@main
struct RituelApp: App {
    private let container: ModelContainer

    init() {
        #if DEBUG
        // Pour les captures : `-RituelSampleData` lance l'app sur les données d'exemple, en mémoire.
        if ProcessInfo.processInfo.arguments.contains("-RituelSampleData") {
            container = PreviewData.container
            return
        }
        #endif
        do {
            container = try RituelStore.makeContainer()
        } catch {
            fatalError("Impossible d'ouvrir la base Rituel : \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
