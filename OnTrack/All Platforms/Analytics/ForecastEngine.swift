//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// The outcome of projecting when a goal will be reached.
public enum ForecastResult: Equatable, Sendable {
    /// The goal has already been reached (trend is at or past the target).
    case reached
    /// A projected date, with the daily rate of change (kg/day, signed) used to compute it.
    case estimated(date: Date, dailyRateKg: Double)
    /// The trend is moving away from the target, so no meaningful date can be given.
    case offTrack
    /// There isn't enough data (or the rate is ≈ 0) to estimate.
    case insufficient
}

/// Pure goal-forecasting logic.
///
/// Computes the daily rate of change from a least-squares fit over the recent trend series,
/// then projects when the trend will reach the target. Honest about failure: if the trend is
/// moving away from the target, or the rate is negligible, it reports `.offTrack` /
/// `.insufficient` rather than an absurd date.
///
public enum ForecastEngine {

    /// The number of trailing days of trend used to estimate the daily rate.
    public static let rateWindowDays = 21

    /// A daily rate below this magnitude (kg/day) is treated as "no real movement".
    public static let negligibleRateKg = 0.005

    /// Projects when the goal will be reached.
    ///
    /// - Parameters:
    ///   - entries: All measurements (any order).
    ///   - targetWeightKg: The goal's target weight.
    ///   - today: The reference date for the projection. Defaults to now.
    ///   - windowDays: The trend window. Defaults to ``AnalyticsEngine/defaultWindowDays``.
    ///   - calendar: Calendar for day boundaries. Defaults to `.current`.
    ///
    public static func forecast(
        entries: [WeightSample],
        targetWeightKg: Double,
        today: Date = .now,
        windowDays: Int = AnalyticsEngine.defaultWindowDays,
        calendar: Calendar = .current
    ) -> ForecastResult {
        let buckets = AnalyticsEngine.dailyBuckets(entries, calendar: calendar)
        let trend = AnalyticsEngine.trendSeries(buckets: buckets, windowDays: windowDays, calendar: calendar)

        guard let currentTrend = trend.last?.weightKg else { return .insufficient }

        let remaining = currentTrend - targetWeightKg
        // Within one display rounding step of the target → consider it reached.
        if abs(remaining) < 0.05 { return .reached }

        guard let dailyRate = dailyRate(trend: trend, today: today, calendar: calendar) else {
            return .insufficient
        }

        if abs(dailyRate) < negligibleRateKg { return .insufficient }

        // remaining > 0 means we need to lose weight (rate must be negative);
        // remaining < 0 means we need to gain (rate must be positive).
        let movingTowardTarget = (remaining > 0 && dailyRate < 0) || (remaining < 0 && dailyRate > 0)
        guard movingTowardTarget else { return .offTrack }

        let days = abs(remaining / dailyRate)
        guard days.isFinite, days >= 0, days < 365 * 50 else { return .insufficient }

        guard let date = calendar.date(byAdding: .day, value: Int(days.rounded()), to: calendar.startOfDay(for: today)) else {
            return .insufficient
        }
        return .estimated(date: date, dailyRateKg: dailyRate)
    }

    /// Least-squares slope (kg/day) over the trailing ``rateWindowDays`` of the trend series.
    /// Returns `nil` if fewer than two trend points are available in the window.
    static func dailyRate(
        trend: [DailyValue],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> Double? {
        guard let lastDay = trend.last?.day,
              let windowStart = calendar.date(byAdding: .day, value: -(rateWindowDays - 1), to: lastDay) else {
            return nil
        }
        let recent = trend.filter { $0.day >= windowStart }
        guard recent.count >= 2 else { return nil }

        // x = days since windowStart, y = trend weight.
        let points: [(x: Double, y: Double)] = recent.map { value in
            let days = calendar.dateComponents([.day], from: windowStart, to: value.day).day ?? 0
            return (Double(days), value.weightKg)
        }

        let n = Double(points.count)
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
        let sumXX = points.reduce(0) { $0 + $1.x * $1.x }

        let denominator = n * sumXX - sumX * sumX
        guard abs(denominator) > .ulpOfOne else { return nil }

        return (n * sumXY - sumX * sumY) / denominator
    }
}
