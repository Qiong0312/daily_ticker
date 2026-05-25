import SwiftUI
import WidgetKit

// MARK: - Root

struct TodayWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TodayWidgetEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot, snapshot.profile != nil {
                content(snapshot: snapshot)
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

    @ViewBuilder
    private func content(snapshot: WidgetSnapshot) -> some View {
        switch family {
        case .systemSmall:
            SmallTodayWidgetView(snapshot: snapshot)
        case .systemLarge:
            LargeTodayWidgetView(snapshot: snapshot)
        default:
            MediumTodayWidgetView(snapshot: snapshot)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("Daily Ticker")
                .font(.headline)
                .foregroundStyle(Color(red: 0.35, green: 0.15, blue: 0.55))
            Text("Open the app to get started")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Small

struct SmallTodayWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetHeaderView(snapshot: snapshot, compact: true)
            WidgetProgressView(snapshot: snapshot)
            if snapshot.allTodayComplete {
                SuperDayBanner(compact: true)
            } else if let next = firstIncomplete {
                Button(intent: ToggleCompleteIntent(missionId: next.missionId)) {
                    HStack(spacing: 6) {
                        Image(systemName: "circle")
                            .font(.caption)
                        Text("\(next.icon) \(next.name)")
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color(red: 0.35, green: 0.15, blue: 0.55))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var firstIncomplete: (missionId: String, icon: String, name: String)? {
        for item in snapshot.today where !item.completed {
            if let m = snapshot.mission(for: item.missionId) {
                return (item.missionId, m.icon, m.name)
            }
        }
        return nil
    }
}

// MARK: - Medium

struct MediumTodayWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetHeaderView(snapshot: snapshot, compact: false)
            WidgetProgressView(snapshot: snapshot)
            if !snapshot.allTodayComplete {
                WidgetChipRow(snapshot: snapshot)
            }
            if snapshot.allTodayComplete {
                SuperDayBanner(compact: false)
            } else {
                WidgetTodayList(snapshot: snapshot, maxRows: 3)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Large

struct LargeTodayWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetHeaderView(snapshot: snapshot, compact: false)
            WidgetProgressView(snapshot: snapshot)
            WidgetChipRow(snapshot: snapshot)
            if snapshot.allTodayComplete {
                SuperDayBanner(compact: false)
            } else {
                WidgetTodayList(snapshot: snapshot, maxRows: 5)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Components

struct WidgetHeaderView: View {
    let snapshot: WidgetSnapshot
    let compact: Bool

    var body: some View {
        HStack(alignment: .top) {
            if let profile = snapshot.profile {
                Text(profile.avatar)
                    .font(.system(size: compact ? 16 : 18))
                VStack(alignment: .leading, spacing: 0) {
                    if !compact {
                        Text(profile.name)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color(red: 0.35, green: 0.15, blue: 0.55))
                    }
                    Text("How's today?")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(red: 0.05, green: 0.55, blue: 0.75))
                }
            }
            Spacer()
            if snapshot.streak > 0 {
                Text("🔥 \(snapshot.streak)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }
}

struct WidgetProgressView: View {
    let snapshot: WidgetSnapshot

    private var completed: Int { snapshot.today.filter(\.completed).count }
    private var total: Int { snapshot.today.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(completed)/\(total) ⭐")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(Color(red: 0.45, green: 0.2, blue: 0.65))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(red: 0.93, green: 0.88, blue: 1))
                    Capsule()
                        .fill(Color.orange)
                        .frame(
                            width: total > 0
                                ? geo.size.width * CGFloat(completed) / CGFloat(total)
                                : 0
                        )
                }
            }
            .frame(height: 6)
        }
    }
}

struct WidgetChipRow: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(snapshot.missions, id: \.id) { mission in
                    let onToday = snapshot.today.contains { $0.missionId == mission.id }
                    Button(intent: ToggleOnTodayIntent(missionId: mission.id)) {
                        HStack(spacing: 2) {
                            Text(mission.icon)
                            Text(shortName(mission.name))
                                .lineLimit(1)
                            if onToday { Text("⭐") }
                        }
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(chipColor(mission.color).opacity(onToday ? 0.55 : 1))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 28)
    }

    private func shortName(_ name: String) -> String {
        name.count > 8 ? String(name.prefix(7)) + "…" : name
    }

    private func chipColor(_ hex: String) -> Color {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = Int(s, radix: 16) else {
            return Color(red: 0.5, green: 0.4, blue: 0.9)
        }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

struct WidgetTodayList: View {
    let snapshot: WidgetSnapshot
    let maxRows: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(snapshot.today.prefix(maxRows)), id: \.missionId) { item in
                if let mission = snapshot.mission(for: item.missionId) {
                    Button(intent: ToggleCompleteIntent(missionId: item.missionId)) {
                        HStack(spacing: 6) {
                            Image(systemName: item.completed ? "star.fill" : "circle")
                                .font(.caption)
                                .foregroundStyle(item.completed ? .yellow : .secondary)
                            Text("\(mission.icon) \(mission.name)")
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                                .foregroundStyle(Color(red: 0.35, green: 0.15, blue: 0.55))
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            if snapshot.today.count > maxRows {
                Text("+\(snapshot.today.count - maxRows) more in app")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SuperDayBanner: View {
    let compact: Bool

    var body: some View {
        Text("Super day! You earned all your stars! 🎉")
            .font(.system(size: compact ? 10 : 11, weight: .heavy))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .padding(.vertical, compact ? 6 : 8)
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
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
