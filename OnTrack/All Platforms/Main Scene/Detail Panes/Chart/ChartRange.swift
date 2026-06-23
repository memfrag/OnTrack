//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// A selectable time range for the trend chart and statistics.
public enum ChartRange: String, CaseIterable, Identifiable, Sendable {
    case week
    case month
    case quarter
    case year
    case all

    public var id: Self { self }

    /// Short label for the segmented selector, e.g. `"7D"`.
    public var label: String {
        switch self {
        case .week: "7D"
        case .month: "30D"
        case .quarter: "90D"
        case .year: "1Y"
        case .all: "All"
        }
    }

    /// The number of days the range spans, or `nil` for "all".
    public var dayCount: Int? {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        case .year: 365
        case .all: nil
        }
    }

    /// Whether the raw series should be downsampled to daily buckets for performance/clarity.
    /// Long ranges (1Y / All) downsample; short ranges plot every measurement.
    public var downsamplesRaw: Bool {
        switch self {
        case .week, .month, .quarter: false
        case .year, .all: true
        }
    }

    /// The inclusive lower bound for this range relative to `now`, or `nil` for "all".
    public func startDate(now: Date = .now, calendar: Calendar = .current) -> Date? {
        guard let dayCount else { return nil }
        return calendar.date(byAdding: .day, value: -dayCount, to: now)
    }
}
