//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import SwiftData

/// A single weight measurement.
///
/// The canonical weight is always stored in kilograms (`weightKg`) at full precision;
/// unit conversion happens only at display time. See ``WeightUnit``.
///
/// - Note: The model is intentionally CloudKit-compatible: every stored property has a
///   default value or is optional, and there are no `.unique` attributes or enforced
///   uniqueness constraints. This lets CloudKit sync be enabled later without a migration.
///
@Model
public final class WeightEntry {

    /// A stable identifier for the entry, independent of SwiftData's `persistentModelID`.
    /// Used as the payload when routing to the edit sheet.
    public var id: UUID = UUID()

    /// The moment the measurement was taken.
    public var timestamp: Date = Date.now

    /// The measured weight, in kilograms, stored at full precision.
    public var weightKg: Double = 0

    /// The raw value backing ``source``. Stored as `String` for CloudKit compatibility.
    public var sourceRaw: String = EntrySource.manual.rawValue

    /// An optional free-form note.
    public var note: String?

    /// An optional external identifier (e.g. a Withings measurement id) used for deduplication.
    public var externalMeasurementId: String?

    /// When the record was first created.
    public var createdAt: Date = Date.now

    /// When the record was last modified.
    public var updatedAt: Date = Date.now

    /// The origin of the entry, bridged to ``sourceRaw`` for storage.
    public var source: EntrySource {
        get { EntrySource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        weightKg: Double,
        source: EntrySource = .manual,
        note: String? = nil,
        externalMeasurementId: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.timestamp = timestamp
        self.weightKg = weightKg
        self.sourceRaw = source.rawValue
        self.note = note
        self.externalMeasurementId = externalMeasurementId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
