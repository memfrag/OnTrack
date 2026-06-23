//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// A single calendar day's aggregated weight, in kilograms.
public struct DailyValue: Equatable, Sendable {
    /// The start of the local calendar day.
    public let day: Date
    /// The mean of that day's weigh-ins, in kilograms.
    public let weightKg: Double
}

/// Summary statistics over a set of entries.
public struct WeightStatistics: Equatable, Sendable {
    public let highestKg: Double?
    public let lowestKg: Double?
    public let averageKg: Double?
    public let largestWeeklyLossKg: Double?
    public let largestWeeklyGainKg: Double?
    public let measurementCount: Int

    public static let empty = WeightStatistics(
        highestKg: nil, lowestKg: nil, averageKg: nil,
        largestWeeklyLossKg: nil, largestWeeklyGainKg: nil, measurementCount: 0
    )
}

/// Pure, stateless analytics over weight measurements.
///
/// All computation operates on kilograms. The trend is a **daily-bucketed, trailing
/// calendar-day moving average**: each local calendar day is collapsed to the mean of its
/// weigh-ins, and the trend for a day is the mean of the daily values over the trailing
/// window. Windows with fewer days than the nominal size simply average whatever days exist.
///
/// This type has no dependencies on SwiftData or SwiftUI so it is trivially unit-testable.
///
public enum AnalyticsEngine {

    /// The default trend window, in days.
    public static let defaultWindowDays = 7

    // MARK: - Daily buckets

    /// Collapses entries to one value per local calendar day (the mean of that day's weigh-ins),
    /// sorted ascending by day.
    ///
    /// - Parameters:
    ///   - entries: The measurements to bucket (any order).
    ///   - calendar: The calendar defining day boundaries. Defaults to `.current`.
    ///
    public static func dailyBuckets(
        _ entries: [WeightSample],
        calendar: Calendar = .current
    ) -> [DailyValue] {
        guard !entries.isEmpty else { return [] }

        var sums: [Date: (total: Double, count: Int)] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.timestamp)
            let existing = sums[day] ?? (0, 0)
            sums[day] = (existing.total + entry.weightKg, existing.count + 1)
        }

        return sums
            .map { DailyValue(day: $0.key, weightKg: $0.value.total / Double($0.value.count)) }
            .sorted { $0.day < $1.day }
    }

    // MARK: - Trend

    /// The trend value on a given day: the mean of daily buckets within the trailing window
    /// `[day - (windowDays - 1), day]`. Averages whatever days exist; returns `nil` if none.
    public static func trendValue(
        on day: Date,
        buckets: [DailyValue],
        windowDays: Int = defaultWindowDays,
        calendar: Calendar = .current
    ) -> Double? {
        let dayStart = calendar.startOfDay(for: day)
        guard let windowStart = calendar.date(byAdding: .day, value: -(windowDays - 1), to: dayStart) else {
            return nil
        }
        let values = buckets
            .filter { $0.day >= windowStart && $0.day <= dayStart }
            .map(\.weightKg)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// The trend value for each day that has a bucket, producing a smooth series for charting.
    public static func trendSeries(
        buckets: [DailyValue],
        windowDays: Int = defaultWindowDays,
        calendar: Calendar = .current
    ) -> [DailyValue] {
        buckets.compactMap { bucket in
            guard let value = trendValue(
                on: bucket.day, buckets: buckets, windowDays: windowDays, calendar: calendar
            ) else { return nil }
            return DailyValue(day: bucket.day, weightKg: value)
        }
    }

    /// The current trend weight: the trend value on the most recent day with data.
    public static func currentTrend(
        _ entries: [WeightSample],
        windowDays: Int = defaultWindowDays,
        calendar: Calendar = .current
    ) -> Double? {
        let buckets = dailyBuckets(entries, calendar: calendar)
        guard let last = buckets.last else { return nil }
        return trendValue(on: last.day, buckets: buckets, windowDays: windowDays, calendar: calendar)
    }

    /// The change in trend over the last week: `trend(latestDay) - trend(latestDay - 7 days)`.
    /// Returns `nil` if there isn't enough data to evaluate both points.
    public static func weeklyChange(
        _ entries: [WeightSample],
        windowDays: Int = defaultWindowDays,
        calendar: Calendar = .current
    ) -> Double? {
        let buckets = dailyBuckets(entries, calendar: calendar)
        guard let last = buckets.last,
              let priorDay = calendar.date(byAdding: .day, value: -7, to: last.day) else {
            return nil
        }
        guard let current = trendValue(on: last.day, buckets: buckets, windowDays: windowDays, calendar: calendar),
              let prior = trendValue(on: priorDay, buckets: buckets, windowDays: windowDays, calendar: calendar) else {
            return nil
        }
        return current - prior
    }

    // MARK: - Statistics

    /// Computes summary statistics over the given entries.
    ///
    /// `highest` / `lowest` / `average` are over raw measurements; `largestWeekly*` use
    /// trend-based 7-day deltas (`trend(day) - trend(day - 7)`) scanned across the trend series.
    ///
    public static func statistics(
        _ entries: [WeightSample],
        windowDays: Int = defaultWindowDays,
        calendar: Calendar = .current
    ) -> WeightStatistics {
        guard !entries.isEmpty else { return .empty }

        let weights = entries.map(\.weightKg)
        let highest = weights.max()
        let lowest = weights.min()
        let average = weights.reduce(0, +) / Double(weights.count)

        let buckets = dailyBuckets(entries, calendar: calendar)
        var largestLoss: Double?
        var largestGain: Double?

        for bucket in buckets {
            guard let priorDay = calendar.date(byAdding: .day, value: -7, to: bucket.day),
                  let current = trendValue(on: bucket.day, buckets: buckets, windowDays: windowDays, calendar: calendar),
                  let prior = trendValue(on: priorDay, buckets: buckets, windowDays: windowDays, calendar: calendar)
            else { continue }
            let delta = current - prior
            if delta < (largestLoss ?? .greatestFiniteMagnitude) { largestLoss = delta }
            if delta > (largestGain ?? -.greatestFiniteMagnitude) { largestGain = delta }
        }

        return WeightStatistics(
            highestKg: highest,
            lowestKg: lowest,
            averageKg: average,
            largestWeeklyLossKg: largestLoss.map { min($0, 0) },
            largestWeeklyGainKg: largestGain.map { max($0, 0) },
            measurementCount: entries.count
        )
    }
}

/// A minimal measurement value used by ``AnalyticsEngine``.
///
/// Decoupling the engine from `WeightEntry` keeps it pure and testable. `WeightEntry`
/// conforms to this protocol (see the conformance in the model layer).
public protocol WeightSample {
    var timestamp: Date { get }
    var weightKg: Double { get }
}
