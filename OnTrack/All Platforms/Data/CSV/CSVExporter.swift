//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Serializes ``WeightEntry`` values to the OnTrack CSV format.
///
/// Schema: `timestamp,weight_kg,source,note` with an ISO 8601 timestamp.
///
public enum CSVExporter {

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Produces a CSV document (including header) for the given entries.
    ///
    /// Entries are emitted in ascending timestamp order. The full-precision `weightKg`
    /// is written so exports round-trip without loss.
    ///
    public static func export(_ entries: [WeightEntry]) -> String {
        var lines = ["timestamp,weight_kg,source,note"]
        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            let timestamp = isoFormatter.string(from: entry.timestamp)
            let weight = String(entry.weightKg)
            let source = entry.source.rawValue
            let note = escape(entry.note ?? "")
            lines.append("\(timestamp),\(weight),\(source),\(note)")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Quotes a field if it contains a comma, quote, or newline, escaping embedded quotes.
    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else {
            return field
        }
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
