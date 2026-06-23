//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

#if os(macOS)

import SwiftUI
import SwiftData
import AppRouting

/// The macOS sidebar footer: today's weight, the goal + progress, and a quick Add Weight button.
///
/// Mirrors the layout in the macOS mockup. The progress here uses the latest measurement; the
/// Overview uses the smoothed trend. Refined alongside the analytics work.
///
struct SidebarSummary: View {

    @Environment(AppSettings.self) private var appSettings
    @Environment(Router<MainRouting>.self) private var router

    @Query(sort: \WeightEntry.timestamp, order: .reverse) private var entries: [WeightEntry]
    @Query(sort: \WeightGoal.createdAt, order: .reverse) private var goals: [WeightGoal]

    private var unit: WeightUnit { appSettings.weightUnit }
    private var latest: WeightEntry? { entries.first }
    private var goal: WeightGoal? { goals.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            if let latest {
                LabeledSummary(title: "TODAY", value: unit.formattedWithSymbol(fromKg: latest.weightKg))
            }

            if let goal {
                LabeledSummary(title: "GOAL", value: unit.formattedWithSymbol(fromKg: goal.targetWeightKg))
                if let latest {
                    ProgressView(value: goal.progress(currentWeightKg: latest.weightKg))
                        .tint(.accentColor)
                }
            }

            Button {
                router.presentSheet(.addWeight)
            } label: {
                Label("Add Weight", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
    }
}

private struct LabeledSummary: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
    }
}

#endif
