import SwiftUI
import WidgetKit

@main
struct RituelWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PlaceholderWidget()
    }
}

// Étape 1 : un widget minimal pour que l'extension compile. Remplacé à l'étape 6.
struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry { PlaceholderEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: .now)], policy: .never))
    }
}

struct PlaceholderWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "fr.rituel.placeholder", provider: PlaceholderProvider()) { _ in
            VStack(alignment: .leading, spacing: 8) {
                BrandMark(size: 32)
                Spacer()
                Text(verbatim: "Rituel")
                    .font(.rituelTitle)
                    .foregroundStyle(.ink)
                Text("Bientôt tes habitudes ici.")
                    .font(.rituelCallout)
                    .foregroundStyle(.ink2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(.surface, for: .widget)
        }
        .configurationDisplayName("Rituel")
        .description("Tes habitudes du jour.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    PlaceholderWidget()
} timeline: {
    PlaceholderEntry(date: .now)
}
