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
        .description("Pick missions and earn stars for today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
