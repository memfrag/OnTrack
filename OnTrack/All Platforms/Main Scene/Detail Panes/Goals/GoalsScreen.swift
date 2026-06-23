//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftData
import AppRouting

/// Create, edit, and remove the active weight goal, with progress, weekly pace, and forecast.
struct GoalsScreen: View {

    @Environment(Router<MainRouting>.self) private var router
    @Environment(AppSettings.self) private var appSettings

    @Query(sort: \WeightGoal.createdAt, order: .reverse) private var goals: [WeightGoal]
    @Query(sort: \WeightEntry.timestamp, order: .reverse) private var entries: [WeightEntry]

    private var unit: WeightUnit { appSettings.weightUnit }
    private var goal: WeightGoal? { goals.first }
    private var referenceWeightKg: Double? {
        AnalyticsEngine.currentTrend(entries) ?? entries.first?.weightKg
    }
    private var weeklyChangeKg: Double? { AnalyticsEngine.weeklyChange(entries) }

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router[.goals]) {
            Group {
                if let goal {
                    ScrollView {
                        VStack(spacing: 16) {
                            GoalProgressCard(
                                goal: goal,
                                currentWeightKg: referenceWeightKg,
                                unit: unit,
                                onEdit: { router.presentSheet(.editGoal) }
                            )
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForecastTile(
                                    entries: entries,
                                    goal: goal,
                                    referenceWeightKg: referenceWeightKg,
                                    unit: unit
                                )
                                if let weeklyChangeKg {
                                    StatTile(
                                        title: "Weekly Pace",
                                        value: unit.formattedDeltaWithSymbol(fromKg: weeklyChangeKg),
                                        caption: "Per week",
                                        systemImage: "speedometer"
                                    )
                                }
                                if let date = goal.targetDate {
                                    StatTile(
                                        title: "Target Date",
                                        value: date.formatted(date: .abbreviated, time: .omitted),
                                        systemImage: "flag.checkered"
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    EmptyStateView(
                        title: "No Goal Set",
                        message: "Set a target weight to track your progress and see a projected date.",
                        systemImage: "target",
                        actionTitle: "Set a Goal"
                    ) {
                        router.presentSheet(.editGoal)
                    }
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        router.presentSheet(.editGoal)
                    } label: {
                        Label(goal == nil ? "Set Goal" : "Edit Goal", systemImage: "target")
                    }
                }
            }
            .mainPushableDestinations()
        }
    }
}

// MARK: - Preview

#Preview {
    GoalsScreen()
        .appEnvironment(.mock())
}
