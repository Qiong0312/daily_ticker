import WidgetKit
import SwiftUI

struct TodayWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct TodayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayWidgetEntry {
        TodayWidgetEntry(date: Date(), snapshot: placeholderSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetEntry) -> Void) {
        completion(TodayWidgetEntry(date: Date(), snapshot: WidgetDataStore.load() ?? placeholderSnapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWidgetEntry>) -> Void) {
        let snapshot = WidgetDataStore.load()
        let entry = TodayWidgetEntry(date: Date(), snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private var placeholderSnapshot: WidgetSnapshot {
        WidgetSnapshot(
            updatedAt: "",
            dateKey: "2026-05-24",
            profile: WidgetSnapshotProfile(id: "1", name: "Alex", avatar: "🦊"),
            streak: 3,
            missions: [
                WidgetSnapshotMission(id: "m1", name: "English", icon: "📖", color: "#4ECDC4", sortOrder: 0),
                WidgetSnapshotMission(id: "m2", name: "Maths", icon: "🔢", color: "#A78BFA", sortOrder: 1),
            ],
            today: [
                WidgetSnapshotTodayItem(missionId: "m1", completed: true),
                WidgetSnapshotTodayItem(missionId: "m2", completed: false),
            ]
        )
    }
}
