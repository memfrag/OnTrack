//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

#if os(macOS)

import SwiftUI

/// The macOS "Recent Entries" card: a table of the most recent weigh-ins with a Change column,
/// matching the desktop mockup. Double-click a row to edit; "Show All" jumps to the Entries tab.
struct RecentEntriesTable: View {

    @Environment(WeightRepository.self) private var repository

    let entries: [WeightEntry]
    let unit: WeightUnit
    var onShowAll: () -> Void
    var onEdit: (UUID) -> Void

    private struct Row: Identifiable {
        let id: UUID
        let date: Date
        let weightKg: Double
        let changeKg: Double?
        let note: String?
    }

    /// Most recent entries (capped), each with the change vs the next-older measurement.
    private var rows: [Row] {
        let recent = Array(entries.prefix(8))
        return recent.enumerated().map { index, entry in
            let olderIndex = index + 1
            let change: Double?
            if olderIndex < entries.count {
                change = entry.weightKg - entries[olderIndex].weightKg
            } else {
                change = nil
            }
            return Row(id: entry.id, date: entry.timestamp, weightKg: entry.weightKg, changeKg: change, note: entry.note)
        }
    }

    @State private var selection: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Entries")
                    .font(.headline)
                Spacer()
                Button("Show All", action: onShowAll)
                    .buttonStyle(.borderless)
                    .font(.subheadline)
            }

            Table(rows, selection: $selection) {
                TableColumn("Date") { row in
                    Text(row.date.formatted(date: .abbreviated, time: .omitted))
                }
                TableColumn("Weight") { row in
                    Text(unit.formattedWithSymbol(fromKg: row.weightKg))
                        .monospacedDigit()
                }
                TableColumn("Change") { row in
                    if let change = row.changeKg {
                        Text(unit.formattedDeltaWithSymbol(fromKg: change))
                            .monospacedDigit()
                            .foregroundStyle(change <= 0 ? Color.green : Color.red)
                    } else {
                        Text("—").foregroundStyle(.secondary)
                    }
                }
                TableColumn("Note") { row in
                    Text(row.note ?? "")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(minHeight: 220)
            .contextMenu(forSelectionType: UUID.self) { ids in
                if let id = ids.first {
                    Button("Edit…") { onEdit(id) }
                    Button("Delete", role: .destructive) { delete(id) }
                }
            } primaryAction: { ids in
                if let id = ids.first { onEdit(id) }
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func delete(_ id: UUID) {
        if let entry = entries.first(where: { $0.id == id }) {
            repository.deleteEntry(entry)
        }
    }
}

#endif
