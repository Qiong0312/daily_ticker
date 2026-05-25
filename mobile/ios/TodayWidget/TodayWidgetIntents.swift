import AppIntents
import WidgetKit

// MARK: - Toggle complete

struct ToggleCompleteIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle star"
    static var description = IntentDescription("Mark a mission complete or incomplete for today.")

    @Parameter(title: "Mission")
    var missionId: String

    init() {}

    init(missionId: String) {
        self.missionId = missionId
    }

    func perform() async throws -> some IntentResult {
        try WidgetDataStore.toggleComplete(missionId: missionId)
        return .result()
    }
}

// MARK: - Toggle on today list

struct ToggleOnTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Add or remove mission"
    static var description = IntentDescription("Add or remove a mission from today's list.")

    @Parameter(title: "Mission")
    var missionId: String

    init() {}

    init(missionId: String) {
        self.missionId = missionId
    }

    func perform() async throws -> some IntentResult {
        try WidgetDataStore.toggleOnToday(missionId: missionId)
        return .result()
    }
}

// MARK: - Weather / mood (optional widget style)

struct SetWeatherIntent: AppIntent {
    static var title: LocalizedStringResource = "Set weather"

    @Parameter(title: "Weather")
    var weather: String

    init() {}

    init(weather: String) {
        self.weather = weather
    }

    func perform() async throws -> some IntentResult {
        try WidgetDataStore.setWeather(weather)
        return .result()
    }
}

struct SetMoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Set feel"

    @Parameter(title: "Mood")
    var mood: String

    init() {}

    init(mood: String) {
        self.mood = mood
    }

    func perform() async throws -> some IntentResult {
        try WidgetDataStore.setMood(mood)
        return .result()
    }
}

struct OpenTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Daily Ticker"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
