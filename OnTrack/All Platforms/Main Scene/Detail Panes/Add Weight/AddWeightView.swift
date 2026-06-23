//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppRouting

/// Sheet for adding a new weigh-in or editing an existing one.
///
/// Weight is entered in the user's active display unit and converted to canonical kilograms
/// on save (see ``WeightUnit``). Validation requires a positive weight.
///
struct AddWeightView: View {

    enum Mode: Equatable {
        case add
        case edit(UUID)
    }

    let mode: Mode

    @Environment(WeightRepository.self) private var repository
    @Environment(AppSettings.self) private var appSettings
    @Environment(Router<MainRouting>.self) private var router

    @State private var weightText: String = ""
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var loadedEntry: WeightEntry?

    @FocusState private var weightFieldFocused: Bool

    private var unit: WeightUnit { appSettings.weightUnit }

    private var enteredValue: Double? {
        Double(weightText.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        if let value = enteredValue { return value > 0 }
        return false
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date & Time", selection: $date)
                }

                Section {
                    HStack(alignment: .firstTextBaseline) {
                        TextField("0.0", text: $weightText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .focused($weightFieldFocused)
                        Text(unit.symbol)
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Weight")
                }

                Section("Notes (Optional)") {
                    TextField("Add a note", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Weight" : "Add Weight")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { router.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if case let .edit(id) = mode, let entry = repository.entry(withID: id) {
            loadedEntry = entry
            weightText = unit.formatted(fromKg: entry.weightKg)
            date = entry.timestamp
            note = entry.note ?? ""
        } else {
            // Pre-fill from the latest entry's weight as a convenient starting point.
            if let latest = repository.latestEntry() {
                weightText = unit.formatted(fromKg: latest.weightKg)
            }
            weightFieldFocused = true
        }
    }

    private func save() {
        guard let value = enteredValue, value > 0 else { return }
        let weightKg = unit.kg(fromValue: value)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = trimmedNote.isEmpty ? nil : trimmedNote

        if let entry = loadedEntry {
            repository.updateEntry(entry, weightKg: weightKg, timestamp: date, note: finalNote)
        } else {
            repository.addEntry(weightKg: weightKg, timestamp: date, note: finalNote)
        }
        router.dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddWeightView(mode: .add)
        .appEnvironment(.mock())
}
