//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Shows progress toward the active goal: amount done of total, a progress bar, target,
/// and remaining. Reused on Overview and Goals.
///
struct GoalProgressCard: View {

    let goal: WeightGoal
    let currentWeightKg: Double?
    let unit: WeightUnit
    var onEdit: (() -> Void)?

    private var progress: Double {
        guard let currentWeightKg else { return 0 }
        return goal.progress(currentWeightKg: currentWeightKg)
    }

    private var remainingKg: Double? {
        guard let currentWeightKg else { return nil }
        return goal.remainingKg(currentWeightKg: currentWeightKg)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goal Progress")
                    .font(.headline)
                Spacer()
                if let onEdit {
                    Button("Edit Goal", action: onEdit)
                        .font(.subheadline)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(unit.formatted(fromKg: goal.totalChangeKg * progress))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("of \(unit.formattedWithSymbol(fromKg: goal.totalChangeKg)) goal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(.accentColor)

            HStack {
                LabeledValue(label: "Start", value: unit.formattedWithSymbol(fromKg: goal.startWeightKg))
                Spacer()
                LabeledValue(label: "Target", value: unit.formattedWithSymbol(fromKg: goal.targetWeightKg))
                Spacer()
                if let remainingKg {
                    LabeledValue(label: "Remaining", value: unit.formattedWithSymbol(fromKg: remainingKg))
                }
                Spacer()
                LabeledValue(label: "Complete", value: "\(Int((progress * 100).rounded()))%")
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct LabeledValue: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
        }
    }
}
