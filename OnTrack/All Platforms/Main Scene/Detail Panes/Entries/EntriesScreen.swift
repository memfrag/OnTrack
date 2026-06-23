//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftData
import AppRouting

/// Lists all weigh-ins with search, edit, and delete.
///
/// On iPhone/iPad this is a `List`; on macOS it's a `Table`. Every entry is editable and
/// deletable regardless of source (this is a manual-only app).
///
struct EntriesScreen: View {

    @Environment(Router<MainRouting>.self) private var router
    @Environment(AppSettings.self) private var appSettings
    @Environment(WeightRepository.self) private var repository

    @Query(sort: \WeightEntry.timestamp, order: .reverse) private var entries: [WeightEntry]

    @State private var searchText: String = ""
    @State private var selectedID: WeightEntry.ID?

    private var unit: WeightUnit { appSettings.weightUnit }

    private var filteredEntries: [WeightEntry] {
        guard !searchText.isEmpty else { return entries }
        let query = searchText.lowercased()
        return entries.filter { entry in
            let note = entry.note?.lowercased() ?? ""
            let source = entry.source.label.lowercased()
            let weight = unit.formatted(fromKg: entry.weightKg)
            let date = entry.timestamp.formatted(date: .abbreviated, time: .omitted).lowercased()
            return note.contains(query)
                || source.contains(query)
                || weight.contains(query)
                || date.contains(query)
        }
    }

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router[.entries]) {
            Group {
                if entries.isEmpty {
                    EmptyStateView(
                        title: "No Entries Yet",
                        message: "Add your first weight to start tracking your trend.",
                        systemImage: "list.bullet.clipboard",
                        actionTitle: "Add Weight"
                    ) {
                        router.presentSheet(.addWeight)
                    }
                } else {
                    content
                }
            }
            .navigationTitle("Entries")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    AddWeightToolbarButton()
                }
            }
            .mainPushableDestinations()
        }
        .searchable(text: $searchText, prompt: "Search entries")
    }

    @ViewBuilder private var content: some View {
        #if os(macOS)
        Table(filteredEntries, selection: $selectedID) {
            TableColumn("Date") { entry in
                Text(entry.timestamp.formatted(date: .abbreviated, time: .omitted))
            }
            TableColumn("Time") { entry in
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
            }
            TableColumn("Weight") { entry in
                Text(unit.formattedWithSymbol(fromKg: entry.weightKg))
            }
            TableColumn("Source") { entry in
                Label(entry.source.label, systemImage: entry.source.systemImage)
            }
            TableColumn("Note") { entry in
                Text(entry.note ?? "")
                    .foregroundStyle(.secondary)
            }
        }
        .contextMenu(forSelectionType: WeightEntry.ID.self) { ids in
            if let id = ids.first, let entry = entry(for: id) {
                Button("Edit…") { router.presentSheet(.editEntry(entry.id)) }
                Button("Delete", role: .destructive) { repository.deleteEntry(entry) }
            }
        } primaryAction: { ids in
            if let id = ids.first, let entry = entry(for: id) {
                router.presentSheet(.editEntry(entry.id))
            }
        }
        #else
        List {
            ForEach(filteredEntries) { entry in
                Button {
                    router.presentSheet(.editEntry(entry.id))
                } label: {
                    EntryRow(entry: entry, unit: unit)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: delete)
        }
        #endif
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            repository.deleteEntry(filteredEntries[index])
        }
    }

    private func entry(for id: WeightEntry.ID) -> WeightEntry? {
        entries.first { $0.id == id }
    }
}

// MARK: - Row

private struct EntryRow: View {
    let entry: WeightEntry
    let unit: WeightUnit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.body)
                HStack(spacing: 6) {
                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                    Label(entry.source.label, systemImage: entry.source.systemImage)
                        .labelStyle(.titleAndIcon)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(unit.formattedWithSymbol(fromKg: entry.weightKg))
                .font(.body.weight(.semibold))
                .monospacedDigit()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    EntriesScreen()
        .appEnvironment(.mock())
}
