import SwiftUI
import WidgetKit

@main
struct RituelWidgetsBundle: WidgetBundle {
    var body: some Widget {
        HabitWidget()
        TodayWidget()
        ProgressAccessoryWidget()
    }
}
