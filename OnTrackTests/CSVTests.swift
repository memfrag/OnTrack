//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Testing
import Foundation
@testable import OnTrack

struct CSVTests {

    @Test func parsesValidRowsAndSkipsHeader() {
        let csv = """
        timestamp,weight_kg,source,note
        2026-06-23T07:30:00Z,72.4,manual,Felt good
        2026-06-24T07:30:00Z,72.1,withings,
        """
        let result = CSVImporter.parse(csv)
        #expect(result.rows.count == 2)
        #expect(result.rejected.isEmpty)
        #expect(result.rows[0].weightKg == 72.4)
        #expect(result.rows[0].source == .manual)
        #expect(result.rows[0].note == "Felt good")
        #expect(result.rows[1].source == .withings)
        #expect(result.rows[1].note == nil)
    }

    @Test func rejectsInvalidTimestampAndNonPositiveWeight() {
        let csv = """
        not-a-date,70,manual,
        2026-06-23T07:30:00Z,0,manual,
        2026-06-24T07:30:00Z,-5,manual,
        2026-06-25T07:30:00Z,71.0,manual,
        """
        let result = CSVImporter.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.rejected.count == 3)
    }

    @Test func handlesQuotedNoteContainingComma() {
        let csv = "2026-06-23T07:30:00Z,72.4,manual,\"Morning, after run\""
        let result = CSVImporter.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.rows[0].note == "Morning, after run")
    }

    @Test func parsesTimestampWithFractionalSeconds() {
        let csv = "2026-06-23T07:30:00.500Z,72.4,manual,"
        let result = CSVImporter.parse(csv)
        #expect(result.rows.count == 1)
    }

    @Test func exportRoundTripsThroughImport() {
        let entries = [
            WeightEntry(timestamp: .test(2026, 6, 1), weightKg: 72.4, source: .manual, note: "A"),
            WeightEntry(timestamp: .test(2026, 6, 2), weightKg: 71.9, source: .withings)
        ]
        let csv = CSVExporter.export(entries)
        let parsed = CSVImporter.parse(csv)
        #expect(parsed.rows.count == 2)
        #expect(parsed.rejected.isEmpty)
        // Full-precision weights survive the round trip.
        #expect(parsed.rows.contains { $0.weightKg == 72.4 })
        #expect(parsed.rows.contains { $0.weightKg == 71.9 })
    }

    @Test func exportEscapesNotesWithCommas() {
        let entries = [WeightEntry(timestamp: .test(2026, 6, 1), weightKg: 72.4, note: "after, run")]
        let csv = CSVExporter.export(entries)
        #expect(csv.contains("\"after, run\""))
    }
}
