//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Cross-platform in-app settings, used on iPhone / iPad / visionOS.
///
/// macOS hosts settings in the native Settings window (⌘,) instead; see `SettingsWindow`.
///
struct SettingsScreen: View {

    @Environment(AppSettings.self) private var appSettings
    #if DEBUG
    @Environment(EngineeringMode.self) private var engineeringMode
    #endif

    var body: some View {
        @Bindable var appSettings = appSettings

        Form {
            Section("Appearance") {
                Picker("Color Scheme", selection: $appSettings.colorScheme) {
                    ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                        Text(scheme.label).tag(scheme)
                    }
                }
            }

            Section("Units") {
                Picker("Weight Unit", selection: $appSettings.weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
            }

            DataSettingsSection()

            Section("Account") {
                LabeledContent("Withings", value: "Coming soon")
            }

            InformationSection()

            #if DEBUG
            Section {
                NavigationLink {
                    EngineeringModeForm()
                        .navigationTitle("Engineering Mode")
                        .environment(engineeringMode)
                } label: {
                    Label("Engineering", systemImage: "wrench.and.screwdriver.fill")
                }
            }
            #endif
        }
        .navigationTitle("Settings")
        .formStyle(.grouped)
    }
}

private extension AppColorScheme {
    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsScreen()
            .appEnvironment(.mock())
    }
}
