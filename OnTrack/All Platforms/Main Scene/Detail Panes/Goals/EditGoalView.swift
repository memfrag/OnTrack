//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftData
import AppRouting

/// Sheet for creating or editing the single active goal.
///
/// The goal can be in either direction — the target may be below the start (loss) or above
/// it (gain). Weights are entered in the active unit and stored as kilograms.
///
struct EditGoalView: View {

    @Environment(Router<MainRouting>.self) private var router
    @Environment(WeightRepository.self) private var repository
    @Environment(AppSettings.self) private var appSettings

    @Query(sort: \WeightGoal.createdAt, order: .reverse) private var goals: [WeightGoal]
    @Query(sort: \WeightEntry.timestamp, order: .reverse) private var entries: [WeightEntry]

    @State private var targetText: String = ""
    @State private var startText: String = ""
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = .now
    @State private var didLoad = false

    private var unit: WeightUnit { appSettings.weightUnit }
    private var existingGoal: WeightGoal? { goals.first }

    private var targetValue: Double? { parse(targetText) }
    private var startValue: Double? { parse(startText) }

    private var isValid: Bool {
        (targetValue ?? 0) > 0 && (startValue ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Target") {
                    weightField("Target Weight", text: $targetText)
                    Toggle("Set Target Date", isOn: $hasTargetDate.animation())
                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                    }
                }

                Section {
                    weightField("Starting Weight", text: $startText)
                } header: {
                    Text("Start")
                } footer: {
                    Text("Progress is measured from your starting weight toward the target.")
                }

                if existingGoal != nil {
                    Section {
                        Button("Remove Goal", role: .destructive, action: removeGoal)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(existingGoal == nil ? "New Goal" : "Edit Goal")
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
            .onAppear(perform: loadIfNeeded)
        }
    }

    @ViewBuilder private func weightField(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0.0", text: text)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .monospacedDigit()
            Text(unit.symbol)
                .foregroundStyle(.secondary)
        }
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true

        if let goal = existingGoal {
            targetText = unit.formatted(fromKg: goal.targetWeightKg)
            startText = unit.formatted(fromKg: goal.startWeightKg)
            if let date = goal.targetDate {
                hasTargetDate = true
                targetDate = date
            }
        } else {
            // Default the start weight to the current trend (or latest entry).
            if let reference = AnalyticsEngine.currentTrend(entries) ?? entries.first?.weightKg {
                startText = unit.formatted(fromKg: reference)
            }
        }
    }

    private func save() {
        guard let target = targetValue, let start = startValue, target > 0, start > 0 else { return }
        repository.setGoal(
            targetWeightKg: unit.kg(fromValue: target),
            targetDate: hasTargetDate ? targetDate : nil,
            startWeightKg: unit.kg(fromValue: start),
            startDate: existingGoal?.startDate ?? .now
        )
        router.dismiss()
    }

    private func removeGoal() {
        repository.clearGoal()
        router.dismiss()
    }

    private func parse(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }
}

// MARK: - Preview

#Preview {
    EditGoalView()
        .appEnvironment(.mock())
}
