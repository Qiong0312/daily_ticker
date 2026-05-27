import Foundation
import WidgetKit

// MARK: - Models

struct WidgetSnapshotProfile: Codable {
    var id: String
    var name: String
    var avatar: String
}

struct WidgetSnapshotEntry: Codable {
    var weather: String?
    var mood: String?
}

struct WidgetSnapshotMission: Codable {
    var id: String
    var name: String
    var icon: String
    var color: String
    var sortOrder: Int
}

struct WidgetSnapshotTodayItem: Codable {
    var missionId: String
    var completed: Bool
}

struct WidgetSnapshot: Codable {
    var version: Int = 1
    var updatedAt: String
    var needsAppSync: Bool = false
    var activeProfileId: String?
    var dateKey: String
    var profile: WidgetSnapshotProfile?
    var streak: Int = 0
    var entry: WidgetSnapshotEntry?
    var missions: [WidgetSnapshotMission] = []
    var today: [WidgetSnapshotTodayItem] = []

    var allTodayComplete: Bool {
        !today.isEmpty && today.allSatisfy(\.completed)
    }

    func mission(for id: String) -> WidgetSnapshotMission? {
        missions.first { $0.id == id }
    }
}

// MARK: - Storage

enum WidgetDataStore {
    static let appGroupId = "group.com.dailyticker.dailyTicker"
    static let fileName = "widget_snapshot.json"

    static func fileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent(fileName)
    }

    static func readRaw() -> String? {
        guard let url = fileURL(),
              let data = try? Data(contentsOf: url) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func writeRaw(_ json: String) throws {
        guard let url = fileURL() else {
            throw WidgetStoreError.noContainer
        }
        try json.write(to: url, atomically: true, encoding: .utf8)
    }

    static func load() -> WidgetSnapshot? {
        guard let raw = readRaw(),
              let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: WidgetSnapshot, markNeedsSync: Bool = false) throws {
        var copy = snapshot
        copy.needsAppSync = markNeedsSync
        copy.updatedAt = ISO8601DateFormatter().string(from: Date())
        let data = try JSONEncoder().encode(copy)
        guard let url = fileURL() else { throw WidgetStoreError.noContainer }
        try data.write(to: url, options: .atomic)
        reloadTimelines()
    }

    static func reloadTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Match Dart `todayKey()` — `yyyy-MM-dd` in local time.
    static func todayDateKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// Drop yesterday's tasks/weather when the calendar day has changed.
    static func normalizedForToday(_ snapshot: WidgetSnapshot?) -> WidgetSnapshot? {
        guard var copy = snapshot else { return nil }
        let today = todayDateKey()
        guard copy.dateKey != today else { return copy }
        copy.dateKey = today
        copy.today = []
        copy.entry = nil
        copy.needsAppSync = false
        return copy
    }

    /// Persist a stale-day reset so the app never imports yesterday on launch.
    static func clearStaleSnapshotIfNeeded() {
        guard let snapshot = load(), snapshot.dateKey != todayDateKey() else { return }
        var fresh = snapshot
        fresh.dateKey = todayDateKey()
        fresh.today = []
        fresh.entry = nil
        fresh.needsAppSync = false
        try? save(fresh)
    }

    // MARK: Mutations (widget intents)

    private static func loadMutableForToday() throws -> WidgetSnapshot {
        guard var snapshot = load() else { throw WidgetStoreError.noSnapshot }
        let today = todayDateKey()
        if snapshot.dateKey != today {
            snapshot.dateKey = today
            snapshot.today = []
            snapshot.entry = nil
            snapshot.needsAppSync = false
        }
        return snapshot
    }

    static func toggleComplete(missionId: String) throws {
        var snapshot = try loadMutableForToday()
        guard let index = snapshot.today.firstIndex(where: { $0.missionId == missionId }) else {
            throw WidgetStoreError.missionNotOnToday
        }
        snapshot.today[index].completed.toggle()
        try save(snapshot, markNeedsSync: true)
    }

    static func toggleOnToday(missionId: String) throws {
        var snapshot = try loadMutableForToday()
        if let index = snapshot.today.firstIndex(where: { $0.missionId == missionId }) {
            snapshot.today.remove(at: index)
        } else {
            snapshot.today.append(WidgetSnapshotTodayItem(missionId: missionId, completed: false))
        }
        try save(snapshot, markNeedsSync: true)
    }

    static func setWeather(_ value: String) throws {
        var snapshot = try loadMutableForToday()
        if snapshot.entry == nil {
            snapshot.entry = WidgetSnapshotEntry(weather: value, mood: nil)
        } else {
            snapshot.entry?.weather = value
        }
        try save(snapshot, markNeedsSync: true)
    }

    static func setMood(_ value: String) throws {
        var snapshot = try loadMutableForToday()
        if snapshot.entry == nil {
            snapshot.entry = WidgetSnapshotEntry(weather: nil, mood: value)
        } else {
            snapshot.entry?.mood = value
        }
        try save(snapshot, markNeedsSync: true)
    }
}

enum WidgetStoreError: Error {
    case noContainer
    case noSnapshot
    case missionNotOnToday
}

// MARK: - Deep link (widget + button → app)

enum WidgetDeepLinkStore {
    private static let key = "pending_deep_link"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WidgetDataStore.appGroupId)
    }

    static func enqueue(host: String?) {
        defaults?.set(host ?? "today", forKey: key)
    }

    static func consume() -> String? {
        guard let value = defaults?.string(forKey: key) else { return nil }
        defaults?.removeObject(forKey: key)
        return value
    }
}
