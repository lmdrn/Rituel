import AppIntents
import WidgetKit

struct RituelEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
    /// Habitude choisie pour les widgets configurables.
    var habitID: UUID?
}

/// Choix de l'habitude pour le petit widget et l'écran verrouillé.
struct SelectHabitIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choisir une habitude"
    static let description = IntentDescription("L'habitude affichée par le widget.")

    @Parameter(title: "Habitude")
    var habit: HabitEntity?
}

enum RituelTimeline {
    /// Une entrée maintenant et une à minuit, pour changer de jour même si l'app n'a pas été ouverte.
    static func entries(habitID: UUID? = nil, now: Date = .now) -> [RituelEntry] {
        let calendar = RituelCalendar.current
        let midnight = calendar.adding(days: 1, to: now)
        return [now, midnight].map { RituelEntry(date: $0, data: WidgetDataLoader.load(at: $0, calendar: calendar), habitID: habitID) }
    }

    static func placeholder() -> RituelEntry {
        RituelEntry(date: .now, data: .sample)
    }
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> RituelEntry { RituelTimeline.placeholder() }

    func getSnapshot(in context: Context, completion: @escaping (RituelEntry) -> Void) {
        completion(context.isPreview ? RituelTimeline.placeholder() : RituelTimeline.entries()[0])
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RituelEntry>) -> Void) {
        completion(Timeline(entries: RituelTimeline.entries(), policy: .atEnd))
    }
}

struct HabitProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> RituelEntry { RituelTimeline.placeholder() }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> RituelEntry {
        if context.isPreview { return RituelTimeline.placeholder() }
        return RituelTimeline.entries(habitID: configuration.habit?.id)[0]
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<RituelEntry> {
        Timeline(entries: RituelTimeline.entries(habitID: configuration.habit?.id), policy: .atEnd)
    }
}

extension WidgetData {
    /// Données d'exemple pour la galerie de widgets et les previews.
    static var sample: WidgetData {
        let cal = RituelCalendar.current
        let today = cal.day(.now)
        let specs = DefaultHabits.specs
        let records = [
            EntryRecord(habitID: specs[0].id, day: today, value: 7.5),
            EntryRecord(habitID: specs[1].id, day: today, value: 1250),
            EntryRecord(habitID: specs[2].id, day: today, value: 1),
            EntryRecord(habitID: specs[4].id, day: cal.monday(of: today), value: 1),
        ]
        return build(specs: specs, log: EntryLog(records, calendar: cal), today: today)
    }
}
