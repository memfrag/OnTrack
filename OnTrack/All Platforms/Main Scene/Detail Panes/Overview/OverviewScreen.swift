//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftData
import AppRouting

/// The dashboard: current weight, trend, weekly change, goal progress, forecast, recent entries.
///
/// Metrics are derived from the pure ``AnalyticsEngine`` / ``ForecastEngine``. The trend chart
/// is inserted in Phase 3.
///
struct OverviewScreen: View {

    @Environment(Router<MainRouting>.self) private var router
    @Environment(AppSettings.self) private var appSettings

    @Query(sort: \WeightEntry.timestamp, order: .reverse) private var entries: [WeightEntry]
    @Query(sort: \WeightGoal.createdAt, order: .reverse) private var goals: [WeightGoal]

    private var unit: WeightUnit { appSettings.weightUnit }
    private var latest: WeightEntry? { entries.first }
    private var goal: WeightGoal? { goals.first }

    private var currentTrendKg: Double? { AnalyticsEngine.currentTrend(entries) }
    private var weeklyChangeKg: Double? { AnalyticsEngine.weeklyChange(entries) }

    /// The weight used for goal progress / forecast: the smoothed trend, falling back to the
    /// latest raw measurement when there isn't enough data for a trend.
    private var referenceWeightKg: Double? { currentTrendKg ?? latest?.weightKg }

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router[.overview]) {
            Group {
                if entries.isEmpty {
                    EmptyStateView(
                        title: "Welcome to OnTrack",
                        message: "Add your first weight to see your trend, progress, and forecast.",
                        systemImage: "chart.line.uptrend.xyaxis",
                        actionTitle: "Add Weight"
                    ) {
                        router.presentSheet(.addWeight)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            metricsGrid
                            TrendChartCard(entries: entries, unit: unit)
                            if let goal {
                                GoalProgressCard(
                                    goal: goal,
                                    currentWeightKg: referenceWeightKg,
                                    unit: unit,
                                    onEdit: { router.presentSheet(.editGoal) }
                                )
                            }
                            recentEntriesSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    AddWeightToolbarButton()
                }
            }
            .mainPushableDestinations()
        }
    }

    // MARK: - Metrics

    private var metricsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            if let latest {
                StatTile(
                    title: "Current",
                    value: unit.formattedWithSymbol(fromKg: latest.weightKg),
                    caption: latest.timestamp.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "scalemass"
                )
            }
            if let currentTrendKg {
                StatTile(
                    title: "Trend (7-day)",
                    value: unit.formattedWithSymbol(fromKg: currentTrendKg),
                    systemImage: "chart.line.flattrend.xyaxis"
                )
            }
            if let weeklyChangeKg {
                StatTile(
                    title: "Weekly Change",
                    value: unit.formattedDeltaWithSymbol(fromKg: weeklyChangeKg),
                    caption: "Per week",
                    systemImage: weeklyChangeKg <= 0 ? "arrow.down.right" : "arrow.up.right",
                    trend: weeklyChangeTrend
                )
            }
            ForecastTile(
                entries: entries,
                goal: goal,
                referenceWeightKg: referenceWeightKg,
                unit: unit
            )
        }
    }

    /// Colors the weekly change relative to the goal direction (good = moving toward target).
    /// With no goal, weight loss is shown as "good" by convention.
    private var weeklyChangeTrend: StatTile.Trend {
        guard let weeklyChangeKg else { return .neutral }
        if abs(weeklyChangeKg) < 0.05 { return .neutral }
        let losing = weeklyChangeKg < 0
        if let goal {
            return (losing == goal.isLoss) ? .good : .bad
        }
        return losing ? .good : .bad
    }

    // MARK: - Recent entries

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Entries")
                    .font(.headline)
                Spacer()
                Button("Show All") { router.select(.entries) }
                    .font(.subheadline)
            }
            VStack(spacing: 0) {
                ForEach(entries.prefix(10)) { entry in
                    Button {
                        router.presentSheet(.editEntry(entry.id))
                    } label: {
                        RecentEntryRow(entry: entry, unit: unit)
                    }
                    .buttonStyle(.plain)
                    if entry.id != entries.prefix(10).last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Recent entry row

private struct RecentEntryRow: View {
    let entry: WeightEntry
    let unit: WeightUnit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.timestamp.formatted(date: .abbreviated, time: .omitted))
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(unit.formattedWithSymbol(fromKg: entry.weightKg))
                .font(.body.weight(.medium))
                .monospacedDigit()
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    OverviewScreen()
        .appEnvironment(.mock())
}
