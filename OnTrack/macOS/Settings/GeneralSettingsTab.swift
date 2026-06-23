//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

#if os(macOS)

import SwiftUI

/// The General tab of the macOS Settings window: appearance and units.
struct GeneralSettingsTab: View {

    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        @Bindable var appSettings = appSettings

        Form {
            Picker("Color Scheme", selection: $appSettings.colorScheme) {
                ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                    Text(scheme.description).tag(scheme)
                }
            }

            Picker("Weight Unit", selection: $appSettings.weightUnit) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unit.label).tag(unit)
                }
            }
        }
        .padding(20)
    }
}

#Preview {
    GeneralSettingsTab()
        .appEnvironment(.mock())
}

#endif
