//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Displays the goal forecast as a stat tile: a projected date, or an honest
/// "off track" / "not enough data" message when no meaningful date exists.
///
struct ForecastTile: View {

    let entries: [WeightEntry]
    let goal: WeightGoal?
    let referenceWeightKg: Double?
    let unit: WeightUnit

    private var display: ForecastDisplay {
        ForecastDisplay(entries: entries, goal: goal)
    }

    var body: some View {
        StatTile(
            title: "Forecast",
            value: display.value,
            caption: display.caption,
            systemImage: "calendar",
            trend: display.trend
        )
    }
}

/// Maps a ``ForecastResult`` to human-readable text. Shared so Overview and Goals stay consistent.
struct ForecastDisplay {

    let value: String
    let caption: String?
    let trend: StatTile.Trend

    init(entries: [WeightEntry], goal: WeightGoal?) {
        guard let goal else {
            value = "No goal"
            caption = "Set a goal to forecast"
            trend = .neutral
            return
        }

        let result = ForecastEngine.forecast(entries: entries, targetWeightKg: goal.targetWeightKg)
        switch result {
        case .reached:
            value = "Reached 🎉"
            caption = "You hit your goal"
            trend = .good
        case .estimated(let date, _):
            value = date.formatted(date: .abbreviated, time: .omitted)
            let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
            caption = "About \(max(days, 0)) days to go"
            trend = .good
        case .offTrack:
            value = "Off track"
            caption = "Trending away from goal"
            trend = .bad
        case .insufficient:
            value = "—"
            caption = "Not enough progress to estimate"
            trend = .neutral
        }
    }
}
