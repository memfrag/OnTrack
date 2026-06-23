//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftData

/// Full-screen trend chart with a range selector, interactive callout, and a Rate summary.
struct ChartScreen: View {

    @Environment(AppSettings.self) private var appSettings

    @Query(sort: \WeightEntry.timestamp, order: .reverse) private var entries: [WeightEntry]

    @State private var range: ChartRange = .quarter

    private var unit: WeightUnit { appSettings.weightUnit }
    private var series: ChartSeries { ChartSeries(entries: entries, range: range) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Range", selection: $range) {
                    ForEach(ChartRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                if series.isEmpty {
                    EmptyStateView(
                        title: "No Data in Range",
                        message: "Add measurements or pick a longer range to see your trend.",
                        systemImage: "chart.xyaxis.line"
                    )
                    .frame(height: 240)
                } else {
                    ChartLegend()
                    TrendChartView(series: series, unit: unit, interactive: true)
                        .frame(height: 280)

                    RateSummary(entries: entries, range: range, unit: unit)
                }
            }
            .padding()
        }
        .navigationTitle("Weight Chart")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The "Rate" summary beneath the chart: current trend, weekly change, and range average.
private struct RateSummary: View {

    let entries: [WeightEntry]
    let range: ChartRange
    let unit: WeightUnit

    private var rangeEntries: [WeightEntry] {
        guard let start = range.startDate() else { return entries }
        return entries.filter { $0.timestamp >= start }
    }

    private var currentTrendKg: Double? { AnalyticsEngine.currentTrend(entries) }
    private var weeklyChangeKg: Double? { AnalyticsEngine.weeklyChange(entries) }
    private var averageKg: Double? {
        let weights = rangeEntries.map(\.weightKg)
        guard !weights.isEmpty else { return nil }
        return weights.reduce(0, +) / Double(weights.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rate (\(range.label))")
                .font(.headline)
            HStack(spacing: 12) {
                summary("Trend", currentTrendKg.map { unit.formattedWithSymbol(fromKg: $0) })
                summary("Weekly Change", weeklyChangeKg.map { unit.formattedDeltaWithSymbol(fromKg: $0) })
                summary("Average", averageKg.map { unit.formattedWithSymbol(fromKg: $0) })
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func summary(_ title: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value ?? "—")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChartScreen()
            .appEnvironment(.mock())
    }
}
