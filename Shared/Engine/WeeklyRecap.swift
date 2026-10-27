import Foundation

enum RecapState: Sendable {
    /// Tenu.
    case kept
    /// En cours (ou « en bonne voie » pour un mois).
    case progress
    /// À travailler.
    case work
}

struct RecapRow: Identifiable, Sendable {
    var id: UUID { habit.id }
    let habit: HabitSpec
    let state: RecapState
    /// Entre 0 et 1.
    let score: Double
    /// « 5/6 jours », « 2/3 ».
    let value: String
    let detail: String
    let tip: String?
}

struct WeekRecap: Sendable {
    let weekStart: Date
    let rows: [RecapRow]

    /// Score d'équilibre : moyenne des scores × 100, arrondi.
    var score: Int {
        guard !rows.isEmpty else { return 0 }
        return Int((rows.reduce(0) { $0 + $1.score } / Double(rows.count) * 100).rounded())
    }

    var kept: [RecapRow] { rows.filter { $0.state == .kept } }
    var inProgress: [RecapRow] { rows.filter { $0.state == .progress } }
    var toWork: [RecapRow] { rows.filter { $0.state == .work } }

    var title: String { RecapEngine.title(score: score) }
}

/// Case de la grille « Jour par jour ».
enum HeatCellState: Sendable {
    /// Jour tenu (habitudes quotidiennes).
    case ok
    /// Jour raté (habitudes quotidiennes).
    case over
    /// Quelque chose de noté, sans jugement (habitudes à la semaine ou au mois, objectif pas encore atteint).
    case hit
    case empty
    case future
}

extension RecapState {
    var word: String {
        switch self {
        case .kept: "tenu"
        case .progress: "en cours"
        case .work: "à travailler"
        }
    }
}

enum RecapEngine {
    static func heatCell(_ habit: HabitSpec, value: Double, day: Date, today: Date) -> HeatCellState {
        if day > today { return .future }
        guard habit.period == .day else { return value > 0 ? .hit : .empty }
        if habit.kind == .limit { return HabitEngine.isDayKept(habit, value: value) ? .ok : .over }
        if HabitEngine.isDayKept(habit, value: value) { return .ok }
        return value > 0 ? .hit : .empty
    }

    /// Consigne pour le modèle sur l'appareil : 3 ou 4 phrases douces à partir du récap.
    static func notePrompt(_ recap: WeekRecap, name: String, calendar: RituelCalendar) -> String {
        let who = name.trimmingCharacters(in: .whitespaces)
        let lines = recap.rows.map { row in
            "- \(row.habit.name) (\(HabitEngine.ruleText(row.habit))) : \(row.detail) [\(row.state.word)]"
        }.joined(separator: "\n")
        return """
        Tu écris pour \(who.isEmpty ? "une personne" : who), qui suit ses habitudes pour avoir une routine et baisser son anxiété. \
        Voici son récap de la semaine du \(calendar.shortDate(recap.weekStart)) (score d'équilibre \(recap.score) %) :
        \(lines)

        Écris-lui 3 ou 4 phrases en français, en la tutoyant. Ton doux, bienveillant, concret, jamais culpabilisant. \
        Salue une réussite précise, propose une seule petite action pour la semaine suivante. \
        Pas de liste, pas d'emoji, pas de tiret cadratin, pas de titre. Réponds uniquement avec le texte.
        """
    }

    /// Nettoie la réponse du modèle : pas de tiret cadratin, pas d'espaces superflus.
    static func cleanNote(_ text: String) -> String {
        text.replacingOccurrences(of: " — ", with: ", ")
            .replacingOccurrences(of: "—", with: ",")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static let limitTips = [
        "Repère le moment où l'envie arrive et prépare une alternative à portée de main.",
        "Décide à l'avance du jour où tu te l'accordes, ça le rend plus savoureux.",
        "Note ce que tu ressens juste avant. Souvent c'est de la fatigue, pas de la faim.",
        "Rends-le un peu moins accessible : un détour, un autre trajet, un autre café.",
    ]
    static let goalTips = [
        "Bloque des créneaux précis dans ton agenda dès lundi, comme un rendez-vous.",
        "Commence plus petit : dix minutes comptent, l'important c'est de cocher.",
        "Associe-le à une habitude que tu as déjà, juste après le café du matin par exemple.",
        "Prépare tout la veille pour qu'il n'y ait plus qu'à y aller.",
    ]

    static func title(score: Int) -> String {
        switch score {
        case 85...: "Une semaine douce et tenue"
        case 60...: "Une belle semaine, avec de la marge"
        case 35...: "Une semaine en demi-teinte"
        default: "On repart en douceur"
        }
    }

    /// Conseil stable pour une habitude et une semaine données (pas de `hashValue`, qui change à chaque lancement).
    static func tip(for habit: HabitSpec, weekStart: Date, calendar: RituelCalendar) -> String {
        let list = habit.kind == .limit ? limitTips : goalTips
        let seed = habit.id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) } + calendar.isoWeek(weekStart)
        return list[seed % list.count]
    }

    static func recap(_ habits: [HabitSpec], weekStart: Date, log: EntryLog, today: Date) -> WeekRecap {
        let monday = log.calendar.monday(of: weekStart)
        return WeekRecap(weekStart: monday, rows: habits.compactMap { evaluate($0, weekStart: monday, log: log, today: today) })
    }

    /// Évalue une habitude sur la semaine du lundi `weekStart`, jusqu'à aujourd'hui si elle est en cours.
    static func evaluate(_ habit: HabitSpec, weekStart: Date, log: EntryLog, today rawToday: Date) -> RecapRow? {
        let cal = log.calendar
        let today = cal.day(rawToday)
        let monday = cal.monday(of: weekStart)
        guard monday <= today else { return nil }
        let end = cal.adding(days: 6, to: monday)
        let last = min(end, today)
        let ongoing = end >= today
        let t = QuantityFormat.r2(habit.target)
        func q(_ v: Double) -> String { QuantityFormat.quantity(QuantityFormat.r2(v), for: habit) }
        func qty(_ v: Double) -> String { QuantityFormat.quantityWithUnit(QuantityFormat.r2(v), for: habit) }
        func row(_ state: RecapState, _ score: Double, _ value: String, _ detail: String) -> RecapRow {
            RecapRow(habit: habit, state: state, score: score, value: value, detail: detail,
                     tip: state == .work ? tip(for: habit, weekStart: monday, calendar: cal) : nil)
        }

        switch habit.period {
        case .day:
            var ok = 0, evaluated = 0, sum = 0.0
            for d in cal.days(in: DayRange(first: monday, last: last)) {
                let c = log.value(habit.id, on: d)
                sum += c
                let kept = HabitEngine.isDayKept(habit, value: c)
                // Pour un objectif, aujourd'hui ne compte que s'il est déjà atteint.
                if habit.kind == .goal && d == today && !kept { continue }
                evaluated += 1
                if kept { ok += 1 }
            }
            guard evaluated > 0 else {
                return RecapRow(habit: habit, state: .progress, score: 1, value: "en cours", detail: "Rien à évaluer encore.", tip: nil)
            }
            let bad = evaluated - ok
            let n = Double(evaluated)
            var detail: String
            if bad == 0 {
                detail = habit.kind == .limit ? "Respecté chaque jour." : "Atteint chaque jour."
            } else {
                let days = "\(bad) \(HabitEngine.plural(Double(bad), "jour")) sur \(evaluated)."
                detail = (habit.kind == .limit ? "Dépassé " : "Manqué ") + days
            }
            if habit.isAmount {
                let avg = sum / Double(cal.dayCount(from: monday, to: last))
                detail += " Moyenne \(QuantityFormat.value(QuantityFormat.r2(avg), for: habit)) par jour."
            }
            return row(bad == 0 ? .kept : .work, Double(ok) / n, "\(ok)/\(evaluated) \(HabitEngine.plural(n, "jour"))", detail)

        case .week:
            let c = QuantityFormat.r2(log.total(habit.id, in: DayRange(first: monday, last: end)))
            let value = "\(q(c))/\(q(t))"
            if habit.kind == .limit {
                if c <= t {
                    return row(.kept, 1, value, c == t ? "Pile la limite, c'est tenu." : "Sous la limite, \(q(t - c)) de marge.")
                }
                return row(.work, t / c, value, "Dépassé de \(q(c - t)).")
            }
            if c >= t { return row(.kept, 1, value, c > t ? "Objectif dépassé, bravo." : "Objectif atteint.") }
            if ongoing { return row(.progress, c / t, value, "Encore \(qty(t - c)) d'ici dimanche.") }
            return row(.work, c / t, value, "Il manquait \(qty(t - c)).")

        case .month:
            let month = cal.range(.month, containing: last)
            let c = QuantityFormat.r2(log.total(habit.id, in: DayRange(first: month.first, last: last)))
            let name = cal.monthName(last)
            let value = "\(q(c))/\(q(t))"
            if habit.kind == .limit {
                if c <= t {
                    return row(.kept, 1, value, c == t ? "Limite de \(name) atteinte, garde le cap." : "Bien parti pour \(name).")
                }
                return row(.work, t / c, value, "Dépassé de \(q(c - t)) en \(name).")
            }
            if c >= t { return row(.kept, 1, value, "Objectif de \(name) atteint.") }
            let fraction = Double(cal.dayOfMonth(last)) / Double(cal.daysInMonth(of: last))
            let expected = habit.isAmount ? t * fraction : (t * fraction).rounded(.down)
            if c >= expected {
                return row(.progress, min(1, c / max(expected, 1)), value, "En bonne voie pour \(name).")
            }
            return row(.work, c / max(expected, 1), value, "Un peu en retard sur le rythme de \(name).")
        }
    }
}
