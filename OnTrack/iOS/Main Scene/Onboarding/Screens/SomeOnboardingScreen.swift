//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

#if os(iOS)

import SwiftUI
import AppDesign

// MARK: - SomeOnboardingScreen

/// First-run setup: choose a unit and optionally record a starting weight and goal so the
/// dashboard has something to show immediately. Everything here is optional except the unit.
///
struct SomeOnboardingScreen: View {

    private let onCompletion: () -> Void

    @Environment(AppSettings.self) private var appSettings
    @Environment(WeightRepository.self) private var repository

    @State private var currentText: String = ""
    @State private var goalText: String = ""

    // MARK: Init

    init(onCompletion: @escaping () -> Void) {
        self.onCompletion = onCompletion
    }

    private var unit: WeightUnit { appSettings.weightUnit }

    // MARK: Body

    var body: some View {
        @Bindable var appSettings = appSettings

        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 44))
                            .foregroundStyle(.tint)
                        Text("Welcome to OnTrack")
                            .font(.title2.weight(.bold))
                        Text("Track your weight trend, not the daily noise.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section("Units") {
                    Picker("Weight Unit", selection: $appSettings.weightUnit) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    weightField("Current Weight", text: $currentText)
                    weightField("Goal Weight", text: $goalText)
                } header: {
                    Text("Optional")
                } footer: {
                    Text("You can add these later. A current and goal weight let OnTrack show your progress right away.")
                }
            }
            .navigationTitle("Get Started")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: complete) {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
            }
        }
    }

    @ViewBuilder private func weightField(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("Optional", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .monospacedDigit()
            Text(unit.symbol)
                .foregroundStyle(.secondary)
        }
    }

    private func complete() {
        let current = parse(currentText)
        let goal = parse(goalText)

        if let current {
            repository.addEntry(weightKg: unit.kg(fromValue: current), timestamp: .now)
        }
        if let goal, let current {
            repository.setGoal(
                targetWeightKg: unit.kg(fromValue: goal),
                targetDate: nil,
                startWeightKg: unit.kg(fromValue: current)
            )
        }
        onCompletion()
    }

    private func parse(_ text: String) -> Double? {
        let value = Double(text.replacingOccurrences(of: ",", with: "."))
        return (value ?? 0) > 0 ? value : nil
    }
}

// MARK: - Preview

#Preview {
    SomeOnboardingScreen {
        // On completion
    }
    .appEnvironment(.mock())
}

#endif
