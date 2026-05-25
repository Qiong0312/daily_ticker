import SwiftUI
import WidgetKit

// MARK: - Theme

private enum WidgetTheme {
    static let purple800 = Color(red: 0.35, green: 0.15, blue: 0.55)
    static let purple600 = Color(red: 0.45, green: 0.2, blue: 0.65)
    static let purple500 = Color(red: 0.55, green: 0.35, blue: 0.75)
    static let progressTrack = Color(red: 0.95, green: 0.91, blue: 1)
    static let progressFill = Color(red: 0.98, green: 0.57, blue: 0.24)
    static let hintYellow = Color(red: 1, green: 0.98, blue: 0.78)
    static let selectedEmojiBg = Color(red: 1, green: 0.98, blue: 0.78)
    static let selectedEmojiBorder = Color(red: 0.98, green: 0.8, blue: 0.33)
}

struct WidgetEmojiOption: Identifiable {
    let id: String
    let emoji: String
}

private let widgetWeatherOptions: [WidgetEmojiOption] = [
    .init(id: "sunny", emoji: "☀️"),
    .init(id: "partly-cloudy", emoji: "🌤️"),
    .init(id: "cloudy", emoji: "☁️"),
    .init(id: "rainy", emoji: "🌧️"),
    .init(id: "thunderstorm", emoji: "⛈️"),
]

private let widgetMoodOptions: [WidgetEmojiOption] = [
    .init(id: "happy", emoji: "😊"),
    .init(id: "okay", emoji: "😐"),
    .init(id: "tired", emoji: "😴"),
    .init(id: "frustrated", emoji: "😤"),
    .init(id: "excited", emoji: "🤩"),
]

// MARK: - Layout per widget size

enum WidgetLayout {
    case small
    case medium
    case large

    var maxItems: Int {
        switch self {
        case .small: return 3
        case .medium, .large: return 6
        }
    }

    var columns: Int {
        switch self {
        case .medium: return 2
        default: return 1
        }
    }

    var showsWeatherFeel: Bool { self == .large }

    var compactBanner: Bool { self == .small }

    var compactMissionRow: Bool { self != .large }

    /// Tighter vertical gaps on large widget to use extra height.
    var sectionSpacing: CGFloat { self == .large ? 2 : 4 }

    var listSpacing: CGFloat { self == .large ? 2 : 3 }

    var tightWeatherFeel: Bool { self == .large }
}

private func rgbFromHex(_ hex: String) -> (r: Double, g: Double, b: Double) {
    var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("#") { s.removeFirst() }
    guard s.count == 6, let value = Int(s, radix: 16) else {
        return (0.5, 0.4, 0.9)
    }
    return (
        Double((value >> 16) & 0xFF) / 255,
        Double((value >> 8) & 0xFF) / 255,
        Double(value & 0xFF) / 255
    )
}

private func parseHexColor(_ hex: String) -> Color {
    let (r, g, b) = rgbFromHex(hex)
    return Color(red: r, green: g, blue: b)
}

private func missionTint(_ hex: String, amount: Int) -> Color {
    let (r, g, b) = rgbFromHex(hex)
    let t = Double(min(max(amount, 0), 100)) / 100
    return Color(red: (1 - t) + t * r, green: (1 - t) + t * g, blue: (1 - t) + t * b)
}

// MARK: - Root

struct TodayWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TodayWidgetEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot, snapshot.profile != nil {
                CompactTodayWidgetView(snapshot: snapshot, layout: layout)
            } else {
                emptyState
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.91, blue: 1),
                    Color(red: 1, green: 0.98, blue: 0.94),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var layout: WidgetLayout {
        switch family {
        case .systemSmall: return .small
        case .systemLarge: return .large
        default: return .medium
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("Daily Ticker")
                .font(.headline)
                .foregroundStyle(WidgetTheme.purple800)
            Text("Open the app to get started")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            WidgetAddMissionsButton()
        }
        .padding()
    }
}

// MARK: - Shared layout

struct CompactTodayWidgetView: View {
    let snapshot: WidgetSnapshot
    let layout: WidgetLayout

    var body: some View {
        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
            WidgetHeaderView(snapshot: snapshot)

            if layout.showsWeatherFeel {
                WidgetWeatherFeelSection(snapshot: snapshot, tight: layout.tightWeatherFeel)
            }

            WidgetProgressView(snapshot: snapshot, tight: layout.tightWeatherFeel)

            if snapshot.allTodayComplete {
                SuperDayBanner(compact: layout.compactBanner)
            } else if snapshot.today.isEmpty {
                WidgetEmptyTodayHint()
            } else {
                WidgetTodayList(
                    snapshot: snapshot,
                    maxItems: layout.maxItems,
                    columns: layout.columns,
                    compactRow: layout.compactMissionRow,
                    spacing: layout.listSpacing
                )
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Header

struct WidgetHeaderView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if let profile = snapshot.profile {
                Text(profile.avatar)
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 0) {
                    Text(profile.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WidgetTheme.purple800)
                        .lineLimit(1)
                    Text("How's today?")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(red: 0.05, green: 0.55, blue: 0.75))
                }
            }
            Spacer(minLength: 0)
            if snapshot.streak > 0 {
                Text("🔥 \(snapshot.streak)")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
            }
            WidgetAddMissionsButton()
        }
    }
}

struct WidgetAddMissionsButton: View {
    private static let addMissionsURL = URL(string: "dailyticker://today")!

    var body: some View {
        Link(destination: Self.addMissionsURL) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(WidgetTheme.purple600)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
        }
        .accessibilityLabel("Add missions in app")
    }
}

// MARK: - Weather & feel (large widget)

struct WidgetWeatherFeelSection: View {
    let snapshot: WidgetSnapshot
    var tight: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: tight ? 4 : 6) {
            WidgetEmojiOptionGroup(
                label: "Weather",
                options: widgetWeatherOptions,
                selectedId: snapshot.entry?.weather,
                weatherIntent: true,
                tight: tight
            )
            WidgetEmojiOptionGroup(
                label: "Feel",
                options: widgetMoodOptions,
                selectedId: snapshot.entry?.mood,
                weatherIntent: false,
                tight: tight
            )
        }
    }
}

struct WidgetEmojiOptionGroup: View {
    let label: String
    let options: [WidgetEmojiOption]
    let selectedId: String?
    let weatherIntent: Bool
    var tight: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: tight ? 1 : 2) {
            Text(label)
                .font(.system(size: tight ? 7 : 8, weight: .semibold))
                .foregroundStyle(WidgetTheme.purple500)
            HStack(spacing: tight ? 1 : 2) {
                ForEach(options) { option in
                    if weatherIntent {
                        Button(intent: SetWeatherIntent(weather: option.id)) {
                            WidgetEmojiChip(emoji: option.emoji, selected: selectedId == option.id, tight: tight)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(intent: SetMoodIntent(mood: option.id)) {
                            WidgetEmojiChip(emoji: option.emoji, selected: selectedId == option.id, tight: tight)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WidgetEmojiChip: View {
    let emoji: String
    let selected: Bool
    var tight: Bool = false

    var body: some View {
        Text(emoji)
            .font(.system(size: tight ? 12 : 13))
            .padding(.horizontal, tight ? 3 : 4)
            .padding(.vertical, tight ? 1 : 2)
            .background(selected ? WidgetTheme.selectedEmojiBg : Color.white.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(selected ? WidgetTheme.selectedEmojiBorder : Color.clear, lineWidth: 1.5)
            )
    }
}

// MARK: - Progress

struct WidgetProgressView: View {
    let snapshot: WidgetSnapshot
    var tight: Bool = false

    private var completed: Int { snapshot.today.filter(\.completed).count }
    private var total: Int { snapshot.today.count }

    var body: some View {
        HStack(spacing: tight ? 4 : 6) {
            Text("\(completed)/\(total) ⭐")
                .font(.system(size: tight ? 9 : 10, weight: .heavy))
                .foregroundStyle(WidgetTheme.purple600)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(WidgetTheme.progressTrack)
                    Capsule()
                        .fill(WidgetTheme.progressFill)
                        .frame(
                            width: total > 0
                                ? geo.size.width * CGFloat(completed) / CGFloat(total)
                                : 0
                        )
                }
            }
            .frame(height: tight ? 4 : 5)
        }
    }
}

// MARK: - Today list

struct WidgetTodayList: View {
    let snapshot: WidgetSnapshot
    let maxItems: Int
    let columns: Int
    var compactRow: Bool = true
    var spacing: CGFloat = 3

    private var visibleItems: [WidgetSnapshotTodayItem] {
        Array(snapshot.today.prefix(maxItems))
    }

    private var moreCount: Int {
        max(0, snapshot.today.count - maxItems)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            if columns == 1 {
                ForEach(visibleItems, id: \.missionId) { item in
                    missionRow(for: item)
                }
            } else {
                let rowCount = (visibleItems.count + 1) / 2
                ForEach(0..<rowCount, id: \.self) { row in
                    HStack(spacing: spacing) {
                        missionCell(index: row * 2)
                        missionCell(index: row * 2 + 1)
                    }
                }
            }

            if moreCount > 0 {
                Text("\(moreCount) more in app")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(WidgetTheme.purple500)
                    .frame(maxWidth: .infinity, alignment: columns > 1 ? .center : .leading)
            }
        }
    }

    @ViewBuilder
    private func missionCell(index: Int) -> some View {
        if index < visibleItems.count {
            missionRow(for: visibleItems[index])
                .frame(maxWidth: .infinity)
        } else {
            Color.clear.frame(maxWidth: .infinity, minHeight: 1)
        }
    }

    @ViewBuilder
    private func missionRow(for item: WidgetSnapshotTodayItem) -> some View {
        if let mission = snapshot.mission(for: item.missionId) {
            WidgetTodayMissionRow(
                mission: mission,
                completed: item.completed,
                compact: compactRow
            )
        }
    }
}

struct WidgetTodayMissionRow: View {
    let mission: WidgetSnapshotMission
    let completed: Bool
    var compact: Bool = true

    private var accent: Color { parseHexColor(mission.color) }
    private var starSize: CGFloat { compact ? 20 : 22 }
    private var nameFont: CGFloat { compact ? 10 : 11 }

    var body: some View {
        Button(intent: ToggleCompleteIntent(missionId: mission.id)) {
            HStack(spacing: compact ? 4 : 6) {
                WidgetStarToggle(completed: completed, accent: accent, size: starSize)
                Text(mission.name)
                    .font(.system(size: nameFont, weight: .bold))
                    .foregroundStyle(WidgetTheme.purple800)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, compact ? 5 : 6)
            .padding(.vertical, compact ? 2 : 2)
            .background(missionTint(mission.color, amount: completed ? 22 : 34))
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }
}

struct WidgetStarToggle: View {
    let completed: Bool
    let accent: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(completed ? Color(red: 1, green: 0.95, blue: 0.78) : Color.white.opacity(0.9))
            RoundedRectangle(cornerRadius: size * 0.28)
                .stroke(
                    completed ? Color(red: 1, green: 0.8, blue: 0.3) : accent.opacity(0.45),
                    lineWidth: 1.5
                )
            Text(completed ? "⭐" : "☆")
                .font(.system(size: size * 0.5))
        }
        .frame(width: size, height: size)
    }
}

struct WidgetEmptyTodayHint: View {
    var body: some View {
        Text("Tap + to pick missions in the app")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(WidgetTheme.purple600)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(WidgetTheme.hintYellow.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SuperDayBanner: View {
    let compact: Bool

    var body: some View {
        Text("Super day! You earned all your stars! 🎉")
            .font(.system(size: compact ? 9 : 10, weight: .heavy))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 6)
            .padding(.vertical, compact ? 5 : 7)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1, green: 0.88, blue: 0.28),
                        Color(red: 0.96, green: 0.45, blue: 0.65),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
