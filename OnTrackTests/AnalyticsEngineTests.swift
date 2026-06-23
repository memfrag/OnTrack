//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Testing
import Foundation
@testable import OnTrack

struct AnalyticsEngineTests {

    @Test func dailyBucketsAveragesMultipleEntriesPerDay() {
        let samples = [
            Sample(timestamp: .test(2026, 6, 1, hour: 7), weightKg: 70),
            Sample(timestamp: .test(2026, 6, 1, hour: 20), weightKg: 72),
            Sample(timestamp: .test(2026, 6, 2, hour: 8), weightKg: 71)
        ]
        let buckets = AnalyticsEngine.dailyBuckets(samples, calendar: utcCalendar)
        #expect(buckets.count == 2)
        #expect(buckets[0].weightKg == 71) // (70 + 72) / 2
        #expect(buckets[1].weightKg == 71)
    }

    @Test func trendAveragesAvailableDaysInSparseWindow() {
        // Only two days of data in the trailing 7-day window — average just those.
        let samples = [
            Sample(timestamp: .test(2026, 6, 1), weightKg: 80),
            Sample(timestamp: .test(2026, 6, 5), weightKg: 76)
        ]
        let buckets = AnalyticsEngine.dailyBuckets(samples, calendar: utcCalendar)
        let trend = AnalyticsEngine.trendValue(
            on: .test(2026, 6, 5), buckets: buckets, windowDays: 7, calendar: utcCalendar
        )
        #expect(trend == 78) // (80 + 76) / 2
    }

    @Test func trendExcludesDaysOutsideWindow() {
        let samples = [
            Sample(timestamp: .test(2026, 6, 1), weightKg: 80), // 8 days before the 9th → excluded
            Sample(timestamp: .test(2026, 6, 9), weightKg: 70)
        ]
        let buckets = AnalyticsEngine.dailyBuckets(samples, calendar: utcCalendar)
        let trend = AnalyticsEngine.trendValue(
            on: .test(2026, 6, 9), buckets: buckets, windowDays: 7, calendar: utcCalendar
        )
        #expect(trend == 70)
    }

    @Test func currentTrendUsesMostRecentDay() {
        let samples = (0..<7).map { offset in
            Sample(timestamp: .test(2026, 6, 1 + offset), weightKg: 70 + Double(offset))
        }
        // Days 70...76 → mean = 73.
        let current = AnalyticsEngine.currentTrend(samples, windowDays: 7, calendar: utcCalendar)
        #expect(current == 73)
    }

    @Test func weeklyChangeComparesTrendOneWeekApart() {
        // Day 1: 80, then steady decline to day 15.
        var samples: [Sample] = []
        for day in 1...15 {
            samples.append(Sample(timestamp: .test(2026, 6, day), weightKg: 80 - Double(day - 1) * 0.5))
        }
        let change = AnalyticsEngine.weeklyChange(samples, windowDays: 7, calendar: utcCalendar)
        #expect(change != nil)
        #expect(change! < 0) // losing weight
    }

    @Test func statisticsReportsHighLowAverageAndCount() {
        let samples = [
            Sample(timestamp: .test(2026, 6, 1), weightKg: 70),
            Sample(timestamp: .test(2026, 6, 2), weightKg: 74),
            Sample(timestamp: .test(2026, 6, 3), weightKg: 72)
        ]
        let stats = AnalyticsEngine.statistics(samples, calendar: utcCalendar)
        #expect(stats.highestKg == 74)
        #expect(stats.lowestKg == 70)
        #expect(stats.averageKg == 72)
        #expect(stats.measurementCount == 3)
    }

    @Test func statisticsWeeklyLossIsNonPositiveAndGainNonNegative() {
        var samples: [Sample] = []
        for day in 1...21 {
            samples.append(Sample(timestamp: .test(2026, 6, day), weightKg: 80 - Double(day) * 0.3))
        }
        let stats = AnalyticsEngine.statistics(samples, calendar: utcCalendar)
        if let loss = stats.largestWeeklyLossKg { #expect(loss <= 0) }
        if let gain = stats.largestWeeklyGainKg { #expect(gain >= 0) }
    }

    @Test func emptyEntriesProduceEmptyStatistics() {
        let stats = AnalyticsEngine.statistics([], calendar: utcCalendar)
        #expect(stats == .empty)
        #expect(AnalyticsEngine.currentTrend([], calendar: utcCalendar) == nil)
        #expect(AnalyticsEngine.weeklyChange([], calendar: utcCalendar) == nil)
    }
}
