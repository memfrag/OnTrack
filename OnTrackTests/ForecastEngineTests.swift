//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Testing
import Foundation
@testable import OnTrack

struct ForecastEngineTests {

    /// A steady linear decline from `start` over `days`, one entry per day ending today.
    private func decliningSamples(start: Double, perDay: Double, days: Int, endingAt end: Date) -> [Sample] {
        (0..<days).map { offset in
            let date = utcCalendar.date(byAdding: .day, value: -(days - 1 - offset), to: end)!
            return Sample(timestamp: date, weightKg: start - perDay * Double(offset))
        }
    }

    @Test func estimatesDateWhenTrendingTowardTarget() {
        let today = Date.test(2026, 6, 30)
        let samples = decliningSamples(start: 80, perDay: 0.1, days: 30, endingAt: today)
        let result = ForecastEngine.forecast(
            entries: samples, targetWeightKg: 75, today: today, calendar: utcCalendar
        )
        guard case let .estimated(date, rate) = result else {
            Issue.record("Expected .estimated, got \(result)")
            return
        }
        #expect(rate < 0) // losing
        #expect(date > today) // in the future
    }

    @Test func reportsOffTrackWhenMovingAwayFromTarget() {
        let today = Date.test(2026, 6, 30)
        // Gaining weight, but target is below current → moving away.
        let samples = decliningSamples(start: 70, perDay: -0.1, days: 30, endingAt: today)
        let result = ForecastEngine.forecast(
            entries: samples, targetWeightKg: 65, today: today, calendar: utcCalendar
        )
        #expect(result == .offTrack)
    }

    @Test func reportsInsufficientWhenFlat() {
        let today = Date.test(2026, 6, 30)
        let samples = decliningSamples(start: 75, perDay: 0, days: 30, endingAt: today)
        let result = ForecastEngine.forecast(
            entries: samples, targetWeightKg: 70, today: today, calendar: utcCalendar
        )
        #expect(result == .insufficient)
    }

    @Test func reportsReachedWhenAtTarget() {
        let today = Date.test(2026, 6, 30)
        let samples = decliningSamples(start: 75, perDay: 0.1, days: 30, endingAt: today)
        let current = AnalyticsEngine.currentTrend(samples, calendar: utcCalendar)!
        let result = ForecastEngine.forecast(
            entries: samples, targetWeightKg: current, today: today, calendar: utcCalendar
        )
        #expect(result == .reached)
    }

    @Test func reportsInsufficientWithNoData() {
        let result = ForecastEngine.forecast(
            entries: [], targetWeightKg: 70, today: .test(2026, 6, 30), calendar: utcCalendar
        )
        #expect(result == .insufficient)
    }
}
