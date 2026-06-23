//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftData
import AppRouting

/// Summary statistics over a selectable time range (30D / 90D / 1Y / All).
struct StatisticsScreen: View {

    @Environment(Router<MainRouting>.self) private var router
    @Environment(AppSettings.self) private var appSettings

    @Query(sort: \WeightEntry.timestamp, order: .reverse) private var entries: [WeightEntry]

    @State private var range: ChartRange = .month

    private var unit: WeightUnit { appSettings.weightUnit }

    /// Ranges relevant to statistics, per the PRD (no 7-day option here).
    private let ranges: [ChartRange] = [.month, .quarter, .year, .all]

    private var rangeEntries: [WeightEntry] {
        guard let start = range.startDate() else { return entries }
        return entries.filter { $0.timestamp >= start }
    }

    private var stats: WeightStatistics {
        AnalyticsEngine.statistics(rangeEntries)
    }

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router[.statistics]) {
            Group {
                if entries.isEmpty {
                    EmptyStateView(
                        title: "No Statistics Yet",
                        message: "Add measurements to see your highs, lows, averages, and weekly changes.",
                        systemImage: "chart.bar"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Picker("Range", selection: $range) {
                                ForEach(ranges) { range in
                                    Text(range.label).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)

                            if rangeEntries.isEmpty {
                                EmptyStateView(
                                    title: "No Data in Range",
                                    message: "Pick a longer range to see statistics.",
                                    systemImage: "calendar.badge.exclamationmark"
                                )
                                .frame(height: 200)
                            } else {
                                grid
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Statistics")
            .mainPushableDestinations()
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatTile(
                title: "Highest",
                value: stats.highestKg.map { unit.formattedWithSymbol(fromKg: $0) } ?? "—",
                systemImage: "arrow.up.to.line"
            )
            StatTile(
                title: "Lowest",
                value: stats.lowestKg.map { unit.formattedWithSymbol(fromKg: $0) } ?? "—",
                systemImage: "arrow.down.to.line"
            )
            StatTile(
                title: "Average",
                value: stats.averageKg.map { unit.formattedWithSymbol(fromKg: $0) } ?? "—",
                systemImage: "equal"
            )
            StatTile(
                title: "Largest Weekly Loss",
                value: stats.largestWeeklyLossKg.map { unit.formattedDeltaWithSymbol(fromKg: $0) } ?? "—",
                systemImage: "arrow.down.right",
                trend: stats.largestWeeklyLossKg.map { $0 < 0 ? .good : .neutral } ?? .neutral
            )
            StatTile(
                title: "Largest Weekly Gain",
                value: stats.largestWeeklyGainKg.map { unit.formattedDeltaWithSymbol(fromKg: $0) } ?? "—",
                systemImage: "arrow.up.right",
                trend: stats.largestWeeklyGainKg.map { $0 > 0 ? .bad : .neutral } ?? .neutral
            )
            StatTile(
                title: "Total Measurements",
                value: "\(stats.measurementCount)",
                systemImage: "number"
            )
        }
    }
}

// MARK: - Preview

#Preview {
    StatisticsScreen()
        .appEnvironment(.mock())
}
