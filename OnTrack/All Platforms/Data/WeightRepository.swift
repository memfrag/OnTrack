//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import SwiftData
import OSLog

/// The result of a CSV import operation.
public struct CSVImportResult: Sendable, Equatable {
    /// Number of rows inserted as new entries.
    public let imported: Int
    /// Number of valid rows skipped because they duplicated an existing entry.
    public let skipped: Int
    /// Number of rows rejected because they failed validation.
    public let rejected: Int

    public var total: Int { imported + skipped + rejected }
}

/// Owns all mutations of the weight data store.
///
/// Reads in SwiftUI views should generally go through `@Query` for automatic updates; this
/// repository centralizes *writes* (add / update / delete / goal / CSV) plus the handful of
/// fetches needed by non-view code (onboarding, CSV export, analytics inputs). Keeping
/// mutations here keeps them testable and off the views.
///
@Observable @MainActor
public final class WeightRepository {

    @ObservationIgnored
    public let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Entries

    /// All entries, most recent first.
    public func allEntries() -> [WeightEntry] {
        let descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Entries whose timestamp falls within the given date range, most recent first.
    public func entries(in range: ClosedRange<Date>) -> [WeightEntry] {
        let lower = range.lowerBound
        let upper = range.upperBound
        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate { $0.timestamp >= lower && $0.timestamp <= upper },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// The most recent entry, if any.
    public func latestEntry() -> WeightEntry? {
        var descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    /// Inserts a new manual (or sourced) entry.
    @discardableResult
    public func addEntry(
        weightKg: Double,
        timestamp: Date,
        note: String? = nil,
        source: EntrySource = .manual,
        externalMeasurementId: String? = nil
    ) -> WeightEntry {
        let entry = WeightEntry(
            timestamp: timestamp,
            weightKg: weightKg,
            source: source,
            note: note,
            externalMeasurementId: externalMeasurementId
        )
        modelContext.insert(entry)
        save()
        return entry
    }

    /// Applies edits to an existing entry and bumps its `updatedAt`.
    public func updateEntry(
        _ entry: WeightEntry,
        weightKg: Double,
        timestamp: Date,
        note: String?
    ) {
        entry.weightKg = weightKg
        entry.timestamp = timestamp
        entry.note = note
        entry.updatedAt = .now
        save()
    }

    /// Deletes an entry.
    public func deleteEntry(_ entry: WeightEntry) {
        modelContext.delete(entry)
        save()
    }

    /// Finds an entry by its stable `id`.
    public func entry(withID id: UUID) -> WeightEntry? {
        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }

    // MARK: - Goal

    /// The active goal, if one exists. Only one goal is kept; the most recently created wins.
    public func activeGoal() -> WeightGoal? {
        var descriptor = FetchDescriptor<WeightGoal>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    /// Creates or replaces the active goal. Any existing goals are removed first so there is
    /// always at most one.
    @discardableResult
    public func setGoal(
        targetWeightKg: Double,
        targetDate: Date?,
        startWeightKg: Double,
        startDate: Date = .now
    ) -> WeightGoal {
        clearGoal()
        let goal = WeightGoal(
            targetWeightKg: targetWeightKg,
            targetDate: targetDate,
            startWeightKg: startWeightKg,
            startDate: startDate
        )
        modelContext.insert(goal)
        save()
        return goal
    }

    /// Removes all goals.
    public func clearGoal() {
        let goals = (try? modelContext.fetch(FetchDescriptor<WeightGoal>())) ?? []
        for goal in goals {
            modelContext.delete(goal)
        }
        save()
    }

    // MARK: - CSV

    /// Imports entries from CSV text, skipping exact duplicates.
    ///
    /// A row is considered a duplicate of an existing entry when it shares the same timestamp
    /// and `weightKg` (matching the spec's primary/fallback dedup). Per-row `source` is trusted;
    /// every imported entry remains editable. Invalid rows are rejected and counted.
    ///
    @discardableResult
    public func importCSV(_ text: String) -> CSVImportResult {
        let parsed = CSVImporter.parse(text)

        // Build a set of existing (timestamp, weight) keys for fast dedup, and track within-import dupes.
        var seen = Set<DedupKey>(allEntries().map { DedupKey(timestamp: $0.timestamp, weightKg: $0.weightKg) })

        var imported = 0
        var skipped = 0

        for row in parsed.rows {
            let key = DedupKey(timestamp: row.timestamp, weightKg: row.weightKg)
            if seen.contains(key) {
                skipped += 1
                continue
            }
            seen.insert(key)
            modelContext.insert(WeightEntry(
                timestamp: row.timestamp,
                weightKg: row.weightKg,
                source: row.source,
                note: row.note
            ))
            imported += 1
        }

        if imported > 0 {
            recordImportDate()
        }
        save()

        return CSVImportResult(imported: imported, skipped: skipped, rejected: parsed.rejected.count)
    }

    /// Serializes all entries to CSV text.
    public func exportCSV() -> String {
        CSVExporter.export(allEntries())
    }

    // MARK: - Sync metadata

    private func recordImportDate() {
        let metadata = (try? modelContext.fetch(FetchDescriptor<SyncMetadata>()))?.first
            ?? {
                let new = SyncMetadata()
                modelContext.insert(new)
                return new
            }()
        metadata.lastImportDate = .now
    }

    // MARK: - Saving

    private func save() {
        do {
            try modelContext.save()
        } catch {
            Logger.data.error("Failed to save model context: \(error.localizedDescription)")
        }
    }

    private struct DedupKey: Hashable {
        let timestamp: Date
        let weightKg: Double
    }
}

extension Logger {
    /// Logger for the data / persistence layer.
    static let data = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OnTrack", category: "Data")
}
