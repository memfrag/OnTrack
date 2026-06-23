//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// A validated row parsed from a CSV file, ready to be turned into a ``WeightEntry``.
public struct CSVParsedRow: Equatable, Sendable {
    public let timestamp: Date
    public let weightKg: Double
    public let source: EntrySource
    public let note: String?
}

/// The outcome of attempting to parse a CSV document.
public struct CSVParseResult: Sendable {
    /// Rows that passed validation.
    public let rows: [CSVParsedRow]
    /// Rejected rows, paired with the 1-based line number and a human-readable reason.
    public let rejected: [(line: Int, reason: String)]
}

/// Parses and validates OnTrack CSV documents.
///
/// Expected schema (header optional but recommended):
/// ```
/// timestamp,weight_kg,source,note
/// 2026-06-23T07:30:00Z,72.4,manual,Felt good this morning
/// ```
///
/// Validation rules (per spec):
/// - `timestamp` must be present and parseable (ISO 8601, with or without fractional seconds).
/// - `weight_kg` must parse to a value greater than zero.
/// - Unknown / missing `source` defaults to `.manual`.
/// - Invalid rows are rejected and reported, never imported.
///
public enum CSVImporter {

    private static let isoFormatters: [ISO8601DateFormatter] = {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return [plain, withFractional]
    }()

    /// Parses the given CSV text into validated rows and a list of rejected rows.
    public static func parse(_ text: String) -> CSVParseResult {
        var rows: [CSVParsedRow] = []
        var rejected: [(line: Int, reason: String)] = []

        let lines = text
            .split(whereSeparator: \.isNewline)
            .map(String.init)

        for (index, rawLine) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            let fields = splitFields(rawLine)
            guard let first = fields.first else { continue }

            // Skip a header row.
            if index == 0, first.lowercased() == "timestamp" {
                continue
            }

            guard fields.count >= 2 else {
                rejected.append((lineNumber, "Expected at least timestamp and weight columns"))
                continue
            }

            let timestampField = fields[0].trimmingCharacters(in: .whitespaces)
            guard let timestamp = parseDate(timestampField) else {
                rejected.append((lineNumber, "Invalid or missing timestamp '\(timestampField)'"))
                continue
            }

            let weightField = fields[1].trimmingCharacters(in: .whitespaces)
            guard let weight = Double(weightField), weight > 0 else {
                rejected.append((lineNumber, "Invalid or non-positive weight '\(weightField)'"))
                continue
            }

            let source: EntrySource = fields.count > 2
                ? (EntrySource(rawValue: fields[2].trimmingCharacters(in: .whitespaces).lowercased()) ?? .manual)
                : .manual

            let note: String? = fields.count > 3
                ? {
                    let value = fields[3].trimmingCharacters(in: .whitespaces)
                    return value.isEmpty ? nil : value
                }()
                : nil

            rows.append(CSVParsedRow(timestamp: timestamp, weightKg: weight, source: source, note: note))
        }

        return CSVParseResult(rows: rows, rejected: rejected)
    }

    /// Parses an ISO 8601 date, tolerating presence or absence of fractional seconds.
    static func parseDate(_ string: String) -> Date? {
        for formatter in isoFormatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    /// Splits a single CSV line into fields, honoring double-quoted fields that may
    /// contain commas and escaped quotes (`""`).
    static func splitFields(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var insideQuotes = false
        var iterator = line.makeIterator()
        var pending: Character? = iterator.next()

        while let char = pending {
            pending = iterator.next()
            if insideQuotes {
                if char == "\"" {
                    if pending == "\"" {
                        current.append("\"")
                        pending = iterator.next()
                    } else {
                        insideQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else {
                switch char {
                case "\"":
                    insideQuotes = true
                case ",":
                    fields.append(current)
                    current = ""
                default:
                    current.append(char)
                }
            }
        }
        fields.append(current)
        return fields
    }
}
