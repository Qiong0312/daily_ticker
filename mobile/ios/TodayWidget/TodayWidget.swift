import SwiftUI
import WidgetKit

@main
struct TodayWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
    }
}

struct TodayWidget: Widget {
    let kind: String = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayWidgetProvider()) { entry in
            TodayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Ticker")
        .description("Tick off today's missions. Tap + to add more in the app.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
