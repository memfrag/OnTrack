//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

#if os(macOS)

import SwiftUI

/// The macOS Goal Progress side panel: big remaining-of-total figure, progress bar, and a
/// vertical list of Start / Target / Weekly Pace, matching the desktop mockup's right column.
struct MacGoalPanel: View {

    let goal: WeightGoal
    let currentWeightKg: Double?
    let weeklyChangeKg: Double?
    let unit: WeightUnit
    var onEdit: () -> Void

    private var progress: Double {
        guard let currentWeightKg else { return 0 }
        return goal.progress(currentWeightKg: currentWeightKg)
    }

    private var achievedKg: Double { goal.totalChangeKg * progress }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Goal Progress")
                    .font(.headline)
                Spacer()
                Button("Edit Goal", action: onEdit)
                    .buttonStyle(.borderless)
                    .font(.subheadline)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(unit.formatted(fromKg: achievedKg))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("of \(unit.formattedWithSymbol(fromKg: goal.totalChangeKg)) goal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(.accentColor)

            VStack(spacing: 10) {
                row("Start", unit.formattedWithSymbol(fromKg: goal.startWeightKg))
                Divider()
                row("Target", unit.formattedWithSymbol(fromKg: goal.targetWeightKg),
                    detail: goal.targetDate?.formatted(date: .abbreviated, time: .omitted))
                Divider()
                row("Weekly Pace", weeklyChangeKg.map { unit.formattedDeltaWithSymbol(fromKg: $0) } ?? "—")
            }
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder private func row(_ label: String, _ value: String, detail: String? = nil) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(value)
                    .fontWeight(.medium)
                    .monospacedDigit()
                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.subheadline)
    }
}

#endif
