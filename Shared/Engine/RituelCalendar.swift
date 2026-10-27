import Foundation

/// Plage de jours inclusive, chaque borne normalisée à minuit.
struct DayRange: Hashable, Sendable {
    let first: Date
    let last: Date
}

/// Calendrier de Rituel : semaine du lundi au dimanche, mois civil, fuseau local.
struct RituelCalendar: Sendable {
    let calendar: Calendar

    static let weekdayLetters = ["L", "M", "M", "J", "V", "S", "D"]

    init(timeZone: TimeZone = .current) {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        c.timeZone = timeZone
        c.locale = .rituel
        calendar = c
    }

    static var current: RituelCalendar { RituelCalendar() }

    func day(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func adding(days: Int, to date: Date) -> Date {
        // Ajouter des jours (et non 24 h) garde minuit même lors d'un changement d'heure.
        day(calendar.date(byAdding: .day, value: days, to: day(date)) ?? date)
    }

    func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    func monday(of date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date) // 1 = dimanche
        return adding(days: -((weekday + 5) % 7), to: date)
    }

    func range(_ period: HabitPeriod, containing date: Date) -> DayRange {
        switch period {
        case .day:
            let d = day(date)
            return DayRange(first: d, last: d)
        case .week:
            let m = monday(of: date)
            return DayRange(first: m, last: adding(days: 6, to: m))
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: date)
            let first = day(calendar.date(from: comps) ?? date)
            return DayRange(first: first, last: adding(days: daysInMonth(of: date) - 1, to: first))
        }
    }

    func days(in range: DayRange) -> [Date] {
        var result: [Date] = []
        var d = range.first
        while d <= range.last {
            result.append(d)
            d = adding(days: 1, to: d)
        }
        return result
    }

    /// Nombre de jours de `from` à `to` inclus.
    func dayCount(from: Date, to: Date) -> Int {
        (calendar.dateComponents([.day], from: day(from), to: day(to)).day ?? 0) + 1
    }

    func daysInMonth(of date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    func dayOfMonth(_ date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    func hour(_ date: Date) -> Int {
        calendar.component(.hour, from: date)
    }

    func isoWeek(_ date: Date) -> Int {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = calendar.timeZone
        return iso.component(.weekOfYear, from: date)
    }

    // MARK: Textes de dates

    private func style() -> Date.FormatStyle {
        Date.FormatStyle(date: .omitted, time: .omitted, locale: .rituel, calendar: calendar, timeZone: calendar.timeZone)
    }

    /// « lundi 26 octobre »
    func longDate(_ date: Date) -> String {
        date.formatted(style().weekday(.wide).day().month(.wide))
    }

    /// « 26 oct. »
    func shortDate(_ date: Date) -> String {
        date.formatted(style().day().month(.abbreviated))
    }

    /// « octobre »
    func monthName(_ date: Date) -> String {
        date.formatted(style().month(.wide))
    }
}

extension Locale {
    /// L'interface est en français : les dates aussi, quelle que soit la langue de l'appareil.
    static let rituel = Locale(identifier: "fr_FR")
}
