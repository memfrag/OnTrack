//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
@testable import OnTrack

/// A lightweight `WeightSample` for exercising the pure engines without SwiftData.
struct Sample: WeightSample {
    let timestamp: Date
    let weightKg: Double
}

extension Date {
    /// Builds a fixed UTC date for deterministic tests.
    static func test(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components)!
    }
}

/// A UTC calendar so day-bucketing tests are independent of the machine's time zone.
let utcCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()
