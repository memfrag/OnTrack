//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

#if os(macOS)

import SwiftUI
import AppRouting

/// The wide macOS Overview layout, matching the desktop mockup: a 4-card stat row, an inline
/// trend chart, and a two-column bottom (Recent Entries table beside a Goal Progress panel).
///
/// The selected `range` drives the stat cards and the chart; the date subtitle lives in the
/// navigation bar (set by `OverviewScreen`).
///
struct MacOverviewContent: View {

    let entries: [WeightEntry]
    let goal: WeightGoal?
    let unit: WeightUnit
    let range: ChartRange

    @Environment(Router<MainRouting>.self) private var router

    private var referenceWeightKg: Double? {
        AnalyticsEngine.currentTrend(entries) ?? entries.first?.weightKg
    }

    private var rangeEntries: [WeightEntry] {
        guard let start = range.startDate() else { return entries }
        return entries.filter { $0.timestamp >= start }
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statRow
                chartSection
                bottomRow
            }
            .padding(20)
        }
    }

    // MARK: - Stat row

    private var statRow: some View {
        let stats = AnalyticsEngine.statistics(rangeEntries)
        let weeklyChange = AnalyticsEngine.weeklyChange(entries)
        let trend30 = AnalyticsEngine.currentTrend(entries, windowDays: 30)

        return LazyVGrid(columns: columns, spacing: 12) {
            StatTile(
                title: "Average Weight",
                value: stats.averageKg.map { unit.formattedWithSymbol(fromKg: $0) } ?? "—",
                caption: "Over \(range.label)",
                systemImage: "equal"
            )
            StatTile(
                title: "Change",
                value: weeklyChange.map { unit.formattedDeltaWithSymbol(fromKg: $0) } ?? "—",
                caption: "Per week",
                systemImage: weeklyChange.map { $0 <= 0 ? "arrow.down.right" : "arrow.up.right" } ?? "minus",
                trend: changeTrend(weeklyChange)
            )
            StatTile(
                title: "Lowest",
                value: stats.lowestKg.map { unit.formattedWithSymbol(fromKg: $0) } ?? "—",
                caption: "In \(range.label)",
                systemImage: "arrow.down.to.line"
            )
            StatTile(
                title: "Trend (30-day)",
                value: trend30.map { unit.formattedWithSymbol(fromKg: $0) } ?? "—",
                caption: "30-day average",
                systemImage: "chart.line.flattrend.xyaxis"
            )
        }
    }

    private func changeTrend(_ weeklyChange: Double?) -> StatTile.Trend {
        guard let weeklyChange, abs(weeklyChange) >= 0.05 else { return .neutral }
        let losing = weeklyChange < 0
        if let goal { return (losing == goal.isLoss) ? .good : .bad }
        return losing ? .good : .bad
    }

    // MARK: - Chart

    private var chartSection: some View {
        let series = ChartSeries(entries: entries, range: range)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Weight Chart")
                    .font(.headline)
                Spacer()
                Button {
                    router.push(.chart)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.borderless)
                .help("Open full chart")
            }
            ChartLegend()
            if series.isEmpty {
                Text("Not enough data in this range.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                TrendChartView(series: series, unit: unit)
                    .frame(height: 240)
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Bottom row

    private var bottomRow: some View {
        HStack(alignment: .top, spacing: 16) {
            RecentEntriesTable(entries: entries, unit: unit) {
                router.select(.entries)
            } onEdit: { id in
                router.presentSheet(.editEntry(id))
            }
            .frame(maxWidth: .infinity)

            if let goal {
                MacGoalPanel(
                    goal: goal,
                    currentWeightKg: referenceWeightKg,
                    weeklyChangeKg: AnalyticsEngine.weeklyChange(entries),
                    unit: unit
                ) {
                    router.presentSheet(.editGoal)
                }
                .frame(width: 340)
            }
        }
    }
}

#endif
