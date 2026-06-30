//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import Charts

/// The main trend chart: faint raw measurements plus an emphasized 7-day trend line.
///
/// Values are plotted in the active ``WeightUnit`` (the stored kilograms are converted for
/// display). On long ranges the raw series is pre-downsampled by ``ChartSeries``. When
/// `interactive` is `true`, dragging (iOS) / hovering (macOS) reveals a value callout.
///
struct TrendChartView: View {

    let series: ChartSeries
    let unit: WeightUnit
    var interactive: Bool = false

    @State private var selectedDate: Date?

    private let rawColor = Color.secondary
    private let trendColor = Color.accentColor

    private func display(_ point: WeightPoint) -> Double {
        unit.value(fromKg: point.weightKg)
    }

    /// The trend point nearest the current selection, for the callout.
    private var selectedTrendPoint: WeightPoint? {
        guard let selectedDate, !series.trend.isEmpty else { return nil }
        return series.trend.min {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        }
    }

    var body: some View {
        Chart {
            // Raw measurements: thin straight lines between points, plus faint dots.
            ForEach(series.raw) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", display(point)),
                    series: .value("Series", "Raw")
                )
                .foregroundStyle(rawColor.opacity(0.35))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.linear)
            }
            ForEach(series.raw) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", display(point))
                )
                .foregroundStyle(rawColor.opacity(0.35))
                .symbolSize(18)
            }

            // Trend: emphasized smooth 7-day moving average.
            ForEach(series.trend) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Trend", display(point)),
                    series: .value("Series", "Trend")
                )
                .foregroundStyle(trendColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }

            if let selectedTrendPoint {
                RuleMark(x: .value("Selected", selectedTrendPoint.date))
                    .foregroundStyle(.secondary.opacity(0.4))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        calloutView(for: selectedTrendPoint)
                    }
                PointMark(
                    x: .value("Date", selectedTrendPoint.date),
                    y: .value("Trend", display(selectedTrendPoint))
                )
                .foregroundStyle(trendColor)
                .symbolSize(60)
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxisLabel(unit.symbol)
        .modifier(SelectionModifier(enabled: interactive, selectedDate: $selectedDate))
        .accessibilityLabel("Weight trend chart")
        .accessibilityValue(accessibilitySummary)
    }

    @ViewBuilder private func calloutView(for point: WeightPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(point.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(unit.formattedWithSymbol(fromKg: point.weightKg))
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var accessibilitySummary: String {
        guard let first = series.trend.first, let last = series.trend.last else {
            return "No data"
        }
        return "Trend from \(unit.formattedWithSymbol(fromKg: first.weightKg)) to "
            + "\(unit.formattedWithSymbol(fromKg: last.weightKg)) over \(series.trend.count) days."
    }
}

/// Applies `chartXSelection` only when interactivity is requested, keeping embedded
/// (non-interactive) charts simple.
private struct SelectionModifier: ViewModifier {
    let enabled: Bool
    @Binding var selectedDate: Date?

    func body(content: Content) -> some View {
        if enabled {
            content.chartXSelection(value: $selectedDate)
        } else {
            content
        }
    }
}
