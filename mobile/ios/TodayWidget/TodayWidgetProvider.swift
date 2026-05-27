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
        WidgetDataStore.clearStaleSnapshotIfNeeded()
        let snapshot = WidgetDataStore.normalizedForToday(WidgetDataStore.load())
            ?? placeholderSnapshot
        completion(TodayWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWidgetEntry>) -> Void) {
        WidgetDataStore.clearStaleSnapshotIfNeeded()
        let now = Date()
        let calendar = Calendar.current
        let snapshot = WidgetDataStore.normalizedForToday(WidgetDataStore.load())

        var entries: [TodayWidgetEntry] = [
            TodayWidgetEntry(date: now, snapshot: snapshot),
        ]

        // Refresh at next midnight so the widget clears yesterday without opening the app.
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
            var overnight = snapshot
            if var copy = overnight {
                copy.dateKey = WidgetDataStore.todayDateKey(for: tomorrow)
                copy.today = []
                copy.entry = nil
                copy.needsAppSync = false
                overnight = copy
            }
            entries.append(TodayWidgetEntry(date: tomorrow, snapshot: overnight))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private var placeholderSnapshot: WidgetSnapshot {
        WidgetSnapshot(
            updatedAt: "",
            dateKey: WidgetDataStore.todayDateKey(),
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
