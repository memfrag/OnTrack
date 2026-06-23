//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// A single plotted point (raw or trend), in kilograms.
public struct WeightPoint: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let date: Date
    public let weightKg: Double
}

/// Prepares the raw and trend series for a given range, applying the downsampling and
/// trend rules. Pure and self-contained so the chart views stay simple.
public struct ChartSeries {

    /// Raw measurements (downsampled to daily means on long ranges).
    public let raw: [WeightPoint]
    /// The smoothed trend line.
    public let trend: [WeightPoint]

    public var isEmpty: Bool { raw.isEmpty && trend.isEmpty }

    public init(
        entries: [WeightSample],
        range: ChartRange,
        windowDays: Int = AnalyticsEngine.defaultWindowDays,
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        let inRange: [WeightSample]
        if let start = range.startDate(now: now, calendar: calendar) {
            inRange = entries.filter { $0.timestamp >= start && $0.timestamp <= now }
        } else {
            inRange = entries
        }

        let buckets = AnalyticsEngine.dailyBuckets(inRange, calendar: calendar)

        if range.downsamplesRaw {
            raw = buckets.map { WeightPoint(date: $0.day, weightKg: $0.weightKg) }
        } else {
            raw = inRange
                .sorted { $0.timestamp < $1.timestamp }
                .map { WeightPoint(date: $0.timestamp, weightKg: $0.weightKg) }
        }

        trend = AnalyticsEngine
            .trendSeries(buckets: buckets, windowDays: windowDays, calendar: calendar)
            .map { WeightPoint(date: $0.day, weightKg: $0.weightKg) }
    }
}
