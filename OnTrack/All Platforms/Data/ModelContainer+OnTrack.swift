//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import SwiftData

extension ModelContainer {

    /// The SwiftData schema for the app: all persisted model types.
    static var onTrackSchema: Schema {
        Schema([
            WeightEntry.self,
            WeightGoal.self,
            SyncMetadata.self
        ])
    }

    /// Builds the live, on-disk container used by the running app.
    ///
    /// CloudKit sync is intentionally disabled (`.none`) for now. The models are already
    /// CloudKit-compatible, so enabling sync later is a one-line change to `cloudKitDatabase`
    /// plus adding the iCloud capability and entitlement.
    ///
    @MainActor static func makeLive() -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: onTrackSchema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: onTrackSchema, configurations: configuration)
        } catch {
            fatalError("Failed to create live ModelContainer: \(error)")
        }
    }

    #if DEBUG
    /// Builds an in-memory container seeded with realistic sample data for previews and tests.
    ///
    /// - Parameter seeded: When `true`, the store is populated with ~120 days of sample
    ///   measurements and an active goal so charts, stats and the overview render meaningfully.
    ///
    @MainActor static func makeMock(seeded: Bool = true) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: onTrackSchema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(for: onTrackSchema, configurations: configuration)
            if seeded {
                SampleData.seed(into: container.mainContext)
            }
            return container
        } catch {
            fatalError("Failed to create mock ModelContainer: \(error)")
        }
    }
    #endif
}

#if DEBUG

/// Generates deterministic sample data for previews and tests.
enum SampleData {

    /// Seeds ~120 days of measurements with a gentle downward trend plus daily noise,
    /// and an active weight-loss goal.
    @MainActor static func seed(into context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let dayCount = 120
        let startWeight = 78.0
        let endWeight = 72.4
        let perDayTrend = (endWeight - startWeight) / Double(dayCount)

        for dayOffset in stride(from: dayCount, through: 0, by: -1) {
            // Skip ~30% of days so the data is realistically sparse.
            if dayOffset % 3 == 1 { continue }

            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            // Deterministic pseudo-noise via a sine wave keyed on the day index.
            let phase = Double(dayCount - dayOffset)
            let noise = sin(phase * 0.7) * 0.6 + sin(phase * 0.23) * 0.3
            let trendWeight = startWeight + perDayTrend * Double(dayCount - dayOffset)
            let weight = (trendWeight + noise)

            // Most mornings, around 07:30 local time.
            let timestamp = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: day) ?? day
            context.insert(WeightEntry(
                timestamp: timestamp,
                weightKg: (weight * 10).rounded() / 10,
                source: .manual
            ))
        }

        context.insert(WeightGoal(
            targetWeightKg: 68.0,
            targetDate: calendar.date(byAdding: .day, value: 90, to: today),
            startWeightKg: startWeight,
            startDate: calendar.date(byAdding: .day, value: -dayCount, to: today) ?? today
        ))

        try? context.save()
    }
}

#endif
